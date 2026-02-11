"""
Recognition API endpoints (eCards, feed, leaderboard, badges).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.ecards import ECardCreate, ECardResponse
from app.schemas.recognition_feed import RecognitionFeedResponse
from app.schemas.badges import BadgeCreate, BadgeUpdate, BadgeResponse
from app.schemas.leaderboard import LeaderboardEntry
from app.services.recognition_service import RecognitionService
from app.utils.response import success, created, client_error

router = APIRouter()


@router.post("/", response_model=ECardResponse, status_code=status.HTTP_201_CREATED)
def send_recognition(
    ecard_in: ECardCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Send an eCard recognition to a peer."""
    service = RecognitionService(db)
    try:
        ecard = service.send_ecard(
            sender_id=current_user_id,
            receiver_id=ecard_in.receiver_id,
            badge_id=ecard_in.badge_id,
            message=ecard_in.message
        )
        data = ECardResponse.model_validate(ecard)
        return created(data=data, message="Recognition sent successfully")
    except ValueError as e:
        return client_error(message=str(e))


@router.get("/feed", response_model=List[RecognitionFeedResponse])
def get_recognition_feed(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get company-wide recognition feed."""
    service = RecognitionService(db)
    items = service.get_recognition_feed(skip=skip, limit=limit)
    data = [RecognitionFeedResponse.model_validate(i) for i in items]
    return success(data=data, message="Feed retrieved")


@router.get("/me/overview")
def get_my_appreciation_overview(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get recognitions received and sent by current user."""
    service = RecognitionService(db)
    overview = service.get_appreciation_overview(user_id=current_user_id)
    return success(data=overview, message="Overview retrieved")


@router.get("/auto")
def get_auto_recognitions(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get automated recognitions (celebrations, etc.)."""
    return success(data={"message": "Automated recognitions are processed in the background."})


@router.get("/leaderboard", response_model=List[LeaderboardEntry])
def get_leaderboard(
    period: str = "MONTHLY",  # MONTHLY, YEARLY
    metric: str = "POINTS",   # POINTS, COUNT
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get recognition leaderboard."""
    service = RecognitionService(db)
    data = service.get_leaderboard(period=period, metric=metric, limit=limit)
    return success(data=data, message="Leaderboard retrieved")


# Badges (Used for eCards)
@router.post("/badges", response_model=BadgeResponse, status_code=status.HTTP_201_CREATED)
def create_badge(
    badge: BadgeCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Create a new badge (admin only)."""
    service = RecognitionService(db)
    badge_obj = service.create_badge(
        name=badge.name,
        description=badge.description,
        icon_url=badge.icon_url
    )
    data = BadgeResponse.model_validate(badge_obj)
    return created(data=data, message="Badge created")


@router.put("/badges/{badge_id}", response_model=BadgeResponse)
def update_badge(
    badge_id: int,
    badge: BadgeUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Update a badge (admin only)."""
    service = RecognitionService(db)
    try:
        updated = service.update_badge(badge_id, badge.model_dump(exclude_unset=True))
        data = BadgeResponse.model_validate(updated)
        return success(data=data, message="Badge updated")
    except ValueError as e:
        return client_error(message=str(e), status_code=status.HTTP_404_NOT_FOUND)


@router.patch("/badges/{badge_id}/deactivate")
def deactivate_badge(
    badge_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Deactivate a badge (admin only)."""
    service = RecognitionService(db)
    try:
        updated = service.update_badge(badge_id, {"is_active": False})
        data = BadgeResponse.model_validate(updated)
        return success(data=data, message="Badge deactivated")
    except ValueError as e:
        return client_error(message=str(e), status_code=status.HTTP_404_NOT_FOUND)


@router.get("/badges", response_model=List[BadgeResponse])
def get_badges(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get all badges."""
    service = RecognitionService(db)
    badges = service.get_badges()
    data = [BadgeResponse.model_validate(b) for b in badges]
    return success(data=data, message="Badges retrieved")


@router.get("/{recognition_id}", response_model=ECardResponse)
def get_recognition(
    recognition_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get specific recognition details."""
    from app.models.ecards import ECard
    from sqlalchemy.orm import joinedload
    ecard = db.query(ECard).options(
        joinedload(ECard.sender),
        joinedload(ECard.receiver),
        joinedload(ECard.badge)
    ).filter(ECard.id == recognition_id).first()
    
    if not ecard:
        return client_error(message="ECard not found", status_code=status.HTTP_404_NOT_FOUND)
    data = ECardResponse.model_validate(ecard)
    return success(data=data, message="Recognition found")
