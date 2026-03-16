from typing import Optional, Dict, Any

from sqlalchemy.orm import Session

from app.models.users import User
from app.schemas.users import UserCreate, UserUpdate
from app.repository.users_repository import UsersRepository


# ─── Repository-backed module functions (backward-compatible) ────────

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return UsersRepository(db).get_by_email(email)


def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    return UsersRepository(db).get_by_id(user_id)


def list_users(db: Session, page: int = 1, per_page: int = 20):
    """Return (total, users) for the requested page."""
    from app.utils.constants import clamp_pagination
    page, per_page, skip = clamp_pagination(page, per_page)
    return UsersRepository(db).list_paginated(skip, per_page)


def get_user_count(db: Session) -> int:
    return UsersRepository(db).count()


def create_user(db: Session, user_in: UserCreate) -> User:
    repo = UsersRepository(db)
    existing = repo.get_by_email(user_in.email)
    if existing:
        raise ValueError("User with this email already exists")
    return repo.create(user_in)


def update_user(db: Session, user_id: int, user_in: UserUpdate) -> User:
    repo = UsersRepository(db)
    user = repo.get_by_id(user_id)
    if not user:
        raise ValueError("User not found")
    return repo.update(user, user_in)


def serialize_user(user: User, include_sensitive: bool = True) -> Dict[str, Any]:
    """
    Serialize user object to dict.
    
    Args:
        user: User model instance
        include_sensitive: If False, excludes PII (email, birth_date). Use False for public contexts.
    """
    data = {
        "id": user.id,
        "name": user.name,
        "role": user.role,
        "department_id": user.department_id,
        "department_name": user.department.name if user.department else None,
        "manager_id": user.manager_id,
        "manager_name": user.manager.name if user.manager else None,
        "date_of_joining": user.date_of_joining.isoformat() if user.date_of_joining else None,
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }

    # Include sensitive fields only when appropriate
    if include_sensitive:
        data["email"] = user.email
        data["birth_date"] = user.birth_date.isoformat() if user.birth_date else None

    return data


def serialize_user_context(ctx) -> Dict[str, Any]:
    """
    Serialize a UserContext (user_service mode) to the same response shape as serialize_user.
    Used by GET /users/me when AUTH_MODE == 'user_service'.
    """
    return {
        "id": ctx.id,
        "name": ctx.name,
        "role": ctx.role,
        "email": getattr(ctx, "email", None),
        "department_id": getattr(ctx, "department_id", None),
        "department_name": getattr(ctx, "department_name", None),
        "manager_id": None,
        "manager_name": None,
        "emp_id": getattr(ctx, "emp_id", None),
        "designation": getattr(ctx, "designation", None),
        "img_path": getattr(ctx, "img_path", None),
        "org_id": getattr(ctx, "org_id", None),
        "dob": getattr(ctx, "dob", None),
        "date_of_joining": None,
        "created_at": None,
    }


def serialize_user_profile(profile) -> Dict[str, Any]:
    """
    Serialize a UserProfile (Cache 2) to user list item format.
    Used by GET /users/ when AUTH_MODE == 'user_service'.
    """
    return {
        "id": profile.id,
        "name": profile.name,
        "role": getattr(profile, "role", None),
        "email": getattr(profile, "email", None),
        "department_id": getattr(profile, "department_id", None),
        "department_name": getattr(profile, "department_name", None),
        "manager_id": None,
        "manager_name": None,
        "emp_id": getattr(profile, "emp_id", None),
        "designation": getattr(profile, "designation", None),
        "img_path": getattr(profile, "img_path", None),
        "org_id": getattr(profile, "org_id", None),
        "dob": getattr(profile, "dob", None),
        "date_of_joining": getattr(profile, "date_of_joining", None),
        "is_active": getattr(profile, "is_active", None),
    }
