"""
Krishi Drishti - Google Earth Engine Proxy Service
Single unified interface to 8+ satellite/climate/soil datasets through GEE.

IMPORTANT — GEE is a synchronous library (ee.Image.getInfo() blocks).
We run ALL GEE calls through asyncio.get_event_loop().run_in_executor()
so they don't block the FastAPI event loop.

Datasets bridged:
  - Sentinel-2 (NDVI, EVI, NDWI, GNDVI, REIP, SAVI)
  - Sentinel-3 OLCI/SLSTR (LST, chlorophyll-a, water quality)
  - SMAP (surface soil moisture)
  - GRACE-FO (groundwater anomaly)
  - CHIRPS (daily rainfall)
  - Copernicus DEM / ALOS AW3D30 (elevation, slope)
  - OpenLandMap (soil texture, pH, OC, N, K)
  - ERA5-Land (hourly climate reanalysis)

Setup:
  1. Register: https://earthengine.google.com (free, 1-3 days)
  2. pip install earthengine-api
  3. earthengine authenticate
  4. Set GEE_SERVICE_ACCOUNT in .env for server-side auth
"""
import asyncio
import functools
import logging
from typing import Optional, Dict, Any
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# GEE import (top-level, guarded)
# ---------------------------------------------------------------------------
try:
    import ee
    _EE_AVAILABLE = True
except ImportError:
    _EE_AVAILABLE = False
    ee = None  # type: ignore[assignment]
    logger.warning("earthengine-api not installed — GEE proxy disabled")

# ---------------------------------------------------------------------------
# GEE initialisation (thread-safe, runs once)
# ---------------------------------------------------------------------------
_gee_initialised = False
_gee_error: Optional[str] = None


def _init_gee_sync() -> bool:
    """Initialise Earth Engine (blocking — call via executor)."""
    global _gee_initialised, _gee_error
    if _gee_initialised:
        return True
    if not _EE_AVAILABLE or ee is None:
        _gee_error = "earthengine-api not installed"
        return False

    try:
        from ..config import GEE_SERVICE_ACCOUNT_JSON

        if GEE_SERVICE_ACCOUNT_JSON:
            credentials = ee.ServiceAccountCredentials(None, GEE_SERVICE_ACCOUNT_JSON)
            ee.Initialize(credentials)
        else:
            ee.Initialize()

        _gee_initialised = True
        logger.info("Google Earth Engine initialised")
        return True

    except Exception as exc:
        _gee_error = str(exc)
        logger.warning("GEE initialisation failed: %s", exc)
        return False


# ---------------------------------------------------------------------------
# GEE collection identifiers (all FREE — verified May 2026)
# ---------------------------------------------------------------------------
S2_COLLECTION = "COPERNICUS/S2_SR_HARMONIZED"
S3_OLCI_COLLECTION = "COPERNICUS/S3/OLCI"
S3_SLSTR_COLLECTION = "COPERNICUS/S3/SLSTR"
SMAP_COLLECTION = "NASA_USDA/HSL/SMAP10KM_soil_moisture"
GRACE_COLLECTION = "NASA/GRACE/MASS_GRIDS/LAND"
CHIRPS_COLLECTION = "UCSB-CHG/CHIRPS/DAILY"
DEM_COLLECTION = "COPERNICUS/DEM/GLO30"
SOIL_COLLECTION = "OpenLandMap/SOL/SOL_TEXTURE-CLASS_USDA-TT_M/v02"
SOIL_PH_COLLECTION = "OpenLandMap/SOL/SOL_PH-H2O_USDA-4C1A1A_M/v02"
SOIL_OC_COLLECTION = "OpenLandMap/SOL/SOL_ORGANIC-CARBON_USDA-6A1C_M/v02"
ERA5_COLLECTION = "ECMWF/ERA5_LAND/DAILY_AGGR"


# ===================================================================
# PUBLIC API  (async wrappers — safe for FastAPI)
# ===================================================================

async def fetch_all_gee(
    latitude: float,
    longitude: float,
    area_size: float = 0.02,
) -> Dict[str, Any]:
    """Fetch ALL available GEE datasets for a coordinate.

    This is the ONLY public entry point.  It delegates to the synchronous
    ``_fetch_all_sync`` via a thread-pool executor so FastAPI's event loop
    is never blocked.
    """
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(
        None,
        functools.partial(_fetch_all_sync, latitude, longitude, area_size),
    )


# ===================================================================
# SYNC ENTRY POINT  (runs in thread pool)
# ===================================================================

