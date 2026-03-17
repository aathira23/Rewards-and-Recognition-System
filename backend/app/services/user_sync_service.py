"""
Centralized service for synchronizing user and department data from external sources.
"""
from typing import Union, Optional
from sqlalchemy.orm import Session
from datetime import date as _date

from app.models.users import User
from app.models.departments import Department
from app.schemas.user_context import UserContext, UserProfile
from app.core.security import get_password_hash
import secrets
import logging

logger = logging.getLogger(__name__)

# Valid roles in the system
VALID_ROLES = {"EMPLOYEE", "MANAGER", "DEPT_HEAD", "HR", "ADMIN"}

def get_mapped_role(role: Optional[str]) -> str:
    """Map external roles to internal system roles."""
    if not role:
        return "UNKNOWN"
    
    role_upper = role.upper()
    if role_upper in VALID_ROLES:
        return role_upper
    
    # Optional logic for partial matches can go here
    return "UNKNOWN"

def sync_user_data(db: Session, data: Union[UserContext, UserProfile]) -> User:
    """
    Synchronize user and department data into the local database.
    
    Does not commit the transaction (uses flush) to allow callers 
    to manage atomicity.
    """
    # 1. Sync Department
    if data.department_id and data.department_name:
        dept = db.query(Department).filter(Department.id == data.department_id).first()
        if not dept:
            db.add(Department(id=data.department_id, name=data.department_name))
            db.flush()
        elif dept.name != data.department_name:
            dept.name = data.department_name
            db.flush()

    # 2. Parse Birth Date
    birth: Optional[_date] = None
    dob_str = getattr(data, "dob", None)
    if dob_str:
        try:
            birth = _date.fromisoformat(str(dob_str)[:10])
        except (ValueError, TypeError):
            pass

    # 3. Sync User
    user = db.query(User).filter(User.id == data.id).first()
    role = get_mapped_role(data.role)

    if not user:
        user = User(
            id=data.id,
            name=data.name,
            email=data.email or f"user_{data.id}@ext.local",
            password=get_password_hash(secrets.token_hex(32)),
            role=role,
            department_id=data.department_id,
            birth_date=birth,
        )
        db.add(user)
    else:
        # Update mutable fields
        user.name = data.name
        user.role = role
        user.department_id = data.department_id
        if birth is not None:
            user.birth_date = birth
        if data.email:
            user.email = data.email

    db.flush()
    return user
