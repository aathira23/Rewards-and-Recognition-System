"""
Recognition API endpoints (eCards, feed, leaderboard, badges).
"""
from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.dependencies import get_current_user_id, get_current_user
from app.schemas.ecards import ECardCreate, ECardResponse, UserShortResponse
from app.schemas.recognition_feed import RecognitionFeedResponse
from app.schemas.badges import BadgeCreate, BadgeUpdate, BadgeResponse
from app.services.recognition_service import RecognitionService
from app.services.user_profiles_client import get_users_batch
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

_oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")


def _enrich_user(profiles: dict, user_id: int) -> UserShortResponse:
    """Build a UserShortResponse from a profiles dict, or a stub if not found.

    The dict values can be either UserProfile (user_service mode) or
    UserShortResponse (local mode) — both expose .id, .name, .department_name.
    """
    p = profiles.get(user_id)
    if p is None:
        return UserShortResponse(id=user_id, name=f"User {user_id}", department_name=None)
    if isinstance(p, UserShortResponse):
        return p
    return UserShortResponse(id=p.id, name=p.name, department_name=p.department_name)


def _get_local_user_profiles(db: Session, user_ids: list) -> dict:
    """Local-mode alternative to get_users_batch.

    Queries the local users table so that local DB primary-key IDs are
    resolved to correct names — not mis-mapped via the external User Service.
    Returns Dict[int, UserShortResponse].
    """
    from app.models.users import User as UserModel
    from sqlalchemy.orm import joinedload as _joinedload
    users = (
        db.query(UserModel)
        .options(_joinedload(UserModel.department))
        .filter(UserModel.id.in_(user_ids))
        .all()
    )
    return {
        u.id: UserShortResponse(
            id=u.id,
            name=u.name,
            department_name=u.department.name if u.department else None,
        )
        for u in users
    }


def _resolve_profiles(db: Session, user_ids: list, token: str) -> dict:
    """Return a {user_id: UserShortResponse-or-UserProfile} dict.

    Uses the local DB in 'local' AUTH_MODE so that local auto-increment IDs
    are not incorrectly forwarded to the external User Service (which may
    have completely different users under the same integer IDs).
    """
    if not user_ids:
        return {}
    if settings.AUTH_MODE == "local":
        return _get_local_user_profiles(db, user_ids)
    return get_users_batch(user_ids, token)


@router.post("/", status_code=status.HTTP_201_CREATED)
def send_recognition(
    ecard_in: ECardCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
    token: str = Depends(_oauth2_scheme)
):
    """Send an eCard recognition to a peer."""
    service = RecognitionService(db, token=token)
    try:
        ecard = service.send_ecard(
            sender_id=current_user_id,
            receiver_id=ecard_in.receiver_id,
            badge_id=ecard_in.badge_id,
            message=ecard_in.message,
            token=token,
            persona_type=ecard_in.persona_type,
            persona_label=ecard_in.persona_label,
        )
        data = ECardResponse.model_validate(ecard)
        # Enrich sender/receiver: use local DB in local mode, User Service otherwise
        profiles = _resolve_profiles(db, [ecard.sender_id, ecard.receiver_id], token)
        # When persona is DEPARTMENT the sender identity should stay anonymous
        if ecard.persona_type == "PERSONAL":
            data.sender = _enrich_user(profiles, ecard.sender_id)
        else:
            # Return a synthetic sender with the persona label so the
            # receiver only sees the department name, not the real person.
            data.sender = UserShortResponse(
                id=0,
                name=ecard.persona_label or "Anonymous",
                department_name=ecard.persona_label,
            )
        data.receiver = _enrich_user(profiles, ecard.receiver_id)
        return created(data=data.model_dump(), message=SUCCESS_RECOGNITION_SENT)
    except ValueError as e:
        return client_error(message=str(e))


