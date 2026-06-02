"""
Krishi Drishti - Supabase Database Service
Manages field data, analysis records, CSV upload batches, and user preferences.
"""
import logging
import json
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
from uuid import uuid4

from ..config import SUPABASE_URL, SUPABASE_KEY

logger = logging.getLogger(__name__)

# Try to import supabase client
try:
    from supabase import create_client, Client
    _supabase: Optional[Client] = None
    if SUPABASE_URL and SUPABASE_KEY:
        _supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        logger.info("Supabase client initialized")
except ImportError:
    _supabase = None
    logger.warning("supabase-py not installed - using in-memory fallback")

# In-memory fallback storage when Supabase is not configured
_memory_store: Dict[str, List[Dict[str, Any]]] = {
    "analyses": [],
    "field_profiles": [],
    "csv_batches": [],
    "schedules": []
}


# --- Field Profiles ---

async def save_field_profile(field_data: Dict[str, Any]) -> Dict[str, Any]:
    """Save or update a field profile."""
    field_id = field_data.get("field_id") or f"field_{uuid4().hex[:8]}"
    field_data["field_id"] = field_id
    field_data["created_at"] = datetime.utcnow().isoformat()
    
    if _supabase:
        try:
            result = _supabase.table("field_profiles").upsert(field_data).execute()
            return {"success": True, "field_id": field_id, "data": result.data}
        except Exception as e:
            logger.error(f"Supabase error saving field profile: {e}")
    
    _memory_store["field_profiles"].append(field_data)
    return {"success": True, "field_id": field_id, "data": field_data}


async def get_field_profile(field_id: str) -> Optional[Dict[str, Any]]:
    """Get a field profile by ID."""
    if _supabase:
        try:
            result = _supabase.table("field_profiles").select("*").eq("field_id", field_id).execute()
            if result.data:
                return result.data[0]
        except Exception as e:
            logger.error(f"Supabase error fetching field profile: {e}")
    
    for fp in _memory_store["field_profiles"]:
        if fp.get("field_id") == field_id:
            return fp
    return None


async def list_field_profiles(limit: int = 50) -> List[Dict[str, Any]]:
    """List all saved field profiles."""
    if _supabase:
        try:
            result = _supabase.table("field_profiles").select("*").limit(limit).execute()
            return result.data or []
        except Exception as e:
            logger.error(f"Supabase error listing field profiles: {e}")
    
    return _memory_store["field_profiles"][-limit:]


# --- Analysis Records ---

async def save_analysis(analysis_data: Dict[str, Any]) -> Dict[str, Any]:
    """Save an analysis result."""
    analysis_id = f"analysis_{uuid4().hex[:12]}"
    analysis_data["analysis_id"] = analysis_id
    analysis_data["created_at"] = datetime.utcnow().isoformat()
    
    if _supabase:
        try:
            result = _supabase.table("analyses").insert(analysis_data).execute()
            return {"success": True, "analysis_id": analysis_id, "data": result.data}
        except Exception as e:
            logger.error(f"Supabase error saving analysis: {e}")
    
    _memory_store["analyses"].append(analysis_data)
    return {"success": True, "analysis_id": analysis_id, "data": analysis_data}


async def get_field_analyses(field_id: str, limit: int = 10) -> List[Dict[str, Any]]:
    """Get analysis history for a field."""
    if _supabase:
        try:
            result = _supabase.table("analyses") \
                .select("*") \
                .eq("field_id", field_id) \
                .order("created_at", desc=True) \
                .limit(limit) \
                .execute()
            return result.data or []
        except Exception as e:
            logger.error(f"Supabase error fetching analyses: {e}")
    
    analyses = [a for a in _memory_store["analyses"] if a.get("field_id") == field_id]
    return sorted(analyses, key=lambda x: x.get("created_at", ""), reverse=True)[:limit]


async def get_recent_analyses(limit: int = 20) -> List[Dict[str, Any]]:
    """Get most recent analyses across all fields."""
    if _supabase:
        try:
            result = _supabase.table("analyses") \
                .select("*") \
                .order("created_at", desc=True) \
                .limit(limit) \
                .execute()
            return result.data or []
        except Exception as e:
            logger.error(f"Supabase error fetching recent analyses: {e}")
    
    return sorted(_memory_store["analyses"], 
                  key=lambda x: x.get("created_at", ""), reverse=True)[:limit]


