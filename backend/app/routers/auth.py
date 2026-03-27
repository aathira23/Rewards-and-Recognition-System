"""
Authentication API endpoints.

Dual-mode:
  - "local"        → validate via local DB + HS256 JWT (development / legacy)
  - "user_service" → proxy credentials to Styria User Service; return Styria token

Dev helper (user_service mode only):
  POST /auth/token-login  — accepts a raw Styria Bearer token, validates it
  against the User Service, and returns it in the standard login response
  shape so the frontend can store and use it.  Use this when testing manually
  (paste a token you obtained from the Styria staging portal or browser devtools).
"""
from datetime import timedelta
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.utils.constants import ERROR_INCORRECT_LOGIN
from app.utils.response import build_response, SUCCESS_MESSAGE, FAILURE_MESSAGE

from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter()


@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    """Login endpoint.

    user_service mode: proxies credentials to Styria and returns the Styria
    Bearer token. All subsequent requests must carry that token — it will be
    validated against the User Service on first use (Cache 1 miss) and cached
    for 24 hours.

    local mode: validates against local DB and returns a locally-signed JWT
    (legacy / dev only).
    """
    if settings.AUTH_MODE == "user_service":
        return await _login_via_user_service(form_data.username, form_data.password)
    return _login_local(form_data.username, form_data.password, db)


# ── User Service proxy login ──────────────────────────────────────────────────

async def _login_via_user_service(email: str, password: str):
    """Forward credentials to Styria and return its token to the frontend."""
    try:
        async with httpx.AsyncClient(
            timeout=15.0, verify=settings.USER_SERVICE_VERIFY_SSL
        ) as client:
            resp = await client.post(
                settings.STYRIA_LOGIN_URL,
                json={"username": email, "password": password},
            )
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"User Service unreachable: {exc}",
        )

    if resp.status_code == 401 or resp.status_code == 403:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ERROR_INCORRECT_LOGIN,
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not resp.is_success:
        raise HTTPException(
            status_code=resp.status_code,
            detail=f"User Service login failed: {resp.text}",
        )

    data = resp.json()
    # Styria typically wraps its token in response_data or at top level.
    # Accept both shapes.
    payload = data.get("response_data") or data.get("responseData") or data

    access_token = (
        payload.get("access_token")
        or payload.get("token")
        or payload.get("jwt")
    )
    if not access_token:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="User Service did not return a token",
        )

    user_id = payload.get("user_id") or payload.get("id") or 0

    return build_response(
        status.HTTP_200_OK,
        SUCCESS_MESSAGE,
        None,
        {
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": user_id,
        },
    )


# ── Local login (legacy dev mode) ─────────────────────────────────────────────

def _login_local(email: str, password: str, db: Session):
    """Validate against local DB and return a locally-signed JWT."""
    from app.core.security import verify_password, create_access_token
    from app.models.users import User

    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ERROR_INCORRECT_LOGIN,
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_expires = timedelta(hours=24)
    token_data = {"sub": str(user.id), "email": user.email, "role": user.role}
    access_token = create_access_token(data=token_data, expires_delta=access_expires)

    return build_response(
        status.HTTP_200_OK,
        SUCCESS_MESSAGE,
        None,
        {
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": user.id,
        },
    )


# ── Dev token-login (user_service mode only) ─────────────────────────────────

class _TokenLoginRequest(BaseModel):
    token: str


@router.post("/token-login")
async def token_login(body: _TokenLoginRequest):
    """
    Dev-only helper for user_service mode.

    Supply a raw Styria Bearer token (obtained from browser devtools or another
    Styria-connected app).  The endpoint validates it against the User Service
    (Cache 1) and returns the same response shape as /login so the frontend
    stores and uses it normally.

    Only available when AUTH_MODE == "user_service".
    """
    if settings.AUTH_MODE != "user_service":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Endpoint not available in local mode",
        )

    from app.services.user_service_client import get_user_context

    try:
        ctx = await get_user_context(body.token.strip())
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token validation failed: {exc}",
        )

    return build_response(
        status.HTTP_200_OK,
        SUCCESS_MESSAGE,
        None,
        {
            "access_token": body.token.strip(),
            "token_type": "bearer",
            "user_id": ctx.id,
        },
    )