@router.get("/feed")
def get_recognition_feed(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
    token: str = Depends(_oauth2_scheme)
):
    """Get company-wide recognition feed."""
    service = RecognitionService(db)
    total, items = service.get_recognition_feed(page=page, per_page=per_page)

    # Batch-fetch all user profiles needed for the feed in one call
    user_ids = list({uid for item in items for uid in [item.actor_id, item.receiver_id] if uid})
    profiles = _resolve_profiles(db, user_ids, token)

    data = []
    for item in items:
        feed_item = RecognitionFeedResponse.model_validate(item)
        # If actor_label is set (department persona), show anonymous sender
        if item.actor_label:
            feed_item.actor = UserShortResponse(
                id=0,
                name=item.actor_label,
                department_name=item.actor_label,
            )
        else:
            feed_item.actor = _enrich_user(profiles, item.actor_id)
        if item.receiver_id:
            feed_item.receiver = _enrich_user(profiles, item.receiver_id)
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
    current_user_id: int = Depends(get_current_user_id),
    token: str = Depends(_oauth2_scheme)
):
    """Get recognitions received and sent by current user."""
    service = RecognitionService(db)
    overview = service.get_appreciation_overview(user_id=current_user_id)

    # Enrich sender/receiver on each ecard from User Service
    all_ecards = overview.get("received", []) + overview.get("sent", [])
    user_ids = list(
        {ec.get("sender_id") for ec in all_ecards if ec.get("sender_id")}
        | {ec.get("receiver_id") for ec in all_ecards if ec.get("receiver_id")}
    )
    if user_ids:
        profiles = _resolve_profiles(db, list(user_ids), token)
        for ec in all_ecards:
            # Respect persona anonymity: if DEPARTMENT persona, hide real sender
            if ec.get("persona_type") == "DEPARTMENT" and ec.get("persona_label"):
                ec["sender"] = UserShortResponse(
                    id=0,
                    name=ec["persona_label"],
                    department_name=ec["persona_label"],
                ).model_dump()
            elif ec.get("sender_id"):
                ec["sender"] = _enrich_user(profiles, ec["sender_id"]).model_dump()
            if ec.get("receiver_id"):
                ec["receiver"] = _enrich_user(profiles, ec["receiver_id"]).model_dump()

    return success(data=overview, message=SUCCESS_OVERVIEW_RETRIEVED)


@router.get("/leaderboard")
def get_leaderboard(
    period: str = "MONTHLY",  # MONTHLY, YEARLY
    metric: str = "POINTS",   # POINTS, COUNT
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
    token: str = Depends(_oauth2_scheme)
):
    """Get recognition leaderboard."""
    service = RecognitionService(db)
    data = service.get_leaderboard(period=period, metric=metric, limit=limit)
    
    # Fetch latest profiles from User Service (if not local mode) to match Feed
    user_ids = [item.get("user_id") for item in data if item.get("user_id")]
    if user_ids:
        profiles = _resolve_profiles(db, user_ids, token)
        for item in data:
            uid = item.get("user_id")
            if uid in profiles:
                p = profiles[uid]
                item["name"] = p.name
                item["department_name"] = getattr(p, "department_name", None)
            else:
                item["name"] = f"User {uid}"

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
    current_user = Depends(get_current_user)
):
    """Get all badges. HR/Admin receive all badges including inactive ones."""
    from app.utils.enums import UserRole
    service = RecognitionService(db)
    is_hr_admin = current_user.role in (UserRole.HR.value, UserRole.ADMIN.value)
    badges = service.get_badges(active_only=not is_hr_admin)
    data = [BadgeResponse.model_validate(b).model_dump() for b in badges]
    return success(data=data, message=SUCCESS_BADGES_RETRIEVED)


@router.get("/{recognition_id}")
def get_recognition(
    recognition_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
    token: str = Depends(_oauth2_scheme)
):
    """Get specific recognition details."""
    from app.models.ecards import ECard
    ecard = db.query(ECard).filter(ECard.id == recognition_id).first()

    if not ecard:
        return client_error(message=ERROR_ECARD_NOT_FOUND, status_code=status.HTTP_404_NOT_FOUND)
    data = ECardResponse.model_validate(ecard)
    profiles = _resolve_profiles(db, [ecard.sender_id, ecard.receiver_id], token)
    data.sender = _enrich_user(profiles, ecard.sender_id)
    data.receiver = _enrich_user(profiles, ecard.receiver_id)
    return success(data=data.model_dump(), message=SUCCESS_RECOGNITION_FOUND)
