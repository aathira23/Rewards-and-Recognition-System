"""
Dependency injection utilities.

Supports two auth modes controlled by AUTH_MODE in config:
  - "local"        → decode local HS256 JWT + DB lookup (existing behaviour)
  - "user_service" → validate token via User Service with TTL cache (production)

In "user_service" mode, every cache-miss authentication upserts the user (and
their department) into the local DB.  This keeps all existing SQLAlchemy ORM
joins (ECard.sender, RecognitionFeed.actor, leaderboard names, etc.) working
without touching any other file in the codebase.
"""
import logging
from datetime import date as _date
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.config import settings

logger = logging.getLogger(__name__)

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")


# ─── Local auth helpers (used when AUTH_MODE == "local") ──────────────────

def _get_current_user_id_local(token: str) -> int:
    """Decode local HS256 JWT and return user_id (sub claim)."""
    from app.core.security import decode_access_token

    payload = decode_access_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id: Optional[int] = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return int(user_id)


def _get_current_user_local(db: Session, token: str):
    """Local auth: decode JWT → lookup user in local DB → return User model."""
    from app.models.users import User

    user_id = _get_current_user_id_local(token)
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user


# ─── User Service auth helpers (used when AUTH_MODE == "user_service") ─────

def _upsert_user_from_context(db: Session, ctx) -> None:
    """
    Keep the local users (and departments) table in sync with User Service.

    Called only on an actual User Service round-trip (cache miss on Cache 1).
    This single upsert is the reason all existing ORM relationships — feed
    actor names, leaderboard enrichment, eCard sender/receiver, report names —
    continue to work without any changes to repositories or services.
    """
    from app.models.users import User
    from app.models.departments import Department
    import secrets
    from app.core.security import get_password_hash

    try:
        # 1. Upsert department (creates it if the org/bu_id is new to R&R)
        if ctx.department_id and ctx.department_name:
            dept = db.query(Department).filter(Department.id == ctx.department_id).first()
            if not dept:
                db.add(Department(id=ctx.department_id, name=ctx.department_name))
                db.flush()
            elif dept.name != ctx.department_name:
                dept.name = ctx.department_name

        # 2. Parse birth date if provided
        birth: Optional[_date] = None
        if getattr(ctx, "dob", None):
            try:
                birth = _date.fromisoformat(str(ctx.dob)[:10])
            except (ValueError, TypeError):
                pass

        # 3. Upsert user
        user = db.query(User).filter(User.id == ctx.id).first()
        if not user:
            db.add(User(
                id=ctx.id,
                name=ctx.name,
                email=ctx.email or f"user_{ctx.id}@ext.local",
                # Unusable password — login goes through User Service only
                password=get_password_hash(secrets.token_hex(32)),
                role=ctx.role,
                department_id=ctx.department_id,
                birth_date=birth,
            ))
        else:
            # Refresh mutable fields that User Service owns
            user.name = ctx.name
            user.role = ctx.role
            user.department_id = ctx.department_id
            if birth is not None:
                user.birth_date = birth

        db.commit()

    except Exception:
        db.rollback()
        logger.warning("Failed to upsert user %s from UserContext", ctx.id, exc_info=True)


async def _get_current_user_from_service(token: str, db_factory):
    """
    Validate token via User Service (Cache 1) → return UserContext.

    On a cache miss (first request for this token), also upserts the user
    and their department into the local DB so ORM joins resolve correctly.
    The DB session is only opened when actually needed (cache miss path).
    """
    from app.services.user_service_client import get_user_context, _user_cache

    was_cached = token in _user_cache          # check BEFORE the cache-or-fetch call
    ctx = await get_user_context(token)        # validates via User Service on miss

    if not was_cached:
        # Only open a DB connection + run the upsert on a real cache miss
        db = next(db_factory())
        try:
            _upsert_user_from_context(db, ctx)
        finally:
            db.close()

    return ctx


# ─── Public dependencies (used by all routers) ────────────────────────────

async def get_current_user(
    token: str = Depends(oauth2_scheme),
):
    """
    Get current authenticated user.

    Returns:
        - AUTH_MODE == "user_service": UserContext (from User Service TTL cache)
        - AUTH_MODE == "local":        User ORM model (from local DB)

    Both expose .id and .role — all existing router code works unchanged.

    The DB session is opened lazily: user_service mode only opens it on a
    cache miss; local mode always needs it for the JWT→DB lookup.
    """
    if settings.AUTH_MODE == "user_service":
        return await _get_current_user_from_service(token, get_db)
    else:
        db = next(get_db())
        try:
            return _get_current_user_local(db, token)
        finally:
            db.close()


async def get_current_user_id(
    current_user=Depends(get_current_user),
) -> int:
    """
    Return the current user's ID.

    Derives from get_current_user so the full auth chain is always enforced —
    no separate token decoding, no security bypass in either mode.
    """
    return current_user.id


async def get_optional_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
):
    """
    Attempt to return current user; return None if token is missing or invalid.
    Used by endpoints that allow unauthenticated access (e.g. first user creation).
    """
    try:
        return await get_current_user(token=token, db=db)
    except HTTPException:
        return None
