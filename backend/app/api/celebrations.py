"""
Celebrations API endpoints (birthdays, anniversaries).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.celebrations import CelebrationResponse

router = APIRouter()


@router.get("/upcoming", response_model=List[CelebrationResponse])
def get_upcoming_celebrations(
    days: int = 7,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get upcoming celebrations (birthdays, anniversaries)."""
    # TODO: Implement get upcoming celebrations logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/history", response_model=List[CelebrationResponse])
def get_celebration_history(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get past celebrations."""
    # TODO: Implement get celebration history logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.post("/{celebration_id}/retry")
def retry_celebration(
    celebration_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Retry a failed celebration event (admin only)."""
    # TODO: Implement retry celebration logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )
