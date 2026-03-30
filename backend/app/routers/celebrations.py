"""
Celebrations API endpoints (birthdays, anniversaries, manual life events).
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id, get_current_user, oauth2_scheme
from app.services.user_profiles_client import get_users_batch
from app.schemas.celebrations import CelebrationResponse, ManualCelebrationRequest
from app.services.celebration_service import CelebrationService
from app.utils.response import success, paginated_success
from app.utils.constants import (
    DEFAULT_PAGE_SIZE, SUCCESS_CELEBRATIONS_FETCHED,
    SUCCESS_CELEBRATION_HISTORY_FETCHED, ERROR_ONLY_HR_ADMIN_PROCESS_CELEBRATIONS,
    SUCCESS_CELEBRATIONS_PROCESSED, SUCCESS_LIFE_EVENT_TRIGGERED,
    ERROR_ONLY_HR_ADMIN_TRIGGER_LIFE_EVENT, ERROR_LIFE_EVENT_DUPLICATE,
    ERROR_LIFE_EVENT_USER_NOT_FOUND,
)

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
    return success(data=items, message=SUCCESS_CELEBRATIONS_FETCHED)


@router.get("/history")
def get_celebration_history(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
    token: str = Depends(oauth2_scheme)
):
    """Get past celebrations."""
    service = CelebrationService(db)
    total, hist = service.get_celebration_history(page=page, per_page=per_page)
    # Batch-fetch user names from User Service
    _user_ids = [h.user_id for h in hist]
    _users_map = {uid: p.name for uid, p in get_users_batch(_user_ids, token).items()} if _user_ids else {}
    data = []
    for h in hist:
        d = CelebrationResponse.model_validate(h)
        d.user_name = _users_map.get(h.user_id, "Unknown")
        data.append(d)

    return paginated_success(
        items=data,
        total=total,
        page=page,
        per_page=per_page,
        message=SUCCESS_CELEBRATION_HISTORY_FETCHED,
    )


@router.post("/process-today")
def process_today_celebrations(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Process today's birthdays and anniversaries (HR only)."""
    from app.utils.enums import UserRole
    from app.utils.response import client_error

    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ONLY_HR_ADMIN_PROCESS_CELEBRATIONS, status_code=403)

    service = CelebrationService(db)
    result = service.process_today_celebrations()

    return success(
        data=result,
        message=SUCCESS_CELEBRATIONS_PROCESSED.format(result['birthdays'], result['anniversaries'])
    )


@router.post("/trigger")
def trigger_life_event(
    body: ManualCelebrationRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Manually trigger a life-event celebration (BIRTH or MARRIAGE) for an employee.
    Restricted to HR and Admin only.
    """
    from app.utils.enums import UserRole
    from app.utils.response import client_error

    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ONLY_HR_ADMIN_TRIGGER_LIFE_EVENT, status_code=403)

    token = None
    try:
        from app.core.config import settings
        token = settings.SYSTEM_TOKEN if settings.AUTH_MODE == "user_service" else None
    except Exception:
        pass

    service = CelebrationService(db, token=token)
    try:
        result = service.trigger_manual_celebration(
            user_id=body.user_id,
            celebration_type=body.celebration_type,
            hr_actor_id=current_user.id,
        )
    except ValueError as exc:
        msg = str(exc)
        if "not found" in msg:
            return client_error(message=ERROR_LIFE_EVENT_USER_NOT_FOUND, status_code=404)
        if "already awarded" in msg:
            return client_error(message=ERROR_LIFE_EVENT_DUPLICATE, status_code=409)
        return client_error(message=msg, status_code=400)

    return success(
        data=result,
        message=SUCCESS_LIFE_EVENT_TRIGGERED.format(
            result['celebration_type'].title(), result['user_name']
        ),
    )
