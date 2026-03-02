from typing import Optional, Dict, Any

from sqlalchemy.orm import Session

from app.models.users import User
from app.schemas.users import UserCreate, UserUpdate
from app.core.security import get_password_hash


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()


def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()


def list_users(db: Session, page: int = 1, per_page: int = 20):
    """Return (total, users) for the requested page."""
    from app.utils.constants import clamp_pagination
    page, per_page, skip = clamp_pagination(page, per_page)
    total = db.query(User).count()
    users = db.query(User).offset(skip).limit(per_page).all()
    return total, users


def get_user_count(db: Session) -> int:
    return db.query(User).count()


def create_user(db: Session, user_in: UserCreate) -> User:
    existing = get_user_by_email(db, user_in.email)
    if existing:
        raise ValueError("User with this email already exists")

    hashed = get_password_hash(user_in.password)
    user = User(
        name=user_in.name,
        email=user_in.email,
        password=hashed,
        role=user_in.role,
        department_id=user_in.department_id if user_in.department_id != 0 else None,
        manager_id=user_in.manager_id if user_in.manager_id != 0 else None,
        date_of_joining=user_in.date_of_joining,
        birth_date=user_in.birth_date,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def update_user(db: Session, user_id: int, user_in: UserUpdate) -> User:
    user = get_user_by_id(db, user_id)
    if not user:
        raise ValueError("User not found")

    for field, value in user_in.__dict__.items():
        if field in ["department_id", "manager_id"] and value == 0:
            value = None
        if value is not None:
            setattr(user, field, value)

    db.add(user)
    db.commit()
    db.refresh(user)
    return user


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
