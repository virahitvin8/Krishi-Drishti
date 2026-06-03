"""
Krishi Drishti - User Profile Router
Endpoints for user registration, login, saved fields, and preferences.
"""
import logging
import json
from typing import Optional, Dict, Any, List
from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, HTTPException, Header, Body

from ..models import (
    UserProfileCreate, UserProfileUpdate, UserProfileResponse,
    SavedField
)
from ..services.supabase_service import (
    save_user_profile, get_user_profile, update_user_profile,
    save_user_field, get_user_fields, delete_user_field
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/user", tags=["User"])


@router.post("/register")
async def register_user(profile: UserProfileCreate):
    """Register a new user profile."""
    try:
        result = await save_user_profile(profile.dict())
        return {
            "success": True,
            "message": "Profile created successfully",
            "user": result
        }
    except Exception as e:
        logger.error(f"Error registering user: {e}")
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")


@router.get("/{username}")
async def get_user(username: str):
    """Get user profile with saved fields."""
    try:
        user = await get_user_profile(username)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return {"success": True, "user": user}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{username}")
async def update_user(username: str, update: UserProfileUpdate):
    """Update user profile."""
    try:
        result = await update_user_profile(username, update.dict(exclude_none=True))
        return {"success": True, "message": "Profile updated", "user": result}
    except Exception as e:
        logger.error(f"Error updating user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{username}/login")
async def login_user(username: str):
    """Record user login and return profile."""
    try:
        user = await get_user_profile(username)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        # Update last_login
        await update_user_profile(username, {"last_login": datetime.utcnow().isoformat()})
        return {"success": True, "message": "Login recorded", "user": user}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error logging in: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# --- Saved Fields ---

@router.post("/{username}/fields")
async def save_field(username: str, field: SavedField):
    """Save a field to user's profile."""
    try:
        result = await save_user_field(username, field.dict())
        return {"success": True, "message": "Field saved", "field": result}
    except Exception as e:
        logger.error(f"Error saving field: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{username}/fields")
async def list_saved_fields(username: str):
    """List all saved fields for a user."""
    try:
        fields = await get_user_fields(username)
        return {"success": True, "fields": fields}
    except Exception as e:
        logger.error(f"Error listing fields: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{username}/fields/{field_id}")
async def remove_saved_field(username: str, field_id: str):
    """Remove a saved field."""
    try:
        await delete_user_field(username, field_id)
        return {"success": True, "message": "Field removed"}
    except Exception as e:
        logger.error(f"Error removing field: {e}")
        raise HTTPException(status_code=500, detail=str(e))
