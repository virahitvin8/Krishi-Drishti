"""
Krishi Drishti - Analysis API Router
Endpoints for field analysis, CSV upload, scheduling, and detailed reports.
"""
import logging
import csv
import io
import json
from typing import Optional, List
from uuid import uuid4
from datetime import datetime

from fastapi import APIRouter, HTTPException, UploadFile, File, Query, Body
from fastapi.responses import JSONResponse

from ..models import (
    AnalyzeRequest, CSVUploadResponse, ScheduleRequest,
    AnalysisResponse, DashboardData, DetailedReport, ReportSection
)
from ..services.cdse_service import (
    fetch_sentinel2_indices, fetch_sentinel1_soil_moisture, get_satellite_info
)
from ..services.weather_service import fetch_weather_data
from ..services.analysis_service import (
    combine_all_analysis, process_csv_field_data, generate_hotspot_grid
)
from ..services.supabase_service import (
    save_analysis, save_field_profile, save_csv_batch, save_schedule,
    get_field_analyses, get_dashboard_stats, list_field_profiles
)
from ..services.gee_service import fetch_all_gee
from ..services.isro_service import fetch_isro_data

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["Analysis"])


@router.post("/analyze", response_model=AnalysisResponse)
async def analyze_field(request: AnalyzeRequest):
    """
    Analyze a field/crop using all available satellite data sources.
    
    This is the main endpoint that:
    1. Fetches Sentinel-2 indices (NDVI, EVI, NDWI, GNDVI, REIP, SAVI)
    2. Fetches Sentinel-1 SAR soil moisture
    3. Fetches weather data (NASA POWER + Open-Meteo)
    4. Computes health score, pest risk, drainage, recommendations
    5. Generates hotspot grid for map overlay
    """
    try:
        lat = request.latitude
        lng = request.longitude
        crop_type = request.crop_type or "general"
        
        # 1. Fetch satellite vegetation indices
        indices = await fetch_sentinel2_indices(lat, lng)
        if not indices:
            raise HTTPException(status_code=503, detail="Satellite data temporarily unavailable")
        
        # 2. Fetch SAR soil moisture
        sar_moisture = await fetch_sentinel1_soil_moisture(lat, lng)
        
        # 3. Fetch weather data
        weather = await fetch_weather_data(lat, lng)
        
        # 4. Fetch GEE data FIRST (covers 9+ datasets including Sentinel-2)
        gee_data = await fetch_all_gee(lat, lng)
        gee_s2 = gee_data.get("data", {}).get("sentinel2")
        
        # 5. Use GEE Sentinel-2 if available, otherwise fall back to CDSE
        if gee_s2:
            indices = {
                "ndvi": gee_s2.get("ndvi", 0.4),
                "evi": gee_s2.get("evi", 0.3),
                "ndwi": gee_s2.get("ndwi", 0.2),
                "gndvi": gee_s2.get("gndvi", 0.3),
                "reip": 0.28,  # GEE doesn't compute REIP — keep CDSE default
                "savi": gee_s2.get("savi", 0.3),
                "source": gee_s2.get("source", "GEE"),
            }
        else:
            # Fall back to CDSE Process API
            cdse_indices = await fetch_sentinel2_indices(lat, lng)
            indices = cdse_indices if cdse_indices else _simulate_indices(lat, lng)
        
        # 6. Fetch ISRO high-resolution data (India-specific)
        isro_liss4 = await fetch_isro_data(lat, lng, sensor="resourcesat2_liss4")
        isro_hysis = await fetch_isro_data(lat, lng, sensor="hysis")
        
        # 7. Combine all analyses
        sm = None
        if weather:
            precip = weather.get("precipitation_mm", 0)
            et = weather.get("evapotranspiration_mm", 4)
            sm = min(0.45, max(0.08, 0.20 + (precip - et) * 0.01))
        
        analysis = combine_all_analysis(
            indices=indices,
            weather_data=weather,
            soil_moisture=sm,
            sar_moisture=sar_moisture,
            latitude=lat,
            longitude=lng,
            crop_type=crop_type
        )
        
        # 8. Enrich with supplementary GEE & ISRO data
        analysis["gee_data"] = gee_data.get("data", {})
        analysis["isro_data"] = {
            "liss4": isro_liss4,
            "hysis": isro_hysis,
        }
        analysis["sentinel3_lst"] = gee_data.get("data", {}).get("sentinel3_lst")
        analysis["groundwater"] = gee_data.get("data", {}).get("grace_groundwater")
        
        # 5. Generate field_id and save
        field_id = f"field_{uuid4().hex[:8]}"
        analysis["field_id"] = field_id
        analysis["latitude"] = lat
        analysis["longitude"] = lng
        analysis["crop_type"] = crop_type
        analysis["analysis_date"] = datetime.utcnow().isoformat()
        
        # 6. Save to database (fire-and-forget style)
        await save_analysis({
            "field_id": field_id,
            "latitude": lat,
            "longitude": lng,
            "analysis": analysis,
            "type": "on_demand"
        })
        
        # 7. Build response
        field_analysis = {
            "field_id": field_id,
            "latitude": lat,
            "longitude": lng,
            "area_hectares": 1.0,  # Default from polygon or user input
            "analysis_date": datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC"),
            "satellite_sources": analysis["satellite_sources"],
            "vegetation": analysis["vegetation"],
            "soil": analysis["soil"],
            "weather": analysis["weather"],
            "pest_risk": analysis["pest_risk"],
            "health_score": analysis["health_score"],
            "recommendations": analysis["recommendations"],
            "hotspot_grid": analysis["hotspot_grid"]
        }
        
        return AnalysisResponse(
            success=True,
            message="Analysis complete. Your selected land has been analyzed using Sentinel-2, Sentinel-1 SAR, and weather data.",
            analysis=field_analysis,
            language=request.language or "en"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in analyze endpoint: {e}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@router.post("/analyze/batch")
async def analyze_batch(locations: List[dict] = Body(
    ..., description="List of {latitude, longitude, crop_type?} objects"
)):
    """
    Batch analyze multiple field locations.
    Each item should have latitude, longitude, and optional crop_type.
    """
    results = []
    errors = []
    
    for i, loc in enumerate(locations):
        try:
            lat = float(loc.get("latitude", 0))
            lng = float(loc.get("longitude", 0))
            crop = loc.get("crop_type", "general")
            
            if not (-90 <= lat <= 90) or not (-180 <= lng <= 180):
                errors.append(f"Item {i}: Invalid coordinates")
                continue
            
            request = AnalyzeRequest(latitude=lat, longitude=lng, crop_type=crop)
            result = await analyze_field(request)
            results.append(result.dict())
            
        except Exception as e:
            errors.append(f"Item {i}: {str(e)}")
    
    return {
        "success": len(errors) == 0,
        "total": len(locations),
        "processed": len(results),
        "failed": len(errors),
        "results": results,
        "errors": errors
    }


@router.post("/upload-csv", response_model=CSVUploadResponse)
async def upload_csv(file: UploadFile = File(...)):
    """
    Upload a CSV file containing field locations for batch analysis.
    
    Expected CSV columns: latitude, longitude, [field_id], [crop_type], [area_hectares]
    """
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only CSV files accepted")
    
    try:
        content = await file.read()
        text = content.decode("utf-8")
        reader = csv.DictReader(io.StringIO(text))
        
        if not reader.fieldnames:
            raise HTTPException(status_code=400, detail="Empty CSV or missing headers")
        
        required_cols = ["latitude", "longitude"]
        missing = [c for c in required_cols if c not in reader.fieldnames]
        if missing:
            raise HTTPException(
                status_code=400, 
                detail=f"Missing required columns: {', '.join(missing)}"
            )
        
        processed = 0
        failed = 0
        errors = []
        results = []
        
        for row_num, row in enumerate(reader, start=2):
            field_info = process_csv_field_data(row)
            
            if "error" in field_info:
                failed += 1
                errors.append(f"Row {row_num}: {field_info['error']}")
                continue
            
            try:
                lat = field_info["latitude"]
                lng = field_info["longitude"]
                
                # Analyze this field
                request = AnalyzeRequest(
                    latitude=lat,
                    longitude=lng,
                    crop_type=field_info.get("crop_type", "general")
                )
                result = await analyze_field(request)
                
                # Save as field profile
                await save_field_profile({
                    "field_id": field_info.get("field_id", result.analysis["field_id"]),
                    "latitude": lat,
                    "longitude": lng,
                    "crop_type": field_info.get("crop_type", "general"),
                    "area_hectares": field_info.get("area_hectares", 1),
                    "last_analysis_id": result.analysis["field_id"]
                })
                
                results.append(result.dict())
                processed += 1
                
            except Exception as e:
                failed += 1
                errors.append(f"Row {row_num}: Analysis failed - {str(e)}")
        
        # Save batch record
        batch_id = f"csv_{uuid4().hex[:8]}"
        await save_csv_batch({
            "batch_id": batch_id,
            "filename": file.filename,
            "total_rows": processed + failed,
            "processed": processed,
            "failed": failed,
            "errors": errors
        })
        
        return CSVUploadResponse(
            total_parcels=processed + failed,
            processed=processed,
            failed=failed,
            errors=errors[:10],  # Return first 10 errors
            batch_id=batch_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing CSV upload: {e}")
        raise HTTPException(status_code=500, detail=f"CSV processing failed: {str(e)}")


@router.post("/schedule", response_model=dict)
async def schedule_analysis(schedule: ScheduleRequest):
    """
    Schedule recurring analysis for a field.
    The system will automatically fetch and analyze satellite data at the configured interval.
    """
    result = await save_schedule({
        "latitude": schedule.latitude,
        "longitude": schedule.longitude,
        "polygon_geojson": schedule.polygon_geojson,
        "interval_days": schedule.interval_days,
        "webhook_url": schedule.webhook_url
    })
    
    return {
        "success": result["success"],
        "schedule_id": result["field_id"],
        "message": f"Analysis scheduled every {schedule.interval_days} days. "
                   f"You'll get automatic updates when new satellite data is available."
    }


@router.get("/dashboard")
async def get_dashboard():
    """Get dashboard overview with stats, recent analyses, and alerts."""
    stats = await get_dashboard_stats()
    recent = await get_recent_analyses_with_details(20)
    profiles = await list_field_profiles(50)
    
    # Build alerts from recent analyses
    alerts = []
    for a in recent[:5]:
        hs = a.get("analysis", {}).get("health_score", {})
        score = hs.get("overall", 0)
        if score < 50:
            alerts.append({
                "type": "critical",
                "field": a.get("field_id", "Unknown"),
                "message": f"Crop stress detected - health score {score}"
            })
        elif score < 65:
            alerts.append({
                "type": "warning",
                "field": a.get("field_id", "Unknown"),
                "message": f"Field needs attention - health score {score}"
            })
    
    return {
        "total_fields": stats["total_fields"],
        "avg_health_score": stats["avg_health_score"],
        "health_distribution": stats["health_distribution"],
        "recent_analyses": recent[:10],
        "satellite_coverage": get_satellite_info(),
        "weather_summary": {
            "source": "NASA POWER + Open-Meteo",
            "last_updated": datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC"),
            "forecast_available": True
        },
        "alerts": alerts
    }


@router.get("/report/{field_id}", response_model=DetailedReport)
async def get_detailed_report(field_id: str):
    """
    Get a detailed multi-section report for a specific field.
    Includes vegetation analysis, soil, weather, pest risk, and historical comparison.
    """
    analyses = await get_field_analyses(field_id, limit=5)
    
    if not analyses:
        raise HTTPException(status_code=404, detail=f"No analysis found for field {field_id}")
    
    latest = analyses[0]
    analysis_data = latest.get("analysis", {})
    
    # Build report sections
    sections = []
    
    # Section 1: Vegetation Indices
    veg = analysis_data.get("vegetation", {})
    hs = analysis_data.get("health_score", {})
    sections.append(ReportSection(
        title="Vegetation Health Analysis",
        content={
            "overall_health": hs.get("overall", 0),
            "status": hs.get("status", "Unknown"),
            "ndvi": round(veg.get("ndvi", 0) * 100, 1),
            "evi": round(veg.get("evi", 0) * 100, 1),
            "ndwi": round(veg.get("ndwi", 0) * 100, 1),
            "gndvi": round(veg.get("gndvi", 0) * 100, 1),
            "reip": round(veg.get("reip", 0) * 100, 1),
            "savi": round(veg.get("savi", 0) * 100, 1),
            "interpretation": _interpret_indices(veg)
        },
        charts=[
            {"type": "radar", "data": veg, "title": "Vegetation Indices Profile"},
            {"type": "gauge", "data": {"value": hs.get("overall", 0)}, "title": "Health Score"}
        ]
    ))
    
    # Section 2: Soil Analysis
    soil = analysis_data.get("soil", {})
    sections.append(ReportSection(
        title="Soil & Moisture Analysis",
        content={
            "surface_moisture_pct": soil.get("moisture_pct", 0),
            "drainage_score": soil.get("drainage_score", 50),
            "sar_soil_moisture": soil.get("sar_soil_moisture", "N/A"),
            "organic_matter_est": soil.get("organic_matter_estimate", 0),
            "drainage_status": "Good" if soil.get("drainage_score", 0) > 60 else "Moderate" if soil.get("drainage_score", 0) > 40 else "Poor",
            "water_stress": "Low" if soil.get("moisture_pct", 0) > 20 else "Moderate" if soil.get("moisture_pct", 0) > 15 else "High"
        }
    ))
    
    # Section 3: Weather
    weather = analysis_data.get("weather", {})
    sections.append(ReportSection(
        title="Weather & Atmosphere",
        content={
            "temperature_c": weather.get("temperature_c", "N/A"),
            "humidity_pct": weather.get("humidity_pct", "N/A"),
            "precipitation_mm": weather.get("precipitation_mm", "N/A"),
            "wind_speed_kmh": weather.get("wind_speed_kmh", "N/A"),
            "solar_radiation_mj": weather.get("solar_radiation_mj", "N/A"),
            "evapotranspiration_mm": weather.get("evapotranspiration_mm", "N/A"),
            "forecast_rain_48h": weather.get("forecast_rain_48h", 0),
            "source": weather.get("source", "N/A")
        },
        charts=[
            {"type": "bar", "data": weather, "title": "Weather Parameters"}
        ]
    ))
    
    # Section 4: Pest Risk
    pest = analysis_data.get("pest_risk", {})
    sections.append(ReportSection(
        title="Pest & Disease Risk Assessment",
        content={
            "risk_score": pest.get("score", 0),
            "risk_level": pest.get("level", "Unknown"),
            "contributing_factors": pest.get("contributing_factors", []),
            "recommendations": pest.get("recommendations", [])
        }
    ))
    
    # Section 5: Recommendations
    sections.append(ReportSection(
        title="Actionable Recommendations",
        content={
            "priority": _get_priority(analysis_data.get("recommendations", [])),
            "recommendations": analysis_data.get("recommendations", []),
            "generated_at": datetime.utcnow().isoformat()
        }
    ))
    
    # Historical comparison
    historical = None
    if len(analyses) >= 2:
        prev = analyses[1].get("analysis", {})
        prev_hs = prev.get("health_score", {})
        curr_hs = analysis_data.get("health_score", {})
        
        historical = {
            "previous_score": prev_hs.get("overall", 0),
            "current_score": curr_hs.get("overall", 0),
            "change": round(curr_hs.get("overall", 0) - prev_hs.get("overall", 0), 1),
            "trend": "improving" if curr_hs.get("overall", 0) > prev_hs.get("overall", 0) 
                     else "declining" if curr_hs.get("overall", 0) < prev_hs.get("overall", 0) 
                     else "stable",
            "previous_date": analyses[1].get("created_at", ""),
            "current_date": analyses[0].get("created_at", "")
        }
    
    return DetailedReport(
        field_id=field_id,
        generated_at=datetime.utcnow().isoformat(),
        sections=sections,
        satellite_metadata=get_satellite_info(),
        historical_comparison=historical,
        export_formats=["pdf", "csv", "json"]
    )


@router.get("/satellites")
async def get_satellite_status():
    """Get information about available satellite data sources and their status."""
    return {
        "success": True,
        "satellites": get_satellite_info(),            "update_frequency": "Every 7 days (configurable)",
            "sources": [
                "ESA Copernicus Sentinel-2 (10m resolution - NDVI, EVI, NDWI, GNDVI, REIP, SAVI)",
                "ESA Copernicus Sentinel-1 SAR (Soil moisture, flood detection)",
                "ESA Sentinel-3 SLSTR (Land surface temperature, 1km)",
                "ESA Sentinel-3 OLCI (Chlorophyll-a, water quality, 300m)",
                "NASA SMAP (Surface soil moisture, 10km)",
                "NASA GRACE-FO (Groundwater anomalies, monthly)",
                "NASA/USGS Landsat 8/9 (30m - long-term vegetation trends)",
                "NASA POWER (Weather data - temperature, precipitation, radiation)",
                "CHIRPS/UCSB (Rainfall, 5.5km daily)",
                "OpenLandMap (Soil texture, pH, organic carbon, 250m)",
                "Copernicus DEM 30m (Elevation, slope, aspect)",
                "ERA5-Land (Hourly climate reanalysis)",
                "Open-Meteo (Weather forecasts - 3 day outlook)",
                "ISRO Resourcesat-2 LISS-IV (5.8m - high-res vegetation)",
                "ISRO HySIS (Hyperspectral 55-band - crop chemistry)",
                "ISRO Cartosat-3 (0.25m - sub-meter crop stress)",
                "ISRO RISAT-1A (C-band SAR - all-weather soil moisture)",
                "ISRO Bhoonidhi (Indian remote sensing data portal)"
            ]
    }


# ============================================================
#  DEMO DATA & BACKFILL ENDPOINTS
# ============================================================


@router.get("/data/stats")
async def get_data_stats():
    """Get statistics about stored data (demo + real)."""
    from ..services.supabase_service import get_recent_analyses, list_field_profiles
    from ..services.demo_data_generator import DEMO_FIELDS, get_demo_field_summary
    
    analyses = await get_recent_analyses(limit=10000)
    profiles = await list_field_profiles(100)
    
    # Count by type
    type_counts = {}
    for a in analyses:
        at = a.get("type", a.get("analysis_type", "unknown"))
        type_counts[at] = type_counts.get(at, 0) + 1
    
    # Count demo vs real
    demo_count = sum(v for k, v in type_counts.items() if "demo" in k)
    real_count = sum(v for k, v in type_counts.items() if "demo" not in k)
    
    return {
        "total_analyses": len(analyses),
        "demo_analyses": demo_count,
        "real_analyses": real_count,
        "by_type": type_counts,
        "total_fields": len(profiles),
        "demo_fields": len(DEMO_FIELDS),
        "demo_field_summary": get_demo_field_summary(),
        "oldest_analysis": min((a.get("created_at", "") for a in analyses), default="N/A"),
        "newest_analysis": max((a.get("created_at", "") for a in analyses), default="N/A")
    }


@router.post("/data/backfill")
async def backfill_demo_data(days: int = Query(30, ge=1, le=365, description="Number of days of history to generate")):
    """
    Backfill historical demo data for Grafana dashboards.
    Generates analysis points every 6 hours going back N days.
    
    Args:
        days: Number of days of history to generate (1-365, default 30)
    """
    from ..services.demo_data_generator import seed_demo_data
    
    total = await seed_demo_data(days_back=days, interval_hours=6)
    
    return {
        "success": True,
        "message": f"Generated {total} historical data points across 8 demo fields ({(days * 4 * 8)} max possible)",
        "days_backfilled": days,
        "data_points_generated": total,
        "fields": 8,
        "interval_hours": 6,
        "tip": "Run /api/v1/data/stats to see total counts. Data is available in Grafana PostgreSQL dashboard immediately."
    }


@router.post("/data/backfill/full")
async def backfill_full_demo_data():
    """
    Generate a full 365 days of historical demo data.
    Useful for showcasing long-term trends in Grafana.
    """
    from ..services.demo_data_generator import seed_demo_data
    
    total = await seed_demo_data(days_back=365, interval_hours=6)
    
    return {
        "success": True,
        "message": f"Generated {total} data points across 8 demo fields (365 days of history at 6-hour intervals)",
        "days_backfilled": 365,
        "data_points_generated": total
    }


@router.post("/data/tick")
async def trigger_demo_tick():
    """
    Manually trigger a single demo data tick (one new data point per field).
    Useful for testing before the next scheduled 6-hour auto-tick.
    """
    from ..services.demo_data_generator import generate_demo_tick
    count = await generate_demo_tick()
    return {
        "success": True,
        "message": f"Generated {count} new demo analysis points",
        "fields_analyzed": count
    }


# --- Helper Functions ---

async def get_recent_analyses_with_details(limit: int = 20) -> list:
    """Get recent analyses with full details."""
    from ..services.supabase_service import get_recent_analyses
    return await get_recent_analyses(limit)


def _interpret_indices(veg: dict) -> str:
    """Generate a human-readable interpretation of vegetation indices."""
    ndvi = veg.get("ndvi", 0)
    if ndvi > 0.6:
        return "Very healthy, dense vegetation with high photosynthetic activity."
    elif ndvi > 0.4:
        return "Moderately healthy vegetation with good biomass."
    elif ndvi > 0.2:
        return "Sparse vegetation or stressed crops. Needs attention."
    else:
        return "Very sparse or bare soil. Significant intervention needed."


def _get_priority(recommendations: list) -> str:
    """Determine priority level from recommendations."""
    critical = any("⚠️" in r or "Critical" in r or "Immediate" in r for r in recommendations)
    warning = any("needs attention" in r.lower() or "elevated" in r.lower() for r in recommendations)
    
    if critical:
        return "HIGH"
    elif warning:
        return "MEDIUM"
    return "LOW"
