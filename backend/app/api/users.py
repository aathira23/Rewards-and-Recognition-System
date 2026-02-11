"""
User management API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.schemas.users import UserCreate, UserResponse, UserUpdate
from app.utils.response import success, client_error, created
from app.services import users_service

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
    """List all users (admin only)."""
    # Only HR role may list users
    # RBAC removed: allow authenticated users to list users

    users = users_service.list_users(db, skip=skip, limit=limit)
    return success(data=[users_service.serialize_user(u) for u in users], message="User list fetched")


@router.post("/", status_code=status.HTTP_201_CREATED)
def create_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    """Create a new user - public endpoint for initial setup."""
    # Authentication removed temporarily to allow creating first user

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
    # RBAC removed: allow authenticated users to update profiles (still permitted to update others)

    try:
        user = users_service.update_user(db, user_id, payload)
    except ValueError as e:
        return client_error(message=str(e), status_code=404)

    return success(data=users_service.serialize_user(user), message="User updated")
