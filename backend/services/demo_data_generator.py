"""
Krishi Drishti - Demo Data Generator
Generates realistic historical field data with seasonal trends for Grafana dashboards.

Runs on startup to seed 60 days of history, then every 6 hours to add new data points.
All 8 demo fields represent real agricultural regions across India with different crops.
"""
import logging
import math
import random
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from uuid import uuid4

from ..config import DEFAULT_LAT, DEFAULT_LNG

logger = logging.getLogger(__name__)

# ============================================================
# DEMO FIELDS — 8 real agricultural regions across India
# Each has unique characteristics for realistic diversity
# ============================================================

DEMO_FIELDS = [
    {
        "field_id": "demo_varanasi",
        "name": "Varanasi Farm",
        "latitude": 25.3176,
        "longitude": 82.9739,
        "crop_type": "wheat",
        "area_hectares": 2.5,
        "base_ndvi": 0.55,
        "base_health": 72,
        "season": "rabi",         # Winter crop cycle
        "seasonal_peak_day": 90,  # Peak at day 90 of season
        "pest_sensitivity": 0.3,
        "irrigation": True
    },
    {
        "field_id": "demo_punjab",
        "name": "Punjab Wheat Belt",
        "latitude": 30.9000,
        "longitude": 75.8500,
        "crop_type": "wheat",
        "area_hectares": 5.0,
        "base_ndvi": 0.65,
        "base_health": 82,
        "season": "rabi",
        "seasonal_peak_day": 85,
        "pest_sensitivity": 0.25,
        "irrigation": True
    },
    {
        "field_id": "demo_karnataka",
        "name": "Karnataka Coffee Estate",
        "latitude": 13.0000,
        "longitude": 75.5000,
        "crop_type": "coffee",
        "area_hectares": 3.0,
        "base_ndvi": 0.60,
        "base_health": 78,
        "season": "perennial",
        "seasonal_peak_day": None,
        "pest_sensitivity": 0.5,
        "irrigation": False
    },
    {
        "field_id": "demo_maharashtra",
        "name": "Maharashtra Cotton Field",
        "latitude": 20.0000,
        "longitude": 76.5000,
        "crop_type": "cotton",
        "area_hectares": 4.0,
        "base_ndvi": 0.45,
        "base_health": 62,
        "season": "kharif",       # Monsoon crop
        "seasonal_peak_day": 60,
        "pest_sensitivity": 0.7,
        "irrigation": False
    },
    {
        "field_id": "demo_telangana",
        "name": "Telangana Rice Paddy",
        "latitude": 17.5000,
        "longitude": 79.0000,
        "crop_type": "rice",
        "area_hectares": 3.5,
        "base_ndvi": 0.58,
        "base_health": 70,
        "season": "kharif",
        "seasonal_peak_day": 55,
        "pest_sensitivity": 0.6,
        "irrigation": True
    },
    {
        "field_id": "demo_gujarat",
        "name": "Gujarat Groundnut Farm",
        "latitude": 22.5000,
        "longitude": 71.5000,
        "crop_type": "groundnut",
        "area_hectares": 3.0,
        "base_ndvi": 0.42,
        "base_health": 58,
        "season": "kharif",
        "seasonal_peak_day": 70,
        "pest_sensitivity": 0.4,
        "irrigation": False
    },
    {
        "field_id": "demo_up_east",
        "name": "UP East Sugarcane",
        "latitude": 26.5000,
        "longitude": 83.5000,
        "crop_type": "sugarcane",
        "area_hectares": 4.5,
        "base_ndvi": 0.62,
        "base_health": 75,
        "season": "perennial",
        "seasonal_peak_day": None,
        "pest_sensitivity": 0.35,
        "irrigation": True
    },
    {
        "field_id": "demo_rajasthan",
        "name": "Rajasthan Dryland",
        "latitude": 27.0000,
        "longitude": 73.5000,
        "crop_type": "mustard",
        "area_hectares": 6.0,
        "base_ndvi": 0.30,
        "base_health": 45,
        "season": "rabi",
        "seasonal_peak_day": 75,
        "pest_sensitivity": 0.2,
        "irrigation": False
    }
]

# Seed for reproducibility across runs
random.seed(42)


def _sinusoidal_seasonal(day_of_year: int, peak_day: int, base: float, amplitude: float) -> float:
    """
    Generate a seasonal sinusoidal pattern.
    Peaks at peak_day, troughs 180 days later.
    """
    radians = (day_of_year - peak_day) * 2 * math.pi / 365
    return base + amplitude * math.cos(radians)


def _stable_hash(value: str) -> float:
    """Deterministic hash that's consistent across runs."""
    import zlib
    return (zlib.adler32(value.encode("utf-8")) & 0x7FFFFFFF) / 0x7FFFFFFF


def _limited_noise(seed_str: str, magnitude: float) -> float:
    """Generate deterministic noise within [-magnitude, +magnitude]."""
    return (_stable_hash(seed_str) - 0.5) * 2 * magnitude


def _apply_moisture_stress(
    ndvi: float,
    precipitation_mm: float,
    evapotranspiration_mm: float
) -> float:
    """
    Apply moisture stress: if ET > precip, NDVI drops slightly.
    """
    stress = max(0, (evapotranspiration_mm - precipitation_mm) / 10)
    return max(0.05, ndvi - stress * 0.03)


def _compute_recommendations(
    health_score: float, ndvi: float, ndwi: float,
    pest_score: float, temp: float, precip: float,
    soil_moisture: float
) -> List[str]:
    """Generate realistic text recommendations based on conditions."""
    recs = []
    if health_score < 50:
        recs.append("⚠️ Critical: Your crop shows significant stress. Immediate action recommended.")
    elif health_score < 65:
        recs.append("🌱 Crop health needs attention. Focus on stressed zones identified on the map.")

    if ndwi < 0.2 and precip < 5:
        recs.append("💧 Low crop water content detected. Irrigate within 24-48 hours.")
    elif ndwi > 0.5:
        recs.append("💧 Adequate water content in crop. Maintain current irrigation schedule.")

    if soil_moisture > 35:
        recs.append("🌊 High soil moisture - check for waterlogging. Improve drainage if needed.")
    elif soil_moisture < 15:
        recs.append("🏜️ Low soil moisture - consider increasing irrigation frequency.")

    if temp > 38:
        recs.append("☀️ High temperature stress. Consider shade management or heat-tolerant practices.")
    elif temp < 15:
        recs.append("❄️ Low temperature detected. Monitor for frost damage.")

    if pest_score >= 50:
        recs.append("🐛 Pest risk is elevated. Scout fields and consider preventive measures.")
    if ndvi < 0.3:
        recs.append("🌿 Low vegetation vigor - check for nutrient deficiency. Consider fertilizer application.")

    if not recs:
        recs.append("✅ Your crop is in good health. Continue regular monitoring.")
    return recs