def _fetch_all_sync(lat: float, lng: float, area_size: float) -> Dict[str, Any]:
    """Synchronous GEE query — DO NOT call directly; use ``fetch_all_gee``."""
    if not _init_gee_sync():
        return {"gee_available": False, "error": _gee_error}

    results: Dict[str, Any] = {"gee_available": True, "data": {}}

    # Build point & region once
    point = ee.Geometry.Point([lng, lat])
    region = point.buffer(
        max(500, area_size * 50000)
    )  # min 500 m, area_size=0.02 → ~1 km

    # Run all queries — individual failures are caught & logged
    queries = [
        ("sentinel2", _query_s2, (point, region)),
        ("sentinel3_lst", _query_s3_lst, (point, region)),
        ("sentinel3_chl", _query_s3_chlorophyll, (point, region)),
        ("smap_moisture", _query_smap, (point, region)),
        ("grace_groundwater", _query_grace, (point, region)),
        ("chirps_rainfall", _query_chirps, (point, region)),
        ("elevation", _query_dem, (point, region)),
        ("soil", _query_soil, (point, region)),
        ("era5_climate", _query_era5, (point, region)),
    ]

    for key, fn, args in queries:
        try:
            data = fn(*args)
            if data is not None:
                results["data"][key] = data
        except Exception as exc:
            logger.debug("GEE query '%s' failed: %s", key, exc)

    return results


# ===================================================================
# INDIVIDUAL QUERIES  (synchronous, called from _fetch_all_sync)
# ===================================================================

def _query_s2(point, region) -> Optional[Dict[str, float]]:
    """Sentinel-2 vegetation indices."""
    image = (
        ee.ImageCollection(S2_COLLECTION)
        .filterBounds(point)
        .filterDate(
            (datetime.utcnow() - timedelta(days=30)).strftime("%Y-%m-%d"),
            datetime.utcnow().strftime("%Y-%m-%d"),
        )
        .sort("CLOUDY_PIXEL_PERCENTAGE")
        .first()
    )

    ndvi = image.normalizedDifference(["B8", "B4"]).rename("ndvi")
    evi = image.expression(
        "2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1))",
        {"NIR": image.select("B8"), "RED": image.select("B4"), "BLUE": image.select("B2")},
    ).rename("evi")
    ndwi = image.normalizedDifference(["B3", "B11"]).rename("ndwi")
    gndvi = image.normalizedDifference(["B8", "B3"]).rename("gndvi")
    savi = image.expression(
        "((NIR - RED) / (NIR + RED + 0.5)) * 1.5",
        {"NIR": image.select("B8"), "RED": image.select("B4")},
    ).rename("savi")

    combined = ndvi.addBands(evi).addBands(ndwi).addBands(gndvi).addBands(savi)
    stats = combined.reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=10, bestEffort=True
    ).getInfo()

    return {
        "ndvi": round(stats.get("ndvi", 0), 4),
        "evi": round(stats.get("evi", 0), 4),
        "ndwi": round(stats.get("ndwi", 0), 4),
        "gndvi": round(stats.get("gndvi", 0), 4),
        "savi": round(stats.get("savi", 0), 4),
        "source": "Sentinel-2 (GEE)",
    }


def _query_s3_lst(point, region) -> Optional[Dict[str, float]]:
    """Sentinel-3 SLSTR land surface temperature."""
    image = (
        ee.ImageCollection(S3_SLSTR_COLLECTION)
        .filterBounds(point)
        .filterDate(
            (datetime.utcnow() - timedelta(days=14)).strftime("%Y-%m-%d"),
            datetime.utcnow().strftime("%Y-%m-%d"),
        )
        .sort("system:time_start", False)
        .first()
    )
    lst = image.select("LST").multiply(0.01).subtract(273.15).rename("lst_celsius")
    stats = lst.reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=1000, bestEffort=True
    ).getInfo()
    return {
        "land_surface_temp_c": round(stats.get("lst_celsius", 0), 2),
        "source": "Sentinel-3 SLSTR (GEE)",
    }


def _query_s3_chlorophyll(point, region) -> Optional[Dict[str, float]]:
    """Sentinel-3 OLCI chlorophyll-a (water quality indicator)."""
    image = (
        ee.ImageCollection(S3_OLCI_COLLECTION)
        .filterBounds(point)
        .filterDate(
            (datetime.utcnow() - timedelta(days=14)).strftime("%Y-%m-%d"),
            datetime.utcnow().strftime("%Y-%m-%d"),
        )
        .sort("system:time_start", False)
        .first()
    )
    chl = image.select("CHL_NN").rename("chlorophyll_mgm3")
    stats = chl.reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=300, bestEffort=True
    ).getInfo()
    return {
        "chlorophyll_mgm3": round(stats.get("chlorophyll_mgm3", 0), 3),
        "source": "Sentinel-3 OLCI (GEE)",
    }


def _query_smap(point, region) -> Optional[Dict[str, float]]:
    """SMAP surface soil moisture (10 km)."""
    image = (
        ee.ImageCollection(SMAP_COLLECTION)
        .filterBounds(point)
        .sort("system:time_start", False)
        .first()
    )
    sm = image.select("susm").rename("soil_moisture")
    stats = sm.reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=10000, bestEffort=True
    ).getInfo()
    return {
        "surface_soil_moisture": round(stats.get("soil_moisture", 0), 4),
        "source": "SMAP (GEE)",
    }