# --- CSV Batches ---

async def save_csv_batch(batch_data: Dict[str, Any]) -> Dict[str, Any]:
    """Save a CSV upload batch."""
    batch_id = f"batch_{uuid4().hex[:8]}"
    batch_data["batch_id"] = batch_id
    batch_data["created_at"] = datetime.utcnow().isoformat()
    
    if _supabase:
        try:
            result = _supabase.table("csv_batches").insert(batch_data).execute()
            return {"success": True, "batch_id": batch_id, "data": result.data}
        except Exception as e:
            logger.error(f"Supabase error saving CSV batch: {e}")
    
    _memory_store["csv_batches"].append(batch_data)
    return {"success": True, "batch_id": batch_id, "data": batch_data}


# --- Scheduled Analyses ---

async def save_schedule(schedule_data: Dict[str, Any]) -> Dict[str, Any]:
    """Save a scheduled recurring analysis."""
    schedule_id = f"sched_{uuid4().hex[:8]}"
    schedule_data["schedule_id"] = schedule_id
    schedule_data["created_at"] = datetime.utcnow().isoformat()
    schedule_data["last_run"] = None
    schedule_data["next_run"] = (datetime.utcnow() + timedelta(days=schedule_data.get("interval_days", 7))).isoformat()
    
    if _supabase:
        try:
            result = _supabase.table("schedules").insert(schedule_data).execute()
            return {"success": True, "schedule_id": schedule_id, "data": result.data}
        except Exception as e:
            logger.error(f"Supabase error saving schedule: {e}")
    
    _memory_store["schedules"].append(schedule_data)
    return {"success": True, "schedule_id": schedule_id, "data": schedule_data}


async def get_due_schedules() -> List[Dict[str, Any]]:
    """Get all schedules that are due for execution."""
    now = datetime.utcnow().isoformat()
    if _supabase:
        try:
            result = _supabase.table("schedules") \
                .select("*") \
                .lte("next_run", now) \
                .execute()
            return result.data or []
        except Exception as e:
            logger.error(f"Supabase error fetching due schedules: {e}")
    
    due = []
    for s in _memory_store["schedules"]:
        if s.get("next_run") and s["next_run"] <= now:
            due.append(s)
    return due


async def update_schedule_run(schedule_id: str) -> None:
    """Update the last_run and next_run times for a schedule."""
    now = datetime.utcnow()
    if _supabase:
        try:
            _supabase.table("schedules") \
                .update({
                    "last_run": now.isoformat(),
                    "next_run": (now + timedelta(days=7)).isoformat()
                }) \
                .eq("schedule_id", schedule_id) \
                .execute()
        except Exception as e:
            logger.error(f"Supabase error updating schedule: {e}")
        return
    
    for s in _memory_store["schedules"]:
        if s.get("schedule_id") == schedule_id:
            s["last_run"] = now.isoformat()
            s["next_run"] = (now + timedelta(days=7)).isoformat()
            break


# --- Dashboard Data ---

async def get_dashboard_stats() -> Dict[str, Any]:
    """Get aggregated dashboard statistics."""
    analyses = await get_recent_analyses(100)
    profiles = await list_field_profiles(100)
    
    if not analyses:
        return {
            "total_fields": len(profiles),
            "avg_health_score": 0,
            "health_distribution": {"healthy": 0, "good": 0, "moderate": 0, "stressed": 0},
            "recent_count": 0
        }
    
    scores = []
    distribution = {"healthy": 0, "good": 0, "moderate": 0, "stressed": 0}
    
    for a in analyses:
        hs = a.get("analysis", {}).get("health_score", {})
        score = hs.get("overall", 0)
        scores.append(score)
        
        if score >= 80:
            distribution["healthy"] += 1
        elif score >= 65:
            distribution["good"] += 1
        elif score >= 50:
            distribution["moderate"] += 1
        else:
            distribution["stressed"] += 1
    
    avg = round(sum(scores) / len(scores), 1) if scores else 0
    
    return {
        "total_fields": len(profiles),
        "avg_health_score": avg,
        "health_distribution": distribution,
        "recent_count": len(analyses)
    }