def generate_demo_analysis(
    field: Dict[str, Any],
    analysis_date: datetime,
    is_historical: bool = False
) -> Dict[str, Any]:
    """
    Generate a single realistic analysis data point for a demo field.

    Produces data matching the format expected by combine_all_analysis()
    so it can be stored alongside real analyses in the database.

    Args:
        field: Demo field definition dict
        analysis_date: DateTime for this analysis point
        is_historical: If True, uses simplified deterministic generation (faster)
    """
    field_id = field["field_id"]
    lat = field["latitude"]
    lng = field["longitude"]
    crop = field["crop_type"]
    base_ndvi = field["base_ndvi"]
    base_health = field["base_health"]
    pest_sens = field["pest_sensitivity"]
    irrigated = field["irrigation"]
    season = field["season"]

    day_of_year = analysis_date.timetuple().tm_yday
    date_str = analysis_date.strftime("%Y-%m-%d")
    seed_key = f"{field_id}_{date_str}"

    # ---- Seasonal NDVI pattern ----
    peak_day = field.get("seasonal_peak_day", 75)
    if peak_day is None:
        # Perennial crops have a gentler cycle
        ndvi_seasonal = _sinusoidal_seasonal(day_of_year, 120, base_ndvi, 0.08)
    else:
        ndvi_seasonal = _sinusoidal_seasonal(day_of_year, peak_day, base_ndvi, 0.15)

    # Add noise
    ndvi_noise = _limited_noise(f"ndvi_{seed_key}", 0.06)
    ndvi = max(0.05, min(0.88, ndvi_seasonal + ndvi_noise))

    # ---- Derived indices ----
    evi = max(0.05, min(0.90, ndvi * 0.92 + _limited_noise(f"evi_{seed_key}", 0.05)))
    ndwi = max(0.05, min(0.70, ndvi * 0.55 + _limited_noise(f"ndwi_{seed_key}", 0.04) - 0.05))
    gndvi = max(0.05, min(0.85, ndvi * 0.90 + _limited_noise(f"gndvi_{seed_key}", 0.04)))
    reip = max(0.10, min(0.55, ndvi * 0.45 + _limited_noise(f"reip_{seed_key}", 0.03) + 0.10))
    savi = max(0.05, min(0.75, ndvi * 0.80 + _limited_noise(f"savi_{seed_key}", 0.04)))

    # ---- Weather data ----
    # Temperature varies by season and latitude
    lat_factor = (35 - lat) / 35  # 0 to ~0.6 for Indian latitudes
    temp_base = 15 + lat_factor * 18
    temp_seasonal = _sinusoidal_seasonal(day_of_year, 190, 0, 6)  # Hotter in summer (day ~190)
    temp = max(10, min(45, temp_base + temp_seasonal + _limited_noise(f"temp_{seed_key}", 2)))

    # Humidity inversely correlated with temperature, plus location
    humidity = max(30, min(95, 75 - (temp - 28) * 1.2 + _limited_noise(f"humid_{seed_key}", 5)))
    humidity = min(95, max(30, humidity))

    # Precipitation: monsoon peaks around day 220 (Aug) for kharif regions
    monsoon_peak = 220
    precip_seasonal = _sinusoidal_seasonal(day_of_year, monsoon_peak, 5, 12)
    precip = max(0, precip_seasonal + _limited_noise(f"precip_{seed_key}", 3))

    # Wind speed
    wind = max(5, min(35, 12 + _limited_noise(f"wind_{seed_key}", 5)))

    # Solar radiation
    solar = max(8, min(32, 20 + _sinusoidal_seasonal(day_of_year, 172, 0, 6) + _limited_noise(f"solar_{seed_key}", 3)))

    # Evapotranspiration
    et = max(1, min(8, 0.0023 * temp * solar ** 0.5 + _limited_noise(f"et_{seed_key}", 1)))

    # Apply moisture stress
    ndvi = _apply_moisture_stress(ndvi, precip, et)

    # ---- Soil moisture ----
    soil_moisture = min(45, max(8, 20 + (precip - et) * 0.8 + _limited_noise(f"soil_{seed_key}", 3)))
    if irrigated:
        soil_moisture = min(45, soil_moisture + 5)

    # ---- Drainage score ----
    drainage = 50 + _limited_noise(f"drain_{seed_key}", 10)
    if soil_moisture > 35:
        drainage -= 15
    elif soil_moisture < 15:
        drainage += 10
    drainage = max(10, min(95, drainage))

    # ---- Health score ----
    health = base_health + (ndvi - base_ndvi) * 80
    if soil_moisture < 12:
        health -= 10
    elif soil_moisture > 38:
        health -= 8
    if temp > 38 or temp < 12:
        health -= 8
    health_noise = _limited_noise(f"health_{seed_key}", 5)
    health = max(15, min(98, round(health + health_noise)))

    # Determine status
    if health >= 80:
        status = "Healthy & Vigorous"
        status_color = "#2ECC71"
    elif health >= 65:
        status = "Good - Monitor"
        status_color = "#F1C40F"
    elif health >= 50:
        status = "Moderate - Needs Attention"
        status_color = "#E67E22"
    else:
        status = "Stressed - Action Required"
        status_color = "#E74C3C"

    # ---- Pest risk ----
    pest_base = pest_sens * 40
    humidity_factor = max(0, (humidity - 50) / 50) * 25
    temp_factor = max(0, min(1, (temp - 22) / 15)) * 15 if 22 <= temp <= 37 else 5
    ndvi_factor = max(0, (0.5 - ndvi) / 0.5) * 15
    pest_score = min(95, max(5, round(pest_base + humidity_factor + temp_factor + ndvi_factor)))
    pest_level = "Low" if pest_score < 25 else "Moderate" if pest_score < 50 else "High" if pest_score < 75 else "Critical"

    # ---- SAR moisture ----
    sar_moisture = min(0.55, max(0.08, soil_moisture / 100 + _limited_noise(f"sar_{seed_key}", 0.03)))

    # ---- Recommendations ----
    recommendations = _compute_recommendations(
        health, ndvi, ndwi, pest_score, temp, precip, soil_moisture
    )

    # ---- Hotspot grid ----
    grid = []
    half = 0.0009
    for i in range(5):
        for j in range(5):
            cell_noise = _limited_noise(f"grid_{seed_key}_{i}_{j}", 0.08)
            cell_ndvi = max(0.05, min(0.85, ndvi + cell_noise))
            is_stressed = cell_ndvi < 0.45
            grid.append({
                "lat": lat + (i - 2) * half,
                "lng": lng + (j - 2) * half,
                "ndvi": round(cell_ndvi, 3),
                "status": "stressed" if is_stressed else "healthy",
                "color": "#E74C3C" if is_stressed else "#64B5F6",
                "opacity": 0.38
            })

    # ---- Build the analysis dict ----
    vegetation = {
        "ndvi": round(ndvi, 3),
        "evi": round(evi, 3),
        "ndwi": round(ndwi, 3),
        "gndvi": round(gndvi, 3),
        "reip": round(reip, 3),
        "savi": round(savi, 3)
    }

    weather = {
        "temperature_c": round(temp, 1),
        "humidity_pct": round(humidity, 1),
        "precipitation_mm": round(precip, 1),
        "wind_speed_kmh": round(wind, 1),
        "solar_radiation_mj": round(solar, 1),
        "evapotranspiration_mm": round(et, 1),
        "forecast_rain_48h": round(max(0, precip + _limited_noise(f"rainf_{seed_key}", 5)), 1),
        "source": "Demo Data Generator"
    }

    soil = {
        "moisture_pct": round(soil_moisture, 1),
        "drainage_score": round(drainage),
        "sar_soil_moisture": round(sar_moisture, 3),
        "organic_matter_estimate": round(1.5 + (lat / 40), 1)
    }

    pest_risk = {
        "score": pest_score,
        "level": pest_level,
        "contributing_factors": [
            "REIP-based early stress detection" if reip < 0.3 else "Normal vegetation stress levels",
            f"Humidity at {humidity:.0f}%{' - favorable for pests' if humidity > 70 else ''}",
            f"Temperature at {temp:.0f}°C{' - within pest proliferation range' if 25 <= temp <= 35 else ''}"
        ],
        "recommendations": [
            "Apply preventive pesticide in high-risk zones" if pest_score > 50 else "Maintain regular scouting schedule",
            "Monitor for early signs of pest activity in stressed areas"
        ]
    }

    return {
        "field_id": field_id,
        "latitude": lat,
        "longitude": lng,
        "crop_type": crop,
        "analysis": {
            "vegetation": vegetation,
            "soil": soil,
            "weather": weather,
            "pest_risk": pest_risk,
            "health_score": {
                "overall": health,
                "status": status,
                "color": status_color,
                "components": {
                    "ndvi_contrib": round(ndvi * 120, 1) if ndvi < 0.8 else 96,
                    "evi_contrib": round(evi * 110, 1),
                    "ndwi_contrib": round((ndwi + 0.5) * 80, 1),
                    "reip_contrib": round(reip * 150, 1),
                    "savi_contrib": round(savi * 130, 1)
                }
            },
            "recommendations": recommendations,
            "hotspot_grid": grid,
            "satellite_sources": [
                {"name": "Sentinel-2", "mission": "Copernicus", "resolution_m": 10,
                 "bands_used": ["B04", "B08", "B03", "B11", "B05-B07"],
                 "acquisition_date": date_str, "cloud_cover_pct": round(10 + _stable_hash(f"cloud_{seed_key}") * 20, 1)},
                {"name": "Sentinel-1 SAR", "mission": "Copernicus", "resolution_m": 10,
                 "bands_used": ["VV", "VH"], "acquisition_date": date_str, "cloud_cover_pct": 0}
            ]
        },
        "analysis_type": "demo_scheduled",
        "analysis_date": date_str,

        # Flat columns for PostgreSQL Grafana queries
        "health_score_flat": health,
        "ndvi_flat": round(ndvi, 3),
        "evi_flat": round(evi, 3),
        "ndwi_flat": round(ndwi, 3),
        "gndvi_flat": round(gndvi, 3),
        "reip_flat": round(reip, 3),
        "savi_flat": round(savi, 3),
        "soil_moisture_pct_flat": round(soil_moisture, 1),
        "drainage_score_flat": round(drainage),
        "pest_risk_score_flat": pest_score,
        "temperature_c_flat": round(temp, 1),
        "humidity_pct_flat": round(humidity, 1),
        "precipitation_mm_flat": round(precip, 1)
    }


async def seed_demo_data(days_back: int = 60, interval_hours: int = 6) -> int:
    """
    Seed the database with realistic historical demo data.

    Generates analysis points at 'interval_hours' intervals going back 'days_back' days.

    Args:
        days_back: Number of days of history to generate
        interval_hours: Hours between each analysis point

    Returns:
        Total number of data points generated
    """
    from .supabase_service import save_analysis, save_field_profile, _memory_store

    # Register demo field profiles first
    for field in DEMO_FIELDS:
        await save_field_profile({
            "field_id": field["field_id"],
            "latitude": field["latitude"],
            "longitude": field["longitude"],
            "crop_type": field["crop_type"],
            "area_hectares": field["area_hectares"],
            "last_health_score": field["base_health"],
            "last_status": "Active"
        })

    # Generate historical data points
    now = datetime.utcnow()
    total = 0
    step = timedelta(hours=interval_hours)
    start = now - timedelta(days=days_back)

    current = start
    while current <= now:
        for field in DEMO_FIELDS:
            analysis = generate_demo_analysis(field, current, is_historical=True)
            # Map flat columns to the expected keys for save_analysis
            save_data = {
                "field_id": analysis["field_id"],
                "latitude": analysis["latitude"],
                "longitude": analysis["longitude"],
                "analysis": analysis["analysis"],
                "type": "demo_historical",
                # Flat columns for Grafana
                "health_score": analysis["health_score_flat"],
                "ndvi": analysis["ndvi_flat"],
                "evi": analysis["evi_flat"],
                "ndwi": analysis["ndwi_flat"],
                "gndvi": analysis["gndvi_flat"],
                "reip": analysis["reip_flat"],
                "savi": analysis["savi_flat"],
                "soil_moisture_pct": analysis["soil_moisture_pct_flat"],
                "drainage_score": analysis["drainage_score_flat"],
                "pest_risk_score": analysis["pest_risk_score_flat"],
                "temperature_c": analysis["temperature_c_flat"],
                "humidity_pct": analysis["humidity_pct_flat"],
                "precipitation_mm": analysis["precipitation_mm_flat"]
            }
            # Override created_at for historical accuracy
            save_data["created_at"] = current.isoformat()
            result = await save_analysis(save_data)
            # Fix the created_at in memory store to use the correct historical date
            if result.get("analysis_id"):
                for a in _memory_store.get("analyses", []):
                    if a.get("analysis_id") == result.get("analysis_id"):
                        a["created_at"] = current.isoformat()
                        break
            total += 1

        current += step

    # Update field profiles with latest health scores
    for field in DEMO_FIELDS:
        latest_analysis = generate_demo_analysis(field, now)
        for fp in _memory_store["field_profiles"]:
            if fp.get("field_id") == field["field_id"]:
                fp["last_health_score"] = latest_analysis["health_score_flat"]
                fp["last_status"] = latest_analysis["analysis"]["health_score"]["status"]
                break

    logger.info(f"✅ Seeded {total} demo data points across {len(DEMO_FIELDS)} fields ({days_back} days back)")
    return total


