"""
User management API endpoints.

Dual-mode: behaviour depends on AUTH_MODE setting.
  - "local"        → reads/writes the local users table (full CRUD).
  - "user_service" → /me served from Cache 1 (Pattern D),
                     GET / served from User Service via Cache 2 Pattern C,
                     POST / and PUT / are disabled (managed by User Service).
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.dependencies import get_current_user, get_optional_current_user, oauth2_scheme
from app.schemas.users import UserCreate, UserUpdate, CacheFlushRequest
from app.utils.response import success, client_error, created, forbidden, paginated_success
from app.utils.enums import UserRole
from app.services import users_service
from app.services.users_service import get_user_count
from app.utils.constants import (
    DEFAULT_PAGE_SIZE, ERROR_UNAUTHORIZED_USER_UPDATE, SUCCESS_USER_FETCHED,
    SUCCESS_USERS_LIST_FETCHED, ERROR_ONLY_HR_ADMIN_CREATE_USER, SUCCESS_USER_CREATED,
    SUCCESS_USER_UPDATED
)
from fastapi import Depends as _Depends

router = APIRouter()


@router.get("/me")
async def get_current_user_route(
    current_user=Depends(get_current_user),
):
    """Get current authenticated user details (Pattern D — always from auth cache)."""
    if settings.AUTH_MODE == "user_service":
        return success(data=users_service.serialize_user_context(current_user), message=SUCCESS_USER_FETCHED)
    return success(data=users_service.serialize_user(current_user), message=SUCCESS_USER_FETCHED)


@router.get("/")
async def list_users(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
    token: str = Depends(oauth2_scheme),
):
    """
    List users.

    user_service mode: Pattern C — paginated list fetched from User Service (5 min cache).
    local mode:        query local users table.
    """
    if settings.AUTH_MODE == "user_service":
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

    is_hr = getattr(current_user, "role", None) in (UserRole.HR.value, UserRole.ADMIN.value)
    total, users = users_service.list_users(db, page=page, per_page=per_page)
    return paginated_success(
        items=[users_service.serialize_user(u, include_sensitive=is_hr) for u in users],
        total=total,
        page=page,
        per_page=per_page,
        message=SUCCESS_USERS_LIST_FETCHED,
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_user(
    user: UserCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_optional_current_user),
):
    """
    Create a new user.

    user_service mode: disabled — user management is owned by the User Service.
    local mode:        first user can be created without auth; subsequent users require HR.
    """
    if settings.AUTH_MODE == "user_service":
        return client_error(
            message="User creation is managed by the central User Service.",
            status_code=400,
        )

    total = get_user_count(db)
    if total > 0:
        if current_user is None or getattr(current_user, "role", None) not in (UserRole.HR.value, UserRole.ADMIN.value):
            return forbidden(ERROR_ONLY_HR_ADMIN_CREATE_USER)

    try:
        created_user = users_service.create_user(db, user)
    except ValueError as e:
        return client_error(message=str(e), status_code=409)

    return created(data=users_service.serialize_user(created_user), message=SUCCESS_USER_CREATED)


@router.put("/{user_id}")
async def update_user(
    user_id: int,
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Update user profile.

    user_service mode: disabled — user management is owned by the User Service.
    local mode:        self or HR may update.
    """
    if settings.AUTH_MODE == "user_service":
        return client_error(
            message="User updates are managed by the central User Service.",
            status_code=400,
        )

    if not (
        getattr(current_user, "role", None) in (UserRole.HR.value, UserRole.ADMIN.value)
        or getattr(current_user, "id", None) == user_id
    ):
        return forbidden(ERROR_UNAUTHORIZED_USER_UPDATE)

    try:
        user = users_service.update_user(db, user_id, payload)
    except ValueError as e:
        return client_error(message=str(e), status_code=404)

    return success(data=users_service.serialize_user(user), message=SUCCESS_USER_UPDATED)


@router.get("/debug/cache")
async def debug_cache():
    """Temporary debug endpoint — shows live cache contents from inside the running process."""
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

