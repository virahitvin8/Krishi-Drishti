"""Krishi Drishti - Data Models"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


# --- Request Models ---

class AnalyzeRequest(BaseModel):
    """Request to analyze a land parcel"""
    latitude: float = Field(..., ge=-90, le=90, description="Center latitude")
    longitude: float = Field(..., ge=-180, le=180, description="Center longitude")
    polygon_geojson: Optional[Dict[str, Any]] = Field(None, description="GeoJSON polygon of the field")
    crop_type: Optional[str] = Field("general", description="Optional crop type for tailored analysis")
    language: Optional[str] = Field("en", description="Language code (en/hi/te)")


class CSVUploadResponse(BaseModel):
    """Response after CSV upload"""
    total_parcels: int
    processed: int
    failed: int
    errors: List[str] = []
    batch_id: str


class ScheduleRequest(BaseModel):
    """Request to schedule periodic analysis"""
    latitude: float
    longitude: float
    polygon_geojson: Optional[Dict[str, Any]]
    interval_days: int = Field(7, ge=1, le=90)
    webhook_url: Optional[str] = None


# --- Response Models ---

class SatelliteSource(BaseModel):
    """Satellite data source info"""
    name: str
    mission: str
    resolution_m: float
    bands_used: List[str]
    acquisition_date: str
    cloud_cover_pct: Optional[float] = None


class VegetationIndices(BaseModel):
    ndvi: float = Field(..., description="Normalized Difference Vegetation Index (0-1)")
    evi: float = Field(..., description="Enhanced Vegetation Index (0-1)")
    ndwi: float = Field(..., description="Normalized Difference Water Index (-1 to 1)")
    gndvi: float = Field(..., description="Green NDVI (0-1)")
    reip: Optional[float] = Field(None, description="Red Edge Inflection Point")
    savi: Optional[float] = Field(None, description="Soil Adjusted Vegetation Index")


class SoilAnalysis(BaseModel):
    moisture_pct: float = Field(..., description="Soil moisture percentage")
    drainage_score: float = Field(..., description="Drainage score 0-100")
    sar_soil_moisture: Optional[float] = Field(None, description="SAR-derived soil moisture")
    organic_matter_estimate: Optional[float] = None


class WeatherData(BaseModel):
    temperature_c: float
    humidity_pct: float
    precipitation_mm: float
    wind_speed_kmh: float
    solar_radiation_mj: float
    evapotranspiration_mm: float
    forecast_rain_48h: float
    source: str = "NASA POWER + Open-Meteo"


class PestRisk(BaseModel):
    score: float = Field(..., description="Pest risk score 0-100")
    level: str = Field(..., description="Low / Moderate / High")
    contributing_factors: List[str] = []
    recommendations: List[str] = []


class HealthScore(BaseModel):
    overall: float = Field(..., description="Overall crop health 0-100")
    status: str = Field(..., description="Text status")
    color: str = Field(..., description="Hex color code")


class FieldAnalysis(BaseModel):
    """Complete analysis for a single field/parcel"""
    field_id: str
    latitude: float
    longitude: float
    area_hectares: float
    analysis_date: str
    satellite_sources: List[SatelliteSource]
    vegetation: VegetationIndices
    soil: SoilAnalysis
    weather: WeatherData
    pest_risk: PestRisk
    health_score: HealthScore
    recommendations: List[str]
    hotspot_grid: Optional[List[Dict[str, Any]]] = None


class AnalysisResponse(BaseModel):
    """Complete analysis response"""
    success: bool
    message: str
    analysis: Optional[FieldAnalysis] = None
    language: str = "en"


class DashboardData(BaseModel):
    """Dashboard overview data"""
    total_fields: int
    avg_health_score: float
    health_distribution: Dict[str, int]
    recent_analyses: List[FieldAnalysis]
    satellite_coverage: Dict[str, Any]
    weather_summary: Dict[str, Any]
    alerts: List[Dict[str, str]]


class ReportSection(BaseModel):
    title: str
    content: Dict[str, Any]
    charts: Optional[List[Dict[str, Any]]] = None


class DetailedReport(BaseModel):
    field_id: str
    generated_at: str
    sections: List[ReportSection]
    satellite_metadata: Dict[str, Any]
    historical_comparison: Optional[Dict[str, Any]] = None
    export_formats: List[str] = ["pdf", "csv", "json"]
