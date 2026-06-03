"""
Krishi Drishti Backend v4.0
Complete satellite data analysis API for Indian farmers.
Integrates: Sentinel-2, Sentinel-1 SAR, Landsat, NASA POWER, Open-Meteo, ISRO Bhoonidhi
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import APP_NAME, APP_VERSION
from .services.scheduler import start_scheduler, stop_scheduler
from .routers import analysis, translation, grafana, user, quantum

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle: start scheduler on boot, stop on shutdown."""
    logger.info(f"{APP_NAME} v{APP_VERSION} starting up...")
    start_scheduler()
    yield
    logger.info(f"{APP_NAME} shutting down...")
    stop_scheduler()


app = FastAPI(
    title=APP_NAME,
    version=APP_VERSION,
    description="""
    Krishi Drishti - Satellite Vision for Smart Farming
    
    Integrates multiple satellite data sources to provide:
    - Crop health analysis (NDVI, EVI, NDWI, GNDVI, REIP, SAVI)
    - Soil moisture estimation (Sentinel-1 SAR + optical)
    - Weather data (NASA POWER + Open-Meteo)
    - Pest risk scoring
    - Drainage analysis
    - Actionable recommendations for farmers
    
    Supported satellites: Sentinel-2, Sentinel-1 SAR, Landsat 8/9, ISRO Resourcesat
    Supported languages: English, हिन्दी, తెలుగు
    
    Grafana Integration: /api/v1/grafana/* endpoints for real-time dashboards
    """,
    lifespan=lifespan,
    contact={
        "name": "Krishi Drishti Team",
        "url": "https://krishidrishti.netlify.app",
    },
    license_info={
        "name": "MIT License",
    }
)

# --- CORS Middleware ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Include Routers ---
app.include_router(analysis.router)
app.include_router(translation.router)
app.include_router(grafana.router)
app.include_router(user.router)
app.include_router(quantum.router)


# --- Health Check Endpoints ---

@app.get("/")
async def root():
    """Root endpoint with API info."""
    return {
        "name": APP_NAME,
        "version": APP_VERSION,
        "status": "running",
        "endpoints": {
            "health": "/health",
            "analyze": "/api/v1/analyze",
            "dashboard": "/api/v1/dashboard",
            "upload_csv": "/api/v1/upload-csv",
            "schedule": "/api/v1/schedule",
            "report": "/api/v1/report/{field_id}",
            "satellites": "/api/v1/satellites",
            "translate": "/api/v1/translate/{language}",
            "grafana_dashboard_json": "/api/v1/grafana/dashboard-json",
            "grafana_query": "/api/v1/grafana/query/*",
            "docs": "/docs"
        },
        "data_sources": [
            "1  · Landsat 8/9 · NASA/USGS · 30m · 8-day · Longest veg record (1982)",
            "2  · Sentinel-2 A/B · ESA · 10m · 5-day · NDVI, EVI, NDWI, GNDVI, SAVI",
            "3  · Sentinel-1 C-band SAR · ESA · 10m · 6-day · Soil moisture, flood",
            "4  · Sentinel-3 SLSTR · ESA · 1km · Daily · Land surface temperature",
            "5  · Sentinel-3 OLCI · ESA · 300m · Daily · Chlorophyll, water quality",
            "6  · SMAP · NASA · 10km · 3-day · Surface soil moisture",
            "7  · GRACE-FO · NASA · Monthly · Groundwater anomaly trends",
            "8  · MODIS NDVI · NASA · 250m · 16-day · Long-term vegetation trends",
            "9  · CHIRPS · UCSB · 5.5km · Daily · Rainfall",
            "10 · Copernicus DEM · ESA · 30m · Static · Elevation, slope, aspect",
            "11 · OpenLandMap · ISRIC · 250m · Static · Soil texture, pH, organic C",
            "12 · ERA5-Land · ECMWF · 11km · Hourly · Climate reanalysis",
            "13 · NASA POWER · NASA · 0.5° · Daily · Temp, humidity, solar, ET",
            "14 · Open-Meteo · Free · 5km · 3-day · Weather forecast",
            "15 · Cartosat-3 · ISRO · 0.25m · 5-day · Sub-meter crop stress",
            "16 · Resourcesat-2 LISS-IV · ISRO · 5.8m · 5-day · Field-scale veg",
            "17 · HySIS · ISRO · 30m/55band · 30-day · Crop chemistry (N,P,K)",
            "18 · RISAT-1A · ISRO · 3-25m · 12-day · All-weather SAR",
        ],
        "languages": ["English", "हिन्दी", "తెలుగు"],
        "grafana_integration": {
            "status": "available",
            "dashboard_endpoint": "/api/v1/grafana/dashboard-json",
            "query_endpoints": [
                "/api/v1/grafana/query/ndvi-trend",
                "/api/v1/grafana/query/vegetation-indices",
                "/api/v1/grafana/query/health-trend",
                "/api/v1/grafana/query/weather-trend",
                "/api/v1/grafana/query/field-summary",
                "/api/v1/grafana/query/field-locations",
                "/api/v1/grafana/query/pest-risk-trend",
                "/api/v1/grafana/query/recommendations"
            ]
        },
        "message": "जय किसान! Krishi Drishti is ready to serve."
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring."""
    return {
        "status": "healthy",
        "version": APP_VERSION,
        "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
        "services": {
            "api": "running",
            "scheduler": "active",
            "cdse": "configured",
            "weather": "configured",
            "grafana": "available"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
