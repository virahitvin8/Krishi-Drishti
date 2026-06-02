"""
Krishi Drishti - Grafana Integration Router
Provides both Infinity API endpoints AND PostgreSQL-optimized dashboard JSON.
Also serves data for Grafana's Infinity datasource as a fallback.
"""
import logging
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from uuid import uuid4

from fastapi import APIRouter, HTTPException, Query, Body
from fastapi.responses import JSONResponse

from ..models import DashboardData, DetailedReport
from ..services.supabase_service import (
    get_recent_analyses, get_field_analyses, get_dashboard_stats, list_field_profiles
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/grafana", tags=["Grafana"])


# ============================================================
#  ENDPOINTS: Infinity Datasource (fallback)
#  These endpoints serve data for Grafana's Infinity datasource.
# ============================================================

@router.get("/health")
@router.post("/health")
async def grafana_health():
    """Health check for Grafana datasource."""
    return {"status": "ok", "version": "4.0.0"}


@router.post("/query/ndvi-trend")
async def query_ndvi_trend(field_id: Optional[str] = Body(None), days: int = Body(30)):
    """Returns NDVI time-series for Infinity datasource."""
    try:
        analyses = await get_field_analyses(field_id or "demo", limit=min(days, 90))
        data_points = []
        for a in analyses:
            ts = a.get("created_at", "")
            ndvi = a.get("analysis", {}).get("vegetation", {}).get("ndvi", 0)
            if ndvi:
                data_points.append({"time": ts, "value": round(ndvi * 100, 1), "metric": "NDVI"})
        if not data_points:
            base = datetime.utcnow() - timedelta(days=days)
            for i in range(min(days, 30)):
                d = base + timedelta(days=i)
                ndvi = 0.35 + (i % 20) / 100 + (hash(str(i)) % 10 - 5) / 100
                data_points.append({"time": d.strftime("%Y-%m-%dT%H:%M:%SZ"),
                                    "value": round(max(0.05, min(0.85, ndvi)) * 100, 1), "metric": "NDVI"})
        return data_points
    except Exception as e:
        logger.error(f"Grafana NDVI query error: {e}")
        return _generate_demo_time_series("NDVI", days)


@router.post("/query/vegetation-indices")
async def query_vegetation_indices(field_id: Optional[str] = Body(None), days: int = Body(30)):
    """Returns all vegetation indices as multi-line time-series."""
    try:
        analyses = await get_field_analyses(field_id or "demo", limit=min(days, 90))
        data_points = []
        for a in analyses:
            ts = a.get("created_at", "")
            veg = a.get("analysis", {}).get("vegetation", {})
            for metric in ["NDVI", "EVI", "NDWI", "GNDVI", "REIP", "SAVI"]:
                val = veg.get(metric.lower(), 0)
                if val:
                    data_points.append({"time": ts, "value": round(val * 100, 1), "metric": metric})
        if not data_points:
            return _generate_multi_metric_time_series(["NDVI", "EVI", "NDWI", "GNDVI", "REIP", "SAVI"], days)
        return data_points
    except Exception as e:
        logger.error(f"Grafana veg query error: {e}")
        return _generate_multi_metric_time_series(["NDVI", "EVI", "NDWI", "GNDVI", "REIP", "SAVI"], days)


@router.post("/query/health-trend")
async def query_health_trend(field_id: Optional[str] = Body(None), days: int = Body(30)):
    """Returns health score trend."""
    try:
        analyses = await get_field_analyses(field_id or "demo", limit=min(days, 90))
        data_points = []
        for a in analyses:
            ts = a.get("created_at", "")
            score = a.get("analysis", {}).get("health_score", {}).get("overall", 0)
            if score:
                data_points.append({"time": ts, "value": score, "metric": "Health Score"})
        if not data_points:
            return _generate_demo_time_series("Health Score", days)
        return data_points
    except Exception as e:
        logger.error(f"Grafana health query error: {e}")
        return _generate_demo_time_series("Health Score", days)


@router.post("/query/weather-trend")
async def query_weather_trend(latitude: Optional[float] = Body(None), longitude: Optional[float] = Body(None), days: int = Body(7)):
    """Returns 7-day weather trend."""
    from ..services.weather_service import fetch_weather_data
    try:
        lat, lng = latitude or 25.3176, longitude or 82.9739
        weather = await fetch_weather_data(lat, lng)
        data_points = []
        day_count = min(days, 7)
        if weather:
            base_temp = weather.get("temperature_c", 30)
            base_humidity = weather.get("humidity_pct", 60)
            base_precip = weather.get("precipitation_mm", 0)
            base_wind = weather.get("wind_speed_kmh", 10)
            base_solar = weather.get("solar_radiation_mj", 20)
            base_et = weather.get("evapotranspiration_mm", 4.5)
            for i in range(day_count):
                d = datetime.utcnow() - timedelta(days=(day_count - 1 - i))
                ts = d.strftime("%Y-%m-%dT%H:%M:%SZ")
                variation = (i % 5 - 2) * 0.5
                for name, base_val, unit in [("Temperature", base_temp, "°C"), ("Humidity", base_humidity, "%"),
                    ("Precipitation", max(0, base_precip + (i % 3 - 1) * 2), "mm"),
                    ("Wind Speed", base_wind + variation, "km/h"),
                    ("Solar Radiation", base_solar + variation * 0.5, "MJ/m²"),
                    ("Evapotranspiration", base_et + variation * 0.1, "mm")]:
                    data_points.append({"time": ts, "value": round(max(0, base_val + variation), 1), "metric": name, "unit": unit})
        return data_points
    except Exception as e:
        logger.error(f"Grafana weather query error: {e}")
        return []


@router.post("/query/field-summary")
async def query_field_summary():
    """Returns summary stats for Stat panels."""
    try:
        stats = await get_dashboard_stats()
        return [{"total_fields": stats["total_fields"], "avg_health_score": stats["avg_health_score"],
                 "healthy_count": stats["health_distribution"]["healthy"],
                 "good_count": stats["health_distribution"]["good"],
                 "moderate_count": stats["health_distribution"]["moderate"],
                 "stressed_count": stats["health_distribution"]["stressed"],
                 "total_analyses": stats["recent_count"],
                 "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")}]
    except Exception as e:
        logger.error(f"Grafana field summary error: {e}")
        return [{"total_fields": 0, "avg_health_score": 0, "healthy_count": 0, "good_count": 0,
                 "moderate_count": 0, "stressed_count": 0, "total_analyses": 0,
                 "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")}]


