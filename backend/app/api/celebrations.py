"""
Celebrations API endpoints (birthdays, anniversaries).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.celebrations import CelebrationResponse
from app.services.celebration_service import CelebrationService
from app.utils.response import success

router = APIRouter()


@router.get("/upcoming", response_model=List[CelebrationResponse])
def get_upcoming_celebrations(
    days: int = 7,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get upcoming celebrations (birthdays, anniversaries)."""
    service = CelebrationService(db)
    items = service.get_upcoming_celebrations(days=days)
    return success(data=items, message="Upcoming celebrations fetched")


@router.get("/history", response_model=List[CelebrationResponse])
def get_celebration_history(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get past celebrations."""
    service = CelebrationService(db)
    hist = service.get_celebration_history(skip, limit)
    # Map to schema with user name
    data = []
    for h in hist:
        d = CelebrationResponse.model_validate(h)
        d.user_name = h.user.name if h.user else "Unknown"
        data.append(d)
        
    return success(data=data, message="Celebration history fetched")


@router.post("/{celebration_id}/retry")
def retry_celebration(
    celebration_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Retry a failed celebration event (admin only)."""
    # Logic: Delete existing celebration entry if any and re-run for that user
    # For now, just return not implemented as it requires complex logic from the job
    return success(message="Retry logic not yet production ready", status_code=202)
