"""
User management API endpoints.

User identity and profiles are served by the centralized User Service.

- /me is served from Cache 1 (auth cache)
- GET / is served from User Service via Cache 2 Pattern C
- POST / and PUT /{id} are disabled (managed by User Service)
"""
from fastapi import APIRouter, Depends, status

from app.core.config import settings
from app.core.dependencies import get_current_user, oauth2_scheme
from app.schemas.users import CacheFlushRequest
from app.utils.response import success, client_error, created, forbidden, paginated_success
from app.utils.enums import UserRole
from app.services import users_service
from app.utils.constants import (
    DEFAULT_PAGE_SIZE, ERROR_UNAUTHORIZED_USER_UPDATE, SUCCESS_USER_FETCHED,
    SUCCESS_USERS_LIST_FETCHED, ERROR_ONLY_HR_ADMIN_CREATE_USER, SUCCESS_USER_CREATED,
    SUCCESS_USER_UPDATED
)

router = APIRouter()


@router.get("/me")
async def get_current_user_route(
    current_user=Depends(get_current_user),
):
    """Get current authenticated user details (Pattern D — always from auth cache)."""
    return success(data=users_service.serialize_user_context(current_user), message=SUCCESS_USER_FETCHED)


@router.get("/")
async def list_users(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    current_user=Depends(get_current_user),
    token: str = Depends(oauth2_scheme),
):
    """
    List users.

    Pattern C — paginated list fetched from User Service (5 min cache).
    """
    from app.services.user_profiles_client import get_users_list
    skip = (page - 1) * per_page
    result = get_users_list(token=token, skip=skip, limit=per_page)
    items = [users_service.serialize_user_profile(p) for p in result["items"]]
    return paginated_success(
        items=items,
        total=result["total"],
        page=page,
        per_page=per_page,
        message=SUCCESS_USERS_LIST_FETCHED,
    )


@router.post("/", status_code=status.HTTP_400_BAD_REQUEST)
async def create_user():
    """Disabled — user management is owned by the central User Service."""
    return client_error(
        message="User creation is managed by the central User Service.",
        status_code=400,
    )


@router.put("/{user_id}")
async def update_user(user_id: int):
    """Disabled — user management is owned by the central User Service."""
    return client_error(
        message="User updates are managed by the central User Service.",
        status_code=400,
    )


@router.get("/debug/cache")
async def debug_cache(
    current_user=Depends(get_current_user),
):
    """Shows live cache stats — HR/Admin only."""
    if getattr(current_user, "role", None) not in (UserRole.HR.value, UserRole.ADMIN.value):
        return forbidden(message="Only HR and Admin can view cache debug info.")
    from app.services.user_service_client import _user_cache
    from app.services.user_profiles_client import _profile_cache, _picker_cache

    return {
        "cache1_tokens": {
            "size": len(_user_cache),
            "users": [
                {"user_id": v.id, "name": v.name, "email": v.email, "ttl_remaining_s": int(_user_cache.timer() - _user_cache._TTLCache__links[k].expires + _user_cache.ttl) if hasattr(_user_cache, '_TTLCache__links') else "n/a"}
                for k, v in list(_user_cache.items())
            ],
        },
        "cache2_profiles": {
            "size": len(_profile_cache),
            "user_ids": list(_profile_cache.keys()),
        },
        "cache2_pickers": {
            "size": len(_picker_cache),
            "keys": list(_picker_cache.keys()),
        },
    }


@router.post("/cache/flush")
async def flush_cache(
    payload: CacheFlushRequest,
    current_user=Depends(get_current_user),
):
    """
    Manually clear User Service caches (Admin/HR only).
    Useful when external data is updated and needs to be reflected instantly.
    """
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
       return forbidden(message="Only HR and Admin can flush the cache.")

    from app.services.user_service_client import invalidate_auth_cache
    from app.services.user_profiles_client import invalidate_all_profiles

    scope = payload.scope.lower()
    flushed = []

    if scope in ("all", "auth"):
        invalidate_auth_cache()
        flushed.append("authentication tokens (Cache 1)")

    if scope in ("all", "profiles"):
        invalidate_all_profiles()
        flushed.append("user profiles and pickers (Cache 2)")

    if not flushed:
        return client_error(message=f"Invalid flush scope: {payload.scope}. Use 'all', 'profiles', or 'auth'.")

    return success(
        data={"flushed": flushed},
        message=f"Successfully flushed: {', '.join(flushed)}"
    )

