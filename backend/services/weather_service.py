"""
Krishi Drishti - Weather Service
Integrates NASA POWER API (primary) and Open-Meteo (fallback)
to provide temperature, precipitation, humidity, solar radiation,
evapotranspiration, and 48-hour forecast.
"""
import logging
from typing import Optional, Dict, Any
from datetime import datetime, timedelta

import httpx

logger = logging.getLogger(__name__)

# NASA POWER API endpoint
NASA_POWER_URL = "https://power.larc.nasa.gov/api/temporal/daily/point"

# Open-Meteo API endpoint (fallback)
OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"


async def fetch_weather_data(
    latitude: float,
    longitude: float,
) -> Optional[Dict[str, Any]]:
    """
    Fetch comprehensive weather data for agriculture from NASA POWER + Open-Meteo.
    
    Returns temperature, humidity, precipitation, solar radiation, ET, and forecast.
    """
    # Try NASA POWER first
    power_data = await _fetch_nasa_power(latitude, longitude)
    
    # Get forecast from Open-Meteo (always available, no API key)
    forecast = await _fetch_open_meteo_forecast(latitude, longitude)
    
    if power_data:
        combined = {**power_data}
        if forecast:
            combined.update(forecast)
        return combined
    
    # Fallback to Open-Meteo only
    if forecast:
        # Estimate evapotranspiration from temperature + solar radiation
        temp = forecast.get("temperature_c", 30)
        solar = forecast.get("solar_radiation_mj", 20)
        forecast["evapotranspiration_mm"] = round(0.0023 * temp * solar ** 0.5, 2)
        forecast["source"] = "Open-Meteo"
        return forecast
    
    return None


async def _fetch_nasa_power(
    latitude: float,
    longitude: float,
) -> Optional[Dict[str, Any]]:
    """Fetch daily weather data from NASA POWER API (free, no API key)."""
    try:
        params = {
            "parameters": "T2M,RH2M,PRECTOTCORR,ALLSKY_SFC_SW_DWN,EVLAND,WS2M",
            "community": "AG",
            "longitude": round(longitude, 4),
            "latitude": round(latitude, 4),
            "start": (datetime.utcnow() - timedelta(days=7)).strftime("%Y%m%d"),
            "end": datetime.utcnow().strftime("%Y%m%d"),
            "format": "JSON"
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(NASA_POWER_URL, params=params)
            
            if response.status_code == 200:
                data = response.json()
                props = data.get("properties", {}).get("parameter", {})
                
                # Get the most recent available date
                dates = []
                for key in props.get("T2M", {}):
                    dates.append(key)
                
                if not dates:
                    return None
                
                latest_date = max(dates)
                
                # Extract values
                t2m = props.get("T2M", {}).get(latest_date, 30)
                rh2m = props.get("RH2M", {}).get(latest_date, 60)
                precip = props.get("PRECTOTCORR", {}).get(latest_date, 0)
                solar = props.get("ALLSKY_SFC_SW_DWN", {}).get(latest_date, 20)
                et = props.get("EVLAND", {}).get(latest_date, 4.5)
                wind = props.get("WS2M", {}).get(latest_date, 10)
                
                logger.info(f"Successfully fetched NASA POWER data for {latitude},{longitude}")
                
                return {
                    "temperature_c": round(t2m, 1),
                    "humidity_pct": round(rh2m, 1),
                    "precipitation_mm": round(max(0, precip), 2),
                    "wind_speed_kmh": round(wind * 3.6, 1),  # Convert m/s to km/h
                    "solar_radiation_mj": round(solar, 2),
                    "evapotranspiration_mm": round(et, 2),
                    "source": "NASA POWER",
                    "data_date": latest_date
                }
            else:
                logger.warning(f"NASA POWER API error {response.status_code}")
                return None
                
    except Exception as e:
        logger.error(f"Exception fetching NASA POWER data: {e}")
        return None


async def _fetch_open_meteo_forecast(
    latitude: float,
    longitude: float,
) -> Optional[Dict[str, Any]]:
    """Fetch weather forecast from Open-Meteo (free, no API key needed)."""
    try:
        params = {
            "latitude": round(latitude, 4),
            "longitude": round(longitude, 4),
            "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max",
            "current_weather": "true",
            "hourly": "relativehumidity_2m",
            "timezone": "auto",
            "forecast_days": 3
        }
        
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.get(OPEN_METEO_URL, params=params)
            
            if response.status_code == 200:
                data = response.json()
                
                # Current weather
                current = data.get("current_weather", {})
                temp = current.get("temperature", 30)
                wind = current.get("windspeed", 10)
                
                # Humidity from hourly (average first 24 hours)
                hourly = data.get("hourly", {})
                humidities = hourly.get("relativehumidity_2m", [60])
                avg_humidity = sum(humidities[:24]) / len(humidities[:24]) if humidities[:24] else 60
                
                # Daily forecast for rain
                daily = data.get("daily", {})
                precip_today = daily.get("precipitation_sum", [0])[0] if daily.get("precipitation_sum") else 0
                precip_tomorrow = daily.get("precipitation_sum", [0])[1] if len(daily.get("precipitation_sum", [])) > 1 else 0
                
                # Solar radiation estimate from temperature (simplified)
                solar_est = max(5, min(35, temp * 0.8 + 5))
                
                logger.info(f"Successfully fetched Open-Meteo data for {latitude},{longitude}")
                
                return {
                    "temperature_c": round(temp, 1),
                    "humidity_pct": round(avg_humidity, 1),
                    "precipitation_mm": round(precip_today, 2),
                    "wind_speed_kmh": round(wind, 1),
                    "solar_radiation_mj": round(solar_est, 2),
                    "evapotranspiration_mm": round(0.0023 * temp * solar_est ** 0.5, 2),
                    "forecast_rain_48h": round(precip_today + precip_tomorrow, 2),
                    "source": "Open-Meteo",
                    "data_date": current.get("time", datetime.utcnow().strftime("%Y-%m-%d"))
                }
            else:
                logger.warning(f"Open-Meteo API error {response.status_code}")
                return None
                
    except Exception as e:
        logger.error(f"Exception fetching Open-Meteo data: {e}")
        return None
