"""
Dependency injection utilities.

Authentication is handled by the centralized User Service.
User data is resolved from the User Service cache — no local users table.
"""
import logging
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.config import settings
from app.schemas.user_context import UserContext

logger = logging.getLogger(__name__)

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

# Optional token dependency (does not raise when missing)
oauth2_scheme_optional = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/auth/login",
    auto_error=False,
)
# ─── User Service auth helpers ─────────────────────────────────────────────


async def _get_current_user_from_service(token: str):
    """
    Validate token via User Service (Cache 1) → return UserContext.
    """
    from app.services.user_service_client import get_user_context

    return await get_user_context(token)


# ─── Public dependencies (used by all routers) ────────────────────────────

async def get_current_user(
    token: str = Depends(oauth2_scheme),
):
    """
    Get current authenticated user.

    Returns UserContext (from the User Service TTL cache).
    """
    return await _get_current_user_from_service(token)


def get_current_user_id(
    current_user=Depends(get_current_user),
) -> int:
    """
    Return the current user's ID.

    Derives from get_current_user so the full auth chain is always enforced —
    no separate token decoding, no security bypass in either mode.
    """
    return current_user.id


async def get_optional_current_user(
    token: Optional[str] = Depends(oauth2_scheme_optional),
):
    """
    Attempt to return current user; return None if token is missing or invalid.
    Used by endpoints that allow unauthenticated access (e.g. first user creation).
    """
    if not token:
        return None
    try:
        return await get_current_user(token=token)
    except HTTPException:
        return None
