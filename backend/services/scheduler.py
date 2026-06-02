"""
Krishi Drishti - Automated Scheduler
Manages periodic satellite data fetching and analysis.
Uses APScheduler for background task scheduling.
"""
import logging
import asyncio
from datetime import datetime, timedelta
from typing import Optional

from ..config import SATELLITE_REFRESH_DAYS

logger = logging.getLogger(__name__)

# Try to import APScheduler
try:
    from apscheduler.schedulers.asyncio import AsyncIOScheduler
    _scheduler: Optional[AsyncIOScheduler] = None
    HAS_SCHEDULER = True
except ImportError:
    _scheduler = None
    HAS_SCHEDULER = False
    logger.warning("APScheduler not installed - auto-refresh disabled")


async def run_scheduled_analysis(latitude: float, longitude: float, field_id: str):
    """
    Run a complete analysis for a scheduled field.
    Called by the scheduler at configured intervals.
    """
    from .cdse_service import fetch_sentinel2_indices, fetch_sentinel1_soil_moisture
    from .weather_service import fetch_weather_data
    from .analysis_service import combine_all_analysis
    from .supabase_service import save_analysis
    
    logger.info(f"Running scheduled analysis for field {field_id} ({latitude}, {longitude})")
    
    try:
        # Fetch all data in parallel
        indices_task = fetch_sentinel2_indices(latitude, longitude)
        weather_task = fetch_weather_data(latitude, longitude)
        sar_task = fetch_sentinel1_soil_moisture(latitude, longitude)
        
        # Gather results
        indices = await indices_task
        weather = await weather_task
        sar_moisture = await sar_task
        
        if not indices:
            logger.warning(f"No satellite data for scheduled analysis {field_id}")
            return
        
        # Combine analysis
        analysis = combine_all_analysis(
            indices=indices,
            weather_data=weather,
            soil_moisture=weather.get("soil_moisture_pct", 0) / 100 if weather else None,
            sar_moisture=sar_moisture,
            latitude=latitude,
            longitude=longitude
        )
        
        analysis["field_id"] = field_id
        analysis["scheduled"] = True
        
        # Save to database
        result = await save_analysis({
            "field_id": field_id,
            "latitude": latitude,
            "longitude": longitude,
            "analysis": analysis,
            "type": "scheduled"
        })
        
        logger.info(f"Scheduled analysis completed for field {field_id}: {result.get('analysis_id')}")
        
    except Exception as e:
        logger.error(f"Error in scheduled analysis for {field_id}: {e}")


def start_scheduler():
    """Start the background scheduler for periodic tasks."""
    global _scheduler
    
    if not HAS_SCHEDULER:
        logger.warning("Cannot start scheduler - APScheduler not installed")
        return
    
    if _scheduler and _scheduler.running:
        logger.info("Scheduler already running")
        return
    
    _scheduler = AsyncIOScheduler()
    
    # Check for due schedules every hour
    _scheduler.add_job(
        _check_due_schedules,
        trigger="interval",
        hours=1,
        id="check_due_schedules",
        replace_existing=True
    )
    
    # Refresh satellite info daily
    _scheduler.add_job(
        _log_satellite_status,
        trigger="interval",
        hours=24,
        id="satellite_status",
        replace_existing=True
    )
    
    _scheduler.start()
    logger.info("Background scheduler started successfully")


async def _check_due_schedules():
    """Check and execute due scheduled analyses."""
    from .supabase_service import get_due_schedules, update_schedule_run
    from ..config import SATELLITE_REFRESH_DAYS
    
    logger.info("Checking for due scheduled analyses...")
    
    schedules = await get_due_schedules()
    for schedule in schedules:
        schedule_id = schedule.get("schedule_id")
        lat = schedule.get("latitude")
        lng = schedule.get("longitude")
        field_id = schedule.get("field_id", schedule_id)
        
        if lat and lng:
            await run_scheduled_analysis(lat, lng, field_id)
            await update_schedule_run(schedule_id)


async def _log_satellite_status():
    """Log satellite data availability status."""
    logger.info(f"Satellite data refresh cycle: every {SATELLITE_REFRESH_DAYS} days")
    
    # Update satellite pass schedules
    today = datetime.utcnow()
    sentinel2_pass = today + timedelta(days=5 - (today.day % 5))
    sentinel1_pass = today + timedelta(days=6 - (today.day % 6))
    landsat_pass = today + timedelta(days=8 - (today.day % 8))
    
    logger.info(
        f"Next satellite passes - Sentinel-2: {sentinel2_pass.date()}, "
        f"Sentinel-1: {sentinel1_pass.date()}, "
        f"Landsat: {landsat_pass.date()}"
    )


def stop_scheduler():
    """Stop the background scheduler."""
    global _scheduler
    if _scheduler and _scheduler.running:
        _scheduler.shutdown(wait=False)
        logger.info("Scheduler stopped")
