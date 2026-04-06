"""
Authentication API endpoints.

Authentication is handled by the centralized User Service.
"""
import httpx
from fastapi import APIRouter, Depends, HTTPException, status

from app.core.config import settings
from app.utils.constants import ERROR_INCORRECT_LOGIN
from app.utils.response import build_response, SUCCESS_MESSAGE

from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter()


@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
):
    """Login endpoint.

    Proxies credentials to Styria and returns the Styria Bearer token.
    All subsequent requests must carry that token — it will be validated
    against the User Service on first use (Cache 1 miss) and cached.
    """
    return await _login_via_user_service(form_data.username, form_data.password)


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
