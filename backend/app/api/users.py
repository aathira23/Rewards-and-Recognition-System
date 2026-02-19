"""
User management API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_optional_current_user
from app.schemas.users import UserCreate, UserResponse, UserUpdate
from app.utils.response import success, client_error, created, forbidden
from app.utils.enums import UserRole
from app.services import users_service
from app.services.users_service import get_user_count

router = APIRouter()


@router.get("/me")
def get_current_user_route(
    current_user = Depends(get_current_user)
):
    """Get current authenticated user details."""
    return success(data=users_service.serialize_user(current_user), message="Fetched current user")


@router.get("/")
def list_users(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """List all users. HR users see full details; others see public profiles."""
    is_hr = getattr(current_user, "role", None) == UserRole.HR.value
    
    users = users_service.list_users(db, skip=skip, limit=limit)
    return success(
        data=[users_service.serialize_user(u, include_sensitive=is_hr) for u in users], 
        message="User list fetched"
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
        if current_user is None or getattr(current_user, "role", None) != UserRole.HR.value:
            return forbidden("Only HR users can create new users")

    try:
        created_user = users_service.create_user(db, user)
    except ValueError as e:
        return client_error(message=str(e), status_code=409)

    return created(data=users_service.serialize_user(created_user), message="User created")


@router.put("/{user_id}")
def update_user(
    user_id: int,
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update user profile (self or HR)."""
    # Only HR or the user themself may update the profile
    if not (getattr(current_user, "role", None) == UserRole.HR.value or getattr(current_user, "id", None) == user_id):
        return forbidden("You do not have permission to update this user")

    try:
        user = users_service.update_user(db, user_id, payload)
    except ValueError as e:
        return client_error(message=str(e), status_code=404)

    return success(data=users_service.serialize_user(user), message="User updated")
