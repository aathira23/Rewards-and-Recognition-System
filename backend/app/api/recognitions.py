"""
Recognition API endpoints (eCards, feed, leaderboard, badges).
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user_id, get_current_user
from app.schemas.ecards import ECardCreate, ECardResponse
from app.schemas.recognition_feed import RecognitionFeedResponse
from app.schemas.badges import BadgeCreate, BadgeUpdate, BadgeResponse
from app.services.recognition_service import RecognitionService
from app.utils.response import success, created, client_error, conflict, server_error, paginated_success
from app.utils.constants import (
    DEFAULT_PAGE_SIZE, SUCCESS_RECOGNITION_SENT, SUCCESS_FEED_RETRIEVED,
    SUCCESS_OVERVIEW_RETRIEVED, SUCCESS_LEADERBOARD_RETRIEVED,
    ERROR_ONLY_HR_ADMIN_CREATE_BADGE, SUCCESS_BADGE_CREATED,
    ERROR_FAILED_CREATE_BADGE, ERROR_ONLY_HR_ADMIN_UPDATE_BADGE,
    SUCCESS_BADGE_UPDATED, SUCCESS_BADGES_RETRIEVED, ERROR_ECARD_NOT_FOUND,
    SUCCESS_RECOGNITION_FOUND
)

router = APIRouter()


@router.post("/", status_code=status.HTTP_201_CREATED)
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
        # Populate department names in nested user objects
        if data.sender and ecard.sender:
            data.sender.department_name = ecard.sender.department.name if ecard.sender.department else None
        if data.receiver and ecard.receiver:
            data.receiver.department_name = ecard.receiver.department.name if ecard.receiver.department else None
        return created(data=data.model_dump(), message=SUCCESS_RECOGNITION_SENT)
    except ValueError as e:
        return client_error(message=str(e))


@router.get("/feed")
def get_recognition_feed(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get company-wide recognition feed."""
    service = RecognitionService(db)
    total, items = service.get_recognition_feed(page=page, per_page=per_page)
    data = []
    for item in items:
        feed_item = RecognitionFeedResponse.model_validate(item)
        # Populate department names in nested user objects
        if feed_item.actor and item.actor:
            feed_item.actor.department_name = item.actor.department.name if item.actor.department else None
        if feed_item.receiver and item.receiver:
            feed_item.receiver.department_name = item.receiver.department.name if item.receiver.department else None
        data.append(feed_item.model_dump())
    return paginated_success(
        items=data,
        total=total,
        page=page,
        per_page=per_page,
        message=SUCCESS_FEED_RETRIEVED,
    )


@router.get("/me/overview")
def get_my_appreciation_overview(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get recognitions received and sent by current user."""
    service = RecognitionService(db)
    overview = service.get_appreciation_overview(user_id=current_user_id)
    # Service already returns serialized data, use it directly
    return success(data=overview, message=SUCCESS_OVERVIEW_RETRIEVED)


@router.get("/leaderboard")
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
    return success(data=data, message=SUCCESS_LEADERBOARD_RETRIEVED)


# Badges (Used for eCards)
@router.post("/badges", status_code=status.HTTP_201_CREATED)
def create_badge(
    badge: BadgeCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new badge (HR only)."""
    from app.utils.enums import UserRole
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ONLY_HR_ADMIN_CREATE_BADGE, status_code=403)

    service = RecognitionService(db)
    try:
        badge_obj = service.create_badge(
            name=badge.name,
            description=badge.description,
            icon_url=badge.icon_url
        )
        data = BadgeResponse.model_validate(badge_obj)
        return created(data=data.model_dump(), message=SUCCESS_BADGE_CREATED)
    except ValueError as e:
        # Duplicate badge name
        return conflict(message=str(e), data={"field": "name", "value": badge.name})
    except Exception:
        return server_error(message=ERROR_FAILED_CREATE_BADGE, data=None)


@router.put("/badges/{badge_id}")
def update_badge(
    badge_id: int,
    badge: BadgeUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a badge (HR only)."""
    from app.utils.enums import UserRole
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ONLY_HR_ADMIN_UPDATE_BADGE, status_code=403)

    service = RecognitionService(db)
    try:
        updated = service.update_badge(badge_id, badge.model_dump(exclude_unset=True))
        data = BadgeResponse.model_validate(updated)
        return success(data=data.model_dump(), message=SUCCESS_BADGE_UPDATED)
    except ValueError as e:
        return client_error(message=str(e), status_code=status.HTTP_404_NOT_FOUND)


@router.get("/badges")
def get_badges(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get all badges."""
    service = RecognitionService(db)
    badges = service.get_badges()
    data = [BadgeResponse.model_validate(b).model_dump() for b in badges]
    return success(data=data, message=SUCCESS_BADGES_RETRIEVED)


@router.get("/{recognition_id}")
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
        return client_error(message=ERROR_ECARD_NOT_FOUND, status_code=status.HTTP_404_NOT_FOUND)
    data = ECardResponse.model_validate(ecard)
    # Populate department names in nested user objects
    if data.sender and ecard.sender:
        data.sender.department_name = ecard.sender.department.name if ecard.sender.department else None
    if data.receiver and ecard.receiver:
        data.receiver.department_name = ecard.receiver.department.name if ecard.receiver.department else None
    return success(data=data.model_dump(), message=SUCCESS_RECOGNITION_FOUND)