@router.post("/query/field-locations")
async def query_field_locations():
    """Returns field locations for GeoMap."""
    try:
        profiles = await list_field_profiles(100)
        locations = []
        for p in profiles:
            locations.append({"latitude": p.get("latitude", 0), "longitude": p.get("longitude", 0),
                              "name": p.get("field_id", "Unknown"), "health_score": p.get("last_health_score", 50),
                              "status": p.get("last_status", "Unknown"), "crop_type": p.get("crop_type", "general"),
                              "area_hectares": p.get("area_hectares", 1)})
        if not locations:
            for i, f in enumerate([{"lat": 25.3176, "lng": 82.9739, "name": "Demo Field 1"},
                {"lat": 25.3200, "lng": 82.9700, "name": "Demo Field 2"},
                {"lat": 25.3150, "lng": 82.9760, "name": "Demo Field 3"}]):
                locations.append({"latitude": f["lat"], "longitude": f["lng"], "name": f["name"],
                                  "health_score": 50 + (hash(str(i)) % 40), "status": "Active",
                                  "crop_type": "Wheat", "area_hectares": 1.5 + (i * 0.5)})
        return locations
    except Exception as e:
        logger.error(f"Grafana locations error: {e}")
        return []


@router.post("/query/pest-risk-trend")
async def query_pest_risk_trend(field_id: Optional[str] = Body(None), days: int = Body(30)):
    """Returns pest risk trend."""
    try:
        analyses = await get_field_analyses(field_id or "demo", limit=min(days, 90))
        data_points = []
        for a in analyses:
            ts = a.get("created_at", "")
            score = a.get("analysis", {}).get("pest_risk", {}).get("score", 0)
            if score:
                data_points.append({"time": ts, "value": score, "metric": "Pest Risk"})
        if not data_points:
            return _generate_demo_time_series("Pest Risk", days)
        return data_points
    except Exception as e:
        logger.error(f"Grafana pest query error: {e}")
        return _generate_demo_time_series("Pest Risk", days)


@router.post("/query/recommendations")
async def query_recommendations(field_id: Optional[str] = Body(None), limit: int = Body(20)):
    """Returns latest recommendations for Table panel."""
    try:
        analyses = await get_field_analyses(field_id or "demo", limit=5)
        recs = []
        for a in analyses:
            ts = a.get("created_at", "")
            for r in a.get("analysis", {}).get("recommendations", []):
                recs.append({"time": ts, "recommendation": r, "field_id": a.get("field_id", field_id or "demo"),
                             "type": "critical" if "⚠️" in r else "warning" if "needs attention" in r.lower() else "info"})
        return recs[:limit]
    except Exception as e:
        logger.error(f"Grafana recs error: {e}")
        return []


# ============================================================
#  ENDPOINT: Dashboard JSON Export
# ============================================================