async def generate_demo_tick() -> int:
    """
    Generate a single new data point for each demo field (called every 6 hours).

    Returns:
        Number of new data points generated
    """
    from .supabase_service import save_analysis, save_field_profile

    now = datetime.utcnow()
    count = 0

    for field in DEMO_FIELDS:
        analysis = generate_demo_analysis(field, now)

        save_data = {
            "field_id": analysis["field_id"],
            "latitude": analysis["latitude"],
            "longitude": analysis["longitude"],
            "analysis": analysis["analysis"],
            "type": "demo_scheduled",
            "health_score": analysis["health_score_flat"],
            "ndvi": analysis["ndvi_flat"],
            "evi": analysis["evi_flat"],
            "ndwi": analysis["ndwi_flat"],
            "gndvi": analysis["gndvi_flat"],
            "reip": analysis["reip_flat"],
            "savi": analysis["savi_flat"],
            "soil_moisture_pct": analysis["soil_moisture_pct_flat"],
            "drainage_score": analysis["drainage_score_flat"],
            "pest_risk_score": analysis["pest_risk_score_flat"],
            "temperature_c": analysis["temperature_c_flat"],
            "humidity_pct": analysis["humidity_pct_flat"],
            "precipitation_mm": analysis["precipitation_mm_flat"]
        }

        await save_analysis(save_data)

        # Update field profile with latest health
        profile = await save_field_profile({
            "field_id": field["field_id"],
            "latitude": field["latitude"],
            "longitude": field["longitude"],
            "crop_type": field["crop_type"],
            "area_hectares": field["area_hectares"],
            "last_health_score": analysis["health_score_flat"],
            "last_status": analysis["analysis"]["health_score"]["status"]
        })
        count += 1

    logger.info(f"📊 Demo data tick: generated {count} new analysis points at {now.strftime('%Y-%m-%d %H:%M UTC')}")
    return count


def get_demo_field_summary() -> List[Dict[str, Any]]:
    """Get a summary of all demo fields for display."""
    summary = []
    for field in DEMO_FIELDS:
        summary.append({
            "field_id": field["field_id"],
            "name": field["name"],
            "latitude": field["latitude"],
            "longitude": field["longitude"],
            "crop_type": field["crop_type"],
            "area_hectares": field["area_hectares"],
            "irrigation": field["irrigation"],
            "season": field["season"]
        })
    return summary