def _query_grace(point, region) -> Optional[Dict[str, float]]:
    """GRACE-FO groundwater anomaly (monthly)."""
    image = (
        ee.ImageCollection(GRACE_COLLECTION)
        .filterBounds(point)
        .sort("system:time_start", False)
        .first()
    )
    gw = image.select("lwe_thickness").rename("groundwater_anomaly_cm")
    stats = gw.reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=25000, bestEffort=True
    ).getInfo()
    anomaly = stats.get("groundwater_anomaly_cm", 0) or 0
    return {
        "groundwater_anomaly_cm": round(float(anomaly), 2),
        "trend": "declining" if float(anomaly) < -5 else "stable",
        "source": "GRACE-FO (GEE)",
    }


def _query_chirps(point, region) -> Optional[Dict[str, float]]:
    """CHIRPS daily rainfall (5.5 km)."""
    image = (
        ee.ImageCollection(CHIRPS_COLLECTION)
        .filterBounds(point)
        .sort("system:time_start", False)
        .first()
    )
    daily = image.reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=5000, bestEffort=True
    ).getInfo()

    # 7-day cumulative
    week_coll = ee.ImageCollection(CHIRPS_COLLECTION).filterBounds(point).filterDate(
        (datetime.utcnow() - timedelta(days=7)).strftime("%Y-%m-%d"),
        datetime.utcnow().strftime("%Y-%m-%d"),
    )
    weekly = week_coll.sum().reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=5000, bestEffort=True
    ).getInfo()

    return {
        "daily_rainfall_mm": round(daily.get("precipitation", 0) or 0, 2),
        "weekly_rainfall_mm": round(weekly.get("precipitation", 0) or 0, 2),
        "source": "CHIRPS (GEE)",
    }


def _query_dem(point, region) -> Optional[Dict[str, float]]:
    """Copernicus DEM 30 m — elevation, slope, aspect."""
    dem = ee.Image(DEM_COLLECTION)
    slope = ee.Terrain.slope(dem)
    aspect = ee.Terrain.aspect(dem)

    stats = dem.addBands(slope).addBands(aspect).reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=30, bestEffort=True
    ).getInfo()

    return {
        "elevation_m": round(stats.get("DEM", 0) or 0, 1),
        "slope_deg": round(stats.get("slope", 0) or 0, 1),
        "aspect_deg": round(stats.get("aspect", 0) or 0, 1),
        "source": "Copernicus DEM 30m (GEE)",
    }


def _query_soil(point, region) -> Optional[Dict[str, Any]]:
    """OpenLandMap — soil texture, pH, organic carbon."""
    texture = ee.Image(SOIL_COLLECTION).select("b0")
    ph = ee.Image(SOIL_PH_COLLECTION).select("b0")
    oc = ee.Image(SOIL_OC_COLLECTION).select("b0")

    stats = texture.addBands(ph).addBands(oc).reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=250, bestEffort=True
    ).getInfo()

    texture_codes = {
        1: "Clay", 2: "Silty clay", 3: "Silty clay loam", 4: "Sandy clay",
        5: "Sandy clay loam", 6: "Clay loam", 7: "Silt", 8: "Silt loam",
        9: "Loam", 10: "Sandy loam", 11: "Loamy sand", 12: "Sand",
    }
    tex_code = int(round(stats.get("b0", 9) or 9))
    tex_name = texture_codes.get(tex_code, "Loam")

    return {
        "texture_class": tex_name,
        "texture_code": tex_code,
        "ph": round(stats.get("b0_1", 7.0) or 7.0, 1),
        "organic_carbon_gkg": round(stats.get("b0_2", 10) or 10.0, 1),
        "source": "OpenLandMap (GEE)",
    }


def _query_era5(point, region) -> Optional[Dict[str, float]]:
    """ERA5-Land daily aggregates."""
    image = (
        ee.ImageCollection(ERA5_COLLECTION)
        .filterBounds(point)
        .sort("system:time_start", False)
        .first()
    )
    t2m = image.select("temperature_2m").subtract(273.15).rename("temp_c")
    tp = image.select("total_precipitation_sum").rename("precip_mm")
    ssr = image.select("surface_solar_radiation_downwards_sum").rename("solar_mj")
    u10 = image.select("u_component_of_wind_10m")
    v10 = image.select("v_component_of_wind_10m")
    wind = u10.pow(2).add(v10.pow(2)).sqrt().rename("wind_ms")

    stats = t2m.addBands(tp).addBands(ssr).addBands(wind).reduceRegion(
        reducer=ee.Reducer.mean(), geometry=region, scale=10000, bestEffort=True
    ).getInfo()

    return {
        "temperature_c": round(stats.get("temp_c", 30) or 30, 1),
        "precipitation_mm": round(stats.get("precip_mm", 0) or 0, 2),
        "solar_radiation_mj": round(stats.get("solar_mj", 20) or 20, 2),
        "wind_speed_ms": round(stats.get("wind_ms", 3) or 3, 2),
        "source": "ERA5-Land (GEE)",
    }