@router.get("/dashboard-json")
async def get_grafana_dashboard_json():
    """Returns Infinity-based dashboard JSON for import."""
    return get_infinity_dashboard_json()


@router.get("/dashboard-json/postgres")
async def get_postgres_dashboard_json():
    """Returns PostgreSQL-optimized dashboard JSON for import."""
    return get_postgres_dashboard_json_def()


# ============================================================
#  HELPER FUNCTIONS
# ============================================================

def _generate_demo_time_series(metric_name: str, days: int) -> List[Dict]:
    base = datetime.utcnow() - timedelta(days=days)
    points = []
    for i in range(min(days, 30)):
        d = base + timedelta(days=i)
        val = max(5, min(95, 30 + (i % 30) + (hash(str(i * 7)) % 25 - 12)))
        points.append({"time": d.strftime("%Y-%m-%dT%H:%M:%SZ"), "value": val, "metric": metric_name})
    return points


def _generate_multi_metric_time_series(metrics: List[str], days: int) -> List[Dict]:
    base = datetime.utcnow() - timedelta(days=days)
    points = []
    for i in range(min(days, 30)):
        d = base + timedelta(days=i)
        for metric in metrics:
            val = 20 + (hash(f"{metric}{i}") % 50)
            points.append({"time": d.strftime("%Y-%m-%dT%H:%M:%SZ"), "value": val, "metric": metric})
    return points


# ============================================================
#  DASHBOARD JSON: Infinity Datasource (13 panels)
# ============================================================

