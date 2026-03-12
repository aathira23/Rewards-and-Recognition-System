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
