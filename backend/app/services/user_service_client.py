"""
User Service client — handles token validation via the centralized User Service.

Uses a TTL cache (24h) keyed by Bearer token so that the User Service is called
at most once per user per day. Follows the same pattern as the Training Service's
auth_service.py.
"""
import logging
from typing import Optional

import httpx
from cachetools import TTLCache
from fastapi import HTTPException
from starlette.status import HTTP_401_UNAUTHORIZED, HTTP_503_SERVICE_UNAVAILABLE

from app.core.config import settings
from app.schemas.user_context import UserContext

logger = logging.getLogger(__name__)

# Cache 1: token string → UserContext  (3h TTL per design doc, max 20 000 active users)
_CACHE_MAX_ITEMS = 20_000
_CACHE_TTL = 60 * 60 * 3  # 3 hours
_user_cache: TTLCache = TTLCache(maxsize=_CACHE_MAX_ITEMS, ttl=_CACHE_TTL)

# Shared async HTTP client (reused across requests)
_http_client: Optional[httpx.AsyncClient] = None


def _get_http_client() -> httpx.AsyncClient:
    global _http_client
    if _http_client is None or _http_client.is_closed:
        _http_client = httpx.AsyncClient(timeout=30.0, verify=False)
    return _http_client


async def get_user_context(token: str) -> UserContext:
    """
    Validate token and return UserContext.

    1. Check TTL cache — return immediately on HIT.
    2. On MISS — call User Service POST /auth/token/get_user_details.
    3. Map response fields → UserContext, cache it, return.
    """
    # 1. Cache check
    if token in _user_cache:
        logger.info("Cache 1 HIT  — user_id=%s (no User Service call)", _user_cache[token].id)
        return _user_cache[token]

    logger.info("Cache 1 MISS — calling User Service: %s", settings.GET_USER_DETAILS_URL)
    # 2. Call User Service
    clean_token = token.strip()
    headers = {
        "Authorization": f"Bearer {clean_token}",
        "Content-Type": "application/json",
    }
    payload = {"token": clean_token}

    try:
        client = _get_http_client()
        response = await client.post(
            settings.GET_USER_DETAILS_URL,
            headers=headers,
            json=payload,
        )
        response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        status_code = exc.response.status_code
        logger.error("User Service returned %s: %s", status_code, exc.response.text)
        if status_code == 401:
            raise HTTPException(status_code=HTTP_401_UNAUTHORIZED, detail="Session expired or invalid")
        raise HTTPException(status_code=status_code, detail="Error from User Service")
    except httpx.RequestError as exc:
        logger.error("Connection error to User Service: %s, URL: %s", exc, settings.GET_USER_DETAILS_URL)
        raise HTTPException(status_code=HTTP_503_SERVICE_UNAVAILABLE, detail="User Service unavailable")

    # 3. Parse response
    data = response.json()
    details = data.get("response_data") or data.get("responseData") or {}

    if not details.get("id"):
        raise HTTPException(status_code=HTTP_401_UNAUTHORIZED, detail="Invalid user details from User Service")

    user_ctx = UserContext(
        id=int(details["id"]),
        role=details.get("role") or details.get("role_name") or "EMPLOYEE",
        org_id=_safe_int(details.get("comp_id")),
        department_id=_safe_int(details.get("bu_id")),
        department_name=details.get("bu_name"),
        first_name=details.get("first_name"),
        last_name=details.get("last_name"),
        email=details.get("email"),
        emp_id=details.get("emp_id"),
        designation=details.get("desig_name"),
        img_path=details.get("img_path"),
        dob=details.get("dob"),
    )

    # Cache it
    _user_cache[clean_token] = user_ctx
    logger.info("Cache 1 stored — user_id=%s, cache_size=%d", user_ctx.id, len(_user_cache))
    return user_ctx


def _safe_int(value) -> Optional[int]:
    """Convert to int if truthy, else None."""
    if value is None:
        return None
    try:
        return int(value)
    except (ValueError, TypeError):
        return None
