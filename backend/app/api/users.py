"""
User management API endpoints.
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_optional_current_user
from app.schemas.users import UserCreate, UserUpdate
from app.utils.response import success, client_error, created, forbidden, paginated_success
from app.utils.enums import UserRole
from app.services import users_service
from app.services.users_service import get_user_count
from app.utils.constants import (
    DEFAULT_PAGE_SIZE, ERROR_UNAUTHORIZED_USER_UPDATE, SUCCESS_USER_FETCHED,
    SUCCESS_USERS_LIST_FETCHED, ERROR_ONLY_HR_ADMIN_CREATE_USER, SUCCESS_USER_CREATED,
    SUCCESS_USER_UPDATED
)

router = APIRouter()


@router.get("/me")
def get_current_user_route(
    current_user = Depends(get_current_user)
):
    """Get current authenticated user details."""
    return success(data=users_service.serialize_user(current_user), message=SUCCESS_USER_FETCHED)


@router.get("/")
def list_users(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """List all users. HR users see full details; others see public profiles."""
    is_hr = getattr(current_user, "role", None) in (UserRole.HR.value, UserRole.ADMIN.value)

    total, users = users_service.list_users(db, page=page, per_page=per_page)
    return paginated_success(
        items=[users_service.serialize_user(u, include_sensitive=is_hr) for u in users],
        total=total,
        page=page,
        per_page=per_page,
        message=SUCCESS_USERS_LIST_FETCHED,
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
def create_user(
    user: UserCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_optional_current_user)
):
    """Create a new user. If users already exist, only HR can create additional users.

    On a fresh system (no users), this endpoint allows creating the first user without authentication.
    """
    # If there are existing users, only HR may create new users
    total = get_user_count(db)
    if total > 0:
        if current_user is None or getattr(current_user, "role", None) not in (UserRole.HR.value, UserRole.ADMIN.value):
            return forbidden(ERROR_ONLY_HR_ADMIN_CREATE_USER)

    try:
        created_user = users_service.create_user(db, user)
    except ValueError as e:
        return client_error(message=str(e), status_code=409)

    return created(data=users_service.serialize_user(created_user), message=SUCCESS_USER_CREATED)


@router.put("/{user_id}")
def update_user(
    user_id: int,
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update user profile (self or HR)."""
    # Only HR or the user themself may update the profile
    if not (getattr(current_user, "role", None) in (UserRole.HR.value, UserRole.ADMIN.value) or getattr(current_user, "id", None) == user_id):
        return forbidden(ERROR_UNAUTHORIZED_USER_UPDATE)

    try:
        user = users_service.update_user(db, user_id, payload)
    except ValueError as e:
        return client_error(message=str(e), status_code=404)

    return success(data=users_service.serialize_user(user), message=SUCCESS_USER_UPDATED)