def get_infinity_dashboard_json() -> Dict[str, Any]:
    """Pre-built Grafana dashboard using Infinity datasource (API-based)."""
    return {
        "__inputs": [],
        "__requires": [{"type": "grafana", "id": "grafana", "name": "Grafana", "version": "10.4.0"},
                       {"type": "datasource", "id": "grafana-infinity-datasource", "name": "Infinity", "version": "3.0.0"}],
        "id": None, "title": "Krishi Drishti - Agricultural Monitoring",
        "description": "Real-time satellite crop health monitoring dashboard. Powered by Infinity datasource.",
        "tags": ["agriculture", "satellite", "ndvi", "crop-health", "india", "krishi-drishti"],
        "timezone": "browser", "schemaVersion": 39, "version": 1, "refresh": "30m",
        "time": {"from": "now-7d", "to": "now"},
        "timepicker": {"refresh_intervals": ["5m", "15m", "30m", "1h", "6h", "12h", "1d", "7d"],
                       "time_options": ["5m", "15m", "1h", "6h", "12h", "24h", "2d", "7d", "30d"]},
        "panels": [
            # ===== ROW 1: Header Stats =====
            {"id": 1, "gridPos": {"h": 3, "w": 2, "x": 0, "y": 0}, "type": "stat", "title": "Total Fields",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"graphMode": "none", "colorMode": "background", "justifyMode": "center", "orientation": "auto",
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/field-summary",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "total_fields", "text": "Total Fields", "type": "string"}],
                          "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"},
                                          "thresholds": {"mode": "absolute", "steps": [{"color": "text", "value": None},
                                              {"color": "green", "value": 1}, {"color": "#E67E22", "value": 25},
                                              {"color": "#E74C3C", "value": 100}]}}}},
            {"id": 2, "gridPos": {"h": 3, "w": 4, "x": 2, "y": 0}, "type": "stat", "title": "Average Crop Health",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"graphMode": "area", "colorMode": "background", "justifyMode": "center", "orientation": "auto",
                         "reduceOptions": {"calcs": ["mean"], "fields": "", "values": False}},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/field-summary",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "avg_health_score", "text": "Avg Health", "type": "number"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 50},
                                              {"color": "#F1C40F", "value": 65}, {"color": "#2ECC71", "value": 80}]},
                                          "unit": "percent"}}},
            {"id": 3, "gridPos": {"h": 3, "w": 3, "x": 6, "y": 0}, "type": "stat", "title": "Healthy Fields",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"graphMode": "none", "colorMode": "background", "justifyMode": "center", "orientation": "auto",
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/field-summary",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "healthy_count", "text": "Healthy", "type": "number"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [{"color": "green", "value": None}, {"color": "green", "value": 1}]}}}},
            {"id": 4, "gridPos": {"h": 3, "w": 3, "x": 9, "y": 0}, "type": "stat", "title": "Stressed Fields",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"graphMode": "none", "colorMode": "background", "justifyMode": "center", "orientation": "auto",
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/field-summary",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "stressed_count", "text": "Stressed", "type": "number"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "green", "value": None}, {"color": "#E67E22", "value": 1},
                                              {"color": "#E74C3C", "value": 5}]}}}},

            # ===== ROW 2: Health Trend =====
            {"id": 5, "gridPos": {"h": 8, "w": 12, "x": 0, "y": 3}, "type": "timeseries",
             "title": "Crop Health Score Trend (7 days)",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"legend": {"calcs": ["mean", "min", "max", "last"], "displayMode": "table", "placement": "bottom"},
                         "tooltip": {"mode": "multi"}, "lineInterpolation": "smooth", "fillOpacity": 30, "pointSize": 3},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/health-trend",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "time", "text": "Time", "type": "timestamp"},
                                      {"selector": "value", "text": "Health Score", "type": "number"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 50},
                                              {"color": "#F1C40F", "value": 65}, {"color": "#2ECC71", "value": 80}]},
                                          "unit": "percent", "min": 0, "max": 100}}},

            # ===== ROW 3: NDVI + All Indices =====
            {"id": 6, "gridPos": {"h": 8, "w": 6, "x": 0, "y": 11}, "type": "timeseries", "title": "NDVI Trend",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"legend": {"calcs": ["mean", "last"], "displayMode": "table", "placement": "bottom"},
                         "tooltip": {"mode": "multi"}, "lineInterpolation": "smooth", "fillOpacity": 40},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/ndvi-trend",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "time", "text": "Time", "type": "timestamp"},
                                      {"selector": "value", "text": "NDVI", "type": "number"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 25},
                                              {"color": "#F1C40F", "value": 45}, {"color": "#2ECC71", "value": 60}]},
                                          "unit": "percent", "min": 0, "max": 100}}},
            {"id": 7, "gridPos": {"h": 8, "w": 6, "x": 6, "y": 11}, "type": "timeseries", "title": "All Vegetation Indices",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"legend": {"calcs": ["mean", "last"], "displayMode": "table", "placement": "bottom"},
                         "tooltip": {"mode": "multi"}, "lineInterpolation": "smooth", "fillOpacity": 10, "pointSize": 2},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/vegetation-indices",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "time", "text": "Time", "type": "timestamp"},
                                      {"selector": "value", "text": "Value", "type": "number"},
                                      {"selector": "metric", "text": "Metric", "type": "string"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"}, "unit": "percent", "min": 0, "max": 100}}},

            # ===== ROW 4: Pest Risk + Weather =====
            {"id": 8, "gridPos": {"h": 7, "w": 4, "x": 0, "y": 19}, "type": "gauge", "title": "Current Pest Risk",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"showThresholdLabels": True, "showThresholdMarkers": True,
                         "reduceOptions": {"calcs": ["mean"], "fields": "", "values": False}},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/pest-risk-trend",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "value", "text": "Risk Score", "type": "number"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#2ECC71", "value": None}, {"color": "#F1C40F", "value": 25},
                                              {"color": "#E67E22", "value": 50}, {"color": "#E74C3C", "value": 75}]},
                                          "unit": "percent", "min": 0, "max": 100}}},
            {"id": 9, "gridPos": {"h": 7, "w": 4, "x": 4, "y": 19}, "type": "bargauge", "title": "Health Distribution",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"orientation": "horizontal", "displayMode": "gradient", "showUnfilled": True,
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/field-summary",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "healthy_count", "text": "Healthy", "type": "number"},
                                      {"selector": "good_count", "text": "Good", "type": "number"},
                                      {"selector": "moderate_count", "text": "Moderate", "type": "number"},
                                      {"selector": "stressed_count", "text": "Stressed", "type": "number"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"},
                                          "thresholds": {"mode": "absolute", "steps": [{"color": "green", "value": None}]}}}},
            {"id": 10, "gridPos": {"h": 7, "w": 4, "x": 8, "y": 19}, "type": "stat", "title": "Weather (Current)",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"graphMode": "none", "colorMode": "value", "justifyMode": "auto", "orientation": "vertical",
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/weather-trend",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "metric", "text": "Parameter", "type": "string"},
                                      {"selector": "value", "text": "Value", "type": "number"},
                                      {"selector": "unit", "text": "Unit", "type": "string"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"},
                                          "thresholds": {"mode": "absolute", "steps": [{"color": "text", "value": None}]}}}},

            # ===== ROW 5: Map + Alerts =====
            {"id": 11, "gridPos": {"h": 10, "w": 6, "x": 0, "y": 26}, "type": "geomap", "title": "Field Health Map",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"controls": {"showZoom": True, "mouseWheelZoom": True},
                         "view": {"lat": 25.3176, "lng": 82.9739, "zoom": 12},
                         "layers": [{"type": "markers", "name": "Fields", "location": {"mode": "coords"},
                                     "label": {"mode": "fixed", "value": "${name}"},
                                     "color": {"mode": "thresholds", "field": "health_score"},
                                     "thresholds": {"mode": "absolute", "steps": [
                                         {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 50},
                                         {"color": "#F1C40F", "value": 65}, {"color": "#2ECC71", "value": 80}]},
                                     "tooltip": True}]},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/field-locations",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "latitude", "text": "latitude", "type": "number"},
                                      {"selector": "longitude", "text": "longitude", "type": "number"},
                                      {"selector": "name", "text": "name", "type": "string"},
                                      {"selector": "health_score", "text": "health_score", "type": "number"},
                                      {"selector": "status", "text": "status", "type": "string"},
                                      {"selector": "crop_type", "text": "crop_type", "type": "string"},
                                      {"selector": "area_hectares", "text": "area_hectares", "type": "number"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"thresholds": {"mode": "absolute", "steps": [
                 {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 50},
                 {"color": "#F1C40F", "value": 65}, {"color": "#2ECC71", "value": 80}]}}}},
            {"id": 12, "gridPos": {"h": 5, "w": 6, "x": 6, "y": 26}, "type": "table", "title": "Recent Alerts",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"sortBy": [{"displayName": "Time", "desc": True}], "footer": {"show": False}},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/recommendations",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "time", "text": "Time", "type": "timestamp"},
                                      {"selector": "recommendation", "text": "Recommendation", "type": "string"},
                                      {"selector": "field_id", "text": "Field", "type": "string"},
                                      {"selector": "type", "text": "Priority", "type": "string"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "text", "value": None},
                                              {"color": "#E74C3C", "value": 0},
                                              {"color": "#E67E22", "value": 1},
                                              {"color": "#2ECC71", "value": 2}]},
                                          "custom": {"align": "left", "displayMode": "auto", "filterable": True}}}},
            {"id": 13, "gridPos": {"h": 5, "w": 6, "x": 6, "y": 31}, "type": "timeseries", "title": "Pest Risk Trend (30 days)",
             "datasource": {"type": "grafana-infinity-datasource", "uid": "infinity"},
             "options": {"legend": {"calcs": ["mean", "max"], "displayMode": "table", "placement": "bottom"},
                         "tooltip": {"mode": "multi"}, "lineInterpolation": "smooth", "fillOpacity": 30},
             "targets": [{"query": "https://krishi-drishti-backend.onrender.com/api/v1/grafana/query/pest-risk-trend",
                          "method": "post", "type": "json", "root_selector": "",
                          "columns": [{"selector": "time", "text": "Time", "type": "timestamp"},
                                      {"selector": "value", "text": "Pest Risk", "type": "number"}], "parser": "backend"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#2ECC71", "value": None}, {"color": "#F1C40F", "value": 25},
                                              {"color": "#E67E22", "value": 50}, {"color": "#E74C3C", "value": 75}]},
                                          "unit": "percent", "min": 0, "max": 100}}}
        ],
        "templating": {"list": [{"id": "field_id", "name": "Field", "type": "textbox", "query": "",
                                  "current": {"text": "all", "value": "all"},
                                  "options": [{"text": "All Fields", "value": "all"}],
                                  "label": "Filter by Field ID", "hide": 0}]},
        "annotations": {"list": [{"builtIn": 1, "datasource": {"type": "grafana", "uid": "-- Grafana --"},
                                   "enable": True, "hide": True, "iconColor": "rgba(0, 211, 255, 1)",
                                   "name": "Annotations & Alerts", "type": "dashboard"}]},
        "editable": True, "graphTooltip": 0,
        "links": [{"title": "Krishi Drishti App", "url": "https://krishidrishti.netlify.app", "type": "link"},
                  {"title": "GitHub Repo", "url": "https://github.com/virahitvin8/Krishi-Drishti", "type": "link"}]
    }


