"""
Celebrations API endpoints (birthdays, anniversaries).
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id, get_current_user
from app.schemas.celebrations import CelebrationResponse
from app.services.celebration_service import CelebrationService
from app.utils.response import success, paginated_success
from app.utils.constants import DEFAULT_PAGE_SIZE

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


@router.get("/history")
def get_celebration_history(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get past celebrations."""
    service = CelebrationService(db)
    total, hist = service.get_celebration_history(page=page, per_page=per_page)
    # Map to schema with user name
    data = []
    for h in hist:
        d = CelebrationResponse.model_validate(h)
        d.user_name = h.user.name if h.user else "Unknown"
        data.append(d)

    return paginated_success(
        items=data,
        total=total,
        page=page,
        per_page=per_page,
        message="Celebration history fetched",
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
        return client_error(message="Only HR/Admin can trigger celebration processing", status_code=403)

    service = CelebrationService(db)
    result = service.process_today_celebrations()

    return success(
        data=result,
        message=f"Processed {result['birthdays']} birthdays and {result['anniversaries']} anniversaries"
    )
