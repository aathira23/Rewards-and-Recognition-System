"""
UserContext schema — represents the authenticated user's identity
as returned by the User Service token validation endpoint.
"""
from typing import Optional
from pydantic import BaseModel


class UserContext(BaseModel):
    """
    Lightweight user identity object returned by get_current_user().

    Provides .id and .role — the two attributes all routers rely on.
    Additional fields are available for features that need them.
    """
    id: int
    role: str
    org_id: Optional[int] = None
    department_id: Optional[int] = None
    department_name: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[str] = None
    emp_id: Optional[str] = None
    designation: Optional[str] = None
    img_path: Optional[str] = None
    dob: Optional[str] = None

    @property
    def name(self) -> str:
        """Full display name — matches the old User model's .name attribute."""
        parts = [self.first_name or "", self.last_name or ""]
        return " ".join(p for p in parts if p).strip() or f"User {self.id}"


class UserProfile(BaseModel):
    """
    User profile fetched from the User Service (Cache 2).

    Populated by Pattern A (single), B (batch), or C (paginated list).
    Keyed by user_id in the profile cache (1h TTL).
    """
    id: int
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[str] = None
    role: Optional[str] = None          # not always returned by GET /users
    org_id: Optional[int] = None
    department_id: Optional[int] = None
    department_name: Optional[str] = None
    emp_id: Optional[str] = None
    designation: Optional[str] = None
    img_path: Optional[str] = None
    dob: Optional[str] = None
    date_of_joining: Optional[str] = None
    is_active: Optional[bool] = None

    @property
    def name(self) -> str:
        parts = [self.first_name or "", self.last_name or ""]
        return " ".join(p for p in parts if p).strip() or f"User {self.id}"
