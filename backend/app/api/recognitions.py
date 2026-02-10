"""
Recognition API endpoints (eCards, feed, leaderboard).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.ecards import ECardCreate, ECardResponse
from app.schemas.recognition_feed import RecognitionFeedResponse

router = APIRouter()


@router.post("/", response_model=ECardResponse, status_code=status.HTTP_201_CREATED)
def send_recognition(
    ecard: ECardCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Send an eCard recognition to a peer."""
    # TODO: Implement send eCard logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/feed", response_model=List[RecognitionFeedResponse])
def get_recognition_feed(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get company-wide recognition feed."""
    # TODO: Implement get feed logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/{recognition_id}", response_model=ECardResponse)
def get_recognition(
    recognition_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get specific recognition details."""
    # TODO: Implement get recognition logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/auto")
def get_auto_recognitions(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get automated recognitions (celebrations, etc.)."""
    # TODO: Implement get auto recognitions logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/leaderboard")
def get_leaderboard(
    period: str = "MONTHLY",  # MONTHLY, YEARLY
    metric: str = "POINTS",   # POINTS, COUNT
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get recognition leaderboard."""
    # TODO: Implement leaderboard logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )
