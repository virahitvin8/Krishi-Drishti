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
from .routers import analysis, translation, grafana

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
            "ESA Copernicus Sentinel-2 (10m optical)",
            "ESA Copernicus Sentinel-1 SAR (10m radar)",
            "NASA/USGS Landsat 8/9 (30m)",
            "NASA POWER (weather)",
            "Open-Meteo (forecast)",
            "ISRO Bhoonidhi (Indian satellites)"
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
