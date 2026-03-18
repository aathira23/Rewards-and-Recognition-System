"""
User schemas for request/response validation.
"""
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, EmailStr


class UserBase(BaseModel):
    """Base user schema."""
    name: str
    email: EmailStr
    role: str
    department_id: Optional[int] = None
    manager_id: Optional[int] = None
    date_of_joining: Optional[date] = None
    birth_date: Optional[date] = None


class UserCreate(UserBase):
    """Schema for creating a user."""
    password: str


class UserUpdate(BaseModel):
    """Schema for updating a user."""
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    role: Optional[str] = None
    department_id: Optional[int] = None
    manager_id: Optional[int] = None
    date_of_joining: Optional[date] = None
    birth_date: Optional[date] = None


class UserPublicResponse(BaseModel):
    """Public user info (safe for leaderboards, feeds, etc)."""
    id: int
    name: str
    department_name: Optional[str] = None
    role: str

    class Config:
        from_attributes = True


class UserResponse(UserBase):
    """Schema for user response (full details for HR/admin)."""
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class UserDetailResponse(BaseModel):
    """Detailed user info (HR/admin only - includes sensitive data)."""
    id: int
    name: str
    email: str
    role: str
    department_id: Optional[int] = None
    department_name: Optional[str] = None
    manager_id: Optional[int] = None
    manager_name: Optional[str] = None
    date_of_joining: Optional[date] = None
    birth_date: Optional[date] = None
    created_at: datetime

    class Config:
        from_attributes = True


class UserLogin(BaseModel):
    """Schema for user login."""
    email: EmailStr
    password: str


class Token(BaseModel):
    """Schema for authentication token."""
    access_token: str
    token_type: str = "bearer"


class CacheFlushRequest(BaseModel):
    """Schema for manual cache flush request."""
    scope: str = "all"  # "all", "profiles", "auth"
