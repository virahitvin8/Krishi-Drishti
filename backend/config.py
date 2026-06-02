"""Krishi Drishti - Configuration Module"""
import os
from dotenv import load_dotenv

load_dotenv()

# --- CDSE (Copernicus Data Space Ecosystem) ---
CDSE_CLIENT_ID = os.getenv("CDSE_CLIENT_ID", "")
CDSE_CLIENT_SECRET = os.getenv("CDSE_CLIENT_SECRET", "")
CDSE_TOKEN_URL = "https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token"
CDSE_PROCESS_URL = "https://sh.dataspace.copernicus.eu/api/v1/process"
CDSE_WMS_BASE = "https://sh.dataspace.copernicus.eu/ogc/wms"

# --- USGS / NASA ---
USGS_USERNAME = os.getenv("USGS_USERNAME", "")
USGS_PASSWORD = os.getenv("USGS_PASSWORD", "")
NASA_EARTHDATA_USER = os.getenv("NASA_EARTHDATA_USER", "")
NASA_EARTHDATA_PASS = os.getenv("NASA_EARTHDATA_PASS", "")

# --- ISRO Bhoonidhi ---
BHOONIDHI_USER = os.getenv("BHOONIDHI_USER", "")
BHOONIDHI_PASS = os.getenv("BHOONIDHI_PASS", "")

# --- Supabase ---
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

# --- App Config ---
APP_NAME = "Krishi Drishti"
APP_VERSION = "4.0.0"
DEFAULT_LAT = 25.3176
DEFAULT_LNG = 82.9739
SATELLITE_REFRESH_DAYS = 7
MAX_CSV_UPLOAD_MB = 10

# --- Supported Languages ---
SUPPORTED_LANGUAGES = {
    "en": "English",
    "hi": "हिन्दी",
    "te": "తెలుగు"
}