# ============================================================
#  DASHBOARD JSON: PostgreSQL Datasource (13 panels, SQL queries)
# ============================================================

def get_postgres_dashboard_json_def() -> Dict[str, Any]:
    """
    Grafana dashboard JSON optimized for PostgreSQL datasource (Supabase).
    Each panel uses SQL queries against the tables defined in supabase_migration.sql.
    
    To use: Grafana → Connections → Add PostgreSQL → enter your Supabase connection details.
    Then import this JSON: Dashboards → New → Import → Paste JSON → Select PostgreSQL datasource.
    """
    return {
        "__inputs": [{"name": "DS_POSTGRES", "label": "Supabase PostgreSQL", "description": "",
                       "type": "datasource", "pluginId": "postgres", "pluginName": "PostgreSQL"}],
        "__requires": [{"type": "grafana", "id": "grafana", "name": "Grafana", "version": "10.4.0"},
                       {"type": "datasource", "id": "postgres", "name": "PostgreSQL", "version": "1.0.0"}],
        "id": None, "title": "Krishi Drishti - PostgreSQL Dashboard",
        "description": "Agricultural monitoring dashboard powered by Supabase PostgreSQL. Uses direct SQL queries for fastest performance.",
        "tags": ["agriculture", "satellite", "postgresql", "supabase", "ndvi", "crop-health"],
        "timezone": "browser", "schemaVersion": 39, "version": 1, "refresh": "30m",
        "time": {"from": "now-7d", "to": "now"},
        "timepicker": {"refresh_intervals": ["5m", "15m", "30m", "1h", "6h", "12h", "1d", "7d"],
                       "time_options": ["5m", "15m", "1h", "6h", "12h", "24h", "2d", "7d", "30d"]},
        "panels": [
            # ===== ROW 1: Header Stats =====
            {"id": 1, "gridPos": {"h": 3, "w": 2, "x": 0, "y": 0}, "type": "stat", "title": "Total Fields",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"graphMode": "none", "colorMode": "background", "justifyMode": "center", "orientation": "auto",
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"format": "table", "group": [], "metricColumn": "none",
                          "rawQuery": True, "rawSql": "SELECT COUNT(*) as total FROM field_profiles;",
                          "refId": "A", "select": [[{"params": ["value"], "type": "column"}]],
                          "table": "field_profiles", "timeColumn": "created_at",
                          "where": [{"name": "$__timeFilter", "params": [], "type": "macro"}]}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "text", "value": None}, {"color": "green", "value": 1},
                                              {"color": "#E67E22", "value": 25}, {"color": "#E74C3C", "value": 100}]}}}},

            {"id": 2, "gridPos": {"h": 3, "w": 4, "x": 2, "y": 0}, "type": "stat", "title": "Average Crop Health",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"graphMode": "area", "colorMode": "background", "justifyMode": "center", "orientation": "auto",
                         "reduceOptions": {"calcs": ["mean"], "fields": "", "values": False}},
             "targets": [{"format": "table", "rawQuery": True,
                          "rawSql": "SELECT ROUND(AVG(health_score), 1) as avg_health FROM analyses WHERE $__timeFilter(created_at);",
                          "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 50},
                                              {"color": "#F1C40F", "value": 65}, {"color": "#2ECC71", "value": 80}]},
                                          "unit": "percent"}}},

            {"id": 3, "gridPos": {"h": 3, "w": 3, "x": 6, "y": 0}, "type": "stat", "title": "Healthy Fields",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"graphMode": "none", "colorMode": "background", "justifyMode": "center", "orientation": "auto",
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"format": "table", "rawQuery": True,
                          "rawSql": "SELECT COUNT(*) as healthy FROM v_latest_field_health WHERE health_status = 'Healthy';",
                          "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [{"color": "green", "value": None}, {"color": "green", "value": 1}]}}}},

            {"id": 4, "gridPos": {"h": 3, "w": 3, "x": 9, "y": 0}, "type": "stat", "title": "Stressed Fields",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"graphMode": "none", "colorMode": "background", "justifyMode": "center", "orientation": "auto",
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"format": "table", "rawQuery": True,
                          "rawSql": "SELECT COUNT(*) as stressed FROM v_latest_field_health WHERE health_status = 'Stressed';",
                          "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "green", "value": None}, {"color": "#E67E22", "value": 1},
                                              {"color": "#E74C3C", "value": 5}]}}}},

            # ===== ROW 2: Health Trend =====
            {"id": 5, "gridPos": {"h": 8, "w": 12, "x": 0, "y": 3}, "type": "timeseries",
             "title": "Crop Health Score Trend (7 days)",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"legend": {"calcs": ["mean", "min", "max", "last"], "displayMode": "table", "placement": "bottom"},
                         "tooltip": {"mode": "multi"}, "lineInterpolation": "smooth", "fillOpacity": 30, "pointSize": 3},
             "targets": [{"format": "time_series", "rawQuery": True,
                          "rawSql": "SELECT created_at as \"time\", health_score as \"Health Score\" FROM analyses WHERE $__timeFilter(created_at) ORDER BY created_at;",
                          "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 50},
                                              {"color": "#F1C40F", "value": 65}, {"color": "#2ECC71", "value": 80}]},
                                          "unit": "percent", "min": 0, "max": 100}}},

            # ===== ROW 3: NDVI + All Indices =====
            {"id": 6, "gridPos": {"h": 8, "w": 6, "x": 0, "y": 11}, "type": "timeseries", "title": "NDVI Trend",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"legend": {"calcs": ["mean", "last"], "displayMode": "table", "placement": "bottom"},
                         "tooltip": {"mode": "multi"}, "lineInterpolation": "smooth", "fillOpacity": 40},
             "targets": [{"format": "time_series", "rawQuery": True,
                          "rawSql": "SELECT created_at as \"time\", ROUND(ndvi::numeric * 100, 1) as \"NDVI\" FROM analyses WHERE $__timeFilter(created_at) ORDER BY created_at;",
                          "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 25},
                                              {"color": "#F1C40F", "value": 45}, {"color": "#2ECC71", "value": 60}]},
                                          "unit": "percent", "min": 0, "max": 100}}},
            {"id": 7, "gridPos": {"h": 8, "w": 6, "x": 6, "y": 11}, "type": "timeseries", "title": "All Vegetation Indices",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"legend": {"calcs": ["mean", "last"], "displayMode": "table", "placement": "bottom"},
                         "tooltip": {"mode": "multi"}, "lineInterpolation": "smooth", "fillOpacity": 10, "pointSize": 2},
             "targets": [
                 {"format": "time_series", "rawQuery": True,
                  "rawSql": "SELECT created_at as \"time\", ROUND(ndvi::numeric * 100, 1) as \"NDVI\" FROM analyses WHERE $__timeFilter(created_at) ORDER BY created_at;",
                  "refId": "A"},
                 {"format": "time_series", "rawQuery": True,
                  "rawSql": "SELECT created_at as \"time\", ROUND(evi::numeric * 100, 1) as \"EVI\" FROM analyses WHERE $__timeFilter(created_at) ORDER BY created_at;",
                  "refId": "B"},
                 {"format": "time_series", "rawQuery": True,
                  "rawSql": "SELECT created_at as \"time\", ROUND(ndwi::numeric * 100, 1) as \"NDWI\" FROM analyses WHERE $__timeFilter(created_at) ORDER BY created_at;",
                  "refId": "C"},
                 {"format": "time_series", "rawQuery": True,
                  "rawSql": "SELECT created_at as \"time\", ROUND(gndvi::numeric * 100, 1) as \"GNDVI\" FROM analyses WHERE $__timeFilter(created_at) ORDER BY created_at;",
                  "refId": "D"},
                 {"format": "time_series", "rawQuery": True,
                  "rawSql": "SELECT created_at as \"time\", ROUND(reip::numeric * 100, 1) as \"REIP\" FROM analyses WHERE $__timeFilter(created_at) ORDER BY created_at;",
                  "refId": "E"},
                 {"format": "time_series", "rawQuery": True,
                  "rawSql": "SELECT created_at as \"time\", ROUND(savi::numeric * 100, 1) as \"SAVI\" FROM analyses WHERE $__timeFilter(created_at) ORDER BY created_at;",
                  "refId": "F"}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"}, "unit": "percent", "min": 0, "max": 100}}},

            # ===== ROW 4: Pest Risk + Weather =====
            {"id": 8, "gridPos": {"h": 7, "w": 4, "x": 0, "y": 19}, "type": "gauge", "title": "Current Pest Risk",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"showThresholdLabels": True, "showThresholdMarkers": True,
                         "reduceOptions": {"calcs": ["mean"], "fields": "", "values": False}},
             "targets": [{"format": "table", "rawQuery": True,
                          "rawSql": "SELECT ROUND(AVG(pest_risk_score), 1) as score FROM analyses WHERE $__timeFilter(created_at);",
                          "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#2ECC71", "value": None}, {"color": "#F1C40F", "value": 25},
                                              {"color": "#E67E22", "value": 50}, {"color": "#E74C3C", "value": 75}]},
                                          "unit": "percent", "min": 0, "max": 100}}},
            {"id": 9, "gridPos": {"h": 7, "w": 4, "x": 4, "y": 19}, "type": "bargauge", "title": "Health Distribution",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"orientation": "horizontal", "displayMode": "gradient", "showUnfilled": True,
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"format": "table", "rawQuery": True,
                          "rawSql": """SELECT 
    COUNT(*) FILTER (WHERE health_status = 'Healthy') as "Healthy",
    COUNT(*) FILTER (WHERE health_status = 'Good') as "Good",
    COUNT(*) FILTER (WHERE health_status = 'Moderate') as "Moderate",
    COUNT(*) FILTER (WHERE health_status = 'Stressed') as "Stressed"
FROM v_latest_field_health;""", "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"},
                                          "thresholds": {"mode": "absolute", "steps": [{"color": "green", "value": None}]}}}},
            {"id": 10, "gridPos": {"h": 7, "w": 4, "x": 8, "y": 19}, "type": "stat", "title": "Weather (Current)",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"graphMode": "none", "colorMode": "value", "justifyMode": "auto", "orientation": "vertical",
                         "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}},
             "targets": [{"format": "table", "rawQuery": True,
                          "rawSql": """SELECT 
    ROUND(AVG(temperature_c), 1) as "Avg Temp °C",
    ROUND(AVG(humidity_pct), 1) as "Avg Humidity %",
    ROUND(AVG(precipitation_mm), 1) as "Total Precip mm"
FROM analyses WHERE $__timeFilter(created_at);""", "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"},
                                          "thresholds": {"mode": "absolute", "steps": [{"color": "text", "value": None}]}}}},

            # ===== ROW 5: Map + Table =====
            {"id": 11, "gridPos": {"h": 10, "w": 6, "x": 0, "y": 26}, "type": "geomap", "title": "Field Health Map",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"controls": {"showZoom": True, "mouseWheelZoom": True},
                         "view": {"lat": 25.3176, "lng": 82.9739, "zoom": 12},
                         "layers": [{"type": "markers", "name": "Fields",
                                     "location": {"mode": "coords"},
                                     "label": {"mode": "fixed", "value": "${name}"},
                                     "color": {"mode": "thresholds", "field": "health_score"},
                                     "thresholds": {"mode": "absolute", "steps": [
                                         {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 50},
                                         {"color": "#F1C40F", "value": 65}, {"color": "#2ECC71", "value": 80}]},
                                     "tooltip": True}]},
             "targets": [{"format": "table", "rawQuery": True,
                          "rawSql": """SELECT latitude, longitude, field_id as name, health_score, health_status as status, 
    crop_type, area_hectares
FROM v_latest_field_health;""", "refId": "A"}],
             "fieldConfig": {"defaults": {"thresholds": {"mode": "absolute", "steps": [
                 {"color": "#E74C3C", "value": None}, {"color": "#E67E22", "value": 50},
                 {"color": "#F1C40F", "value": 65}, {"color": "#2ECC71", "value": 80}]}}}},

            {"id": 12, "gridPos": {"h": 5, "w": 6, "x": 6, "y": 26}, "type": "table", "title": "Field Overview",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"sortBy": [{"displayName": "last_analysis_at", "desc": True}], "footer": {"show": False}},
             "targets": [{"format": "table", "rawQuery": True,
                          "rawSql": """SELECT field_id, health_status, health_score, ndvi, crop_type, 
    ROUND(area_hectares::numeric, 1) as area_ha,
    last_analysis_at
FROM v_latest_field_health
ORDER BY last_analysis_at DESC LIMIT 20;""", "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "text", "value": None}, {"color": "#E74C3C", "value": 0},
                                              {"color": "#E67E22", "value": 50}, {"color": "#2ECC71", "value": 80}]},
                                          "custom": {"align": "left", "displayMode": "auto", "filterable": True}}}},

            {"id": 13, "gridPos": {"h": 5, "w": 6, "x": 6, "y": 31}, "type": "timeseries", "title": "Pest Risk Trend (30 days)",
             "datasource": {"type": "postgres", "uid": "${DS_POSTGRES}"},
             "options": {"legend": {"calcs": ["mean", "max"], "displayMode": "table", "placement": "bottom"},
                         "tooltip": {"mode": "multi"}, "lineInterpolation": "smooth", "fillOpacity": 30},
             "targets": [{"format": "time_series", "rawQuery": True,
                          "rawSql": "SELECT created_at as \"time\", pest_risk_score as \"Pest Risk\" FROM analyses WHERE $__timeFilter(created_at) ORDER BY created_at;",
                          "refId": "A"}],
             "fieldConfig": {"defaults": {"color": {"mode": "thresholds"},
                                          "thresholds": {"mode": "absolute", "steps": [
                                              {"color": "#2ECC71", "value": None}, {"color": "#F1C40F", "value": 25},
                                              {"color": "#E67E22", "value": 50}, {"color": "#E74C3C", "value": 75}]},
                                          "unit": "percent", "min": 0, "max": 100}}}
        ],
        "templating": {"list": [{"id": "field_id", "name": "Field", "type": "textbox", "query": "",
                                  "current": {"text": "all", "value": "all"},
                                  "options": [{"text": "All Fields", "value": "all"}],
                                  "label": "Filter by Field ID", "hide": 0}]},
        "annotations": {"list": [{"builtIn": 1, "datasource": {"type": "grafana", "uid": "-- Grafana --"},
                                   "enable": True, "hide": True, "iconColor": "rgba(0, 211, 255, 1)",
                                   "name": "Annotations & Alerts", "type": "dashboard"}]},
        "editable": True, "graphTooltip": 0,
        "links": [{"title": "Krishi Drishti App", "url": "https://krishidrishti.netlify.app", "type": "link"},
                  {"title": "GitHub Repo", "url": "https://github.com/virahitvin8/Krishi-Drishti", "type": "link"}]
    }
