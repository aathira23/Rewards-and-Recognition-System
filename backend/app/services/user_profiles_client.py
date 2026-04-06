"""
User Profiles client — Cache 2 (user_id → UserProfile).

Implements the three retrieval patterns from the design document:

  Pattern A — Single user lookup         get_user_profile(user_id, token)
  Pattern B — Batch lookup               get_users_batch(user_ids, token)
  Pattern C — Paginated list (pickers)   get_users_list(token, skip, limit)

Uses a sync httpx.Client so it can be called from synchronous service/router
code without needing async/await everywhere.

Cache TTLs per design document:
  - Individual profile (Cache 2)  : 1 hour
  - Picker / list response        : 5 minutes
"""
import logging
from typing import Optional, List, Dict

import httpx
from cachetools import TTLCache

from app.core.config import settings
from app.schemas.user_context import UserProfile

logger = logging.getLogger(__name__)

# ── Cache 2: user_id → UserProfile (1 h TTL) ──────────────────────────────
_profile_cache: TTLCache = TTLCache(maxsize=20_000, ttl=60 * 60)

# ── Response-level cache for Pattern C / picker queries (5 min TTL) ───────
_picker_cache: TTLCache = TTLCache(maxsize=1_000, ttl=5 * 60)


# ── Helpers ────────────────────────────────────────────────────────────────

def _make_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token.strip()}"}


def _safe_int(value) -> Optional[int]:
    if value is None:
        return None
    try:
        return int(value)
    except (ValueError, TypeError):
        return None


def _parse_profile(raw: dict) -> Optional[UserProfile]:
    """Map a raw dict from User Service response → UserProfile."""
    if not raw or not raw.get("id"):
        return None
    return UserProfile(
        id=int(raw["id"]),
        first_name=raw.get("first_name"),
        last_name=raw.get("last_name"),
        email=raw.get("email"),
        role=raw.get("role") or raw.get("role_name") or "EMPLOYEE",
        org_id=_safe_int(raw.get("comp_id")),
        department_id=_safe_int(raw.get("bu_id")),
        department_name=raw.get("bu_name"),
        emp_id=raw.get("emp_id"),
        designation=raw.get("desig_name"),
        img_path=raw.get("img_path"),
        dob=raw.get("dob"),
        date_of_joining=raw.get("date_of_joining"),
        is_active=raw.get("is_active"),
        manager_id=_safe_int(raw.get("manager_id") or raw.get("reporting_to_id")),
    )


# ── Pattern A — Single user lookup ────────────────────────────────────────

def get_user_profile(user_id: int, token: str) -> Optional[UserProfile]:
    """
    Pattern A: resolve a single user_id to a UserProfile.

    Flow:
      1. Check _profile_cache — return instantly on HIT.
      2. On MISS — GET /users?id={user_id} from User Service.
      3. Parse, cache (1h TTL), return.
    """
    if user_id in _profile_cache:
        logger.info("Cache 2 HIT  (Pattern A) — user_id=%s, cache_size=%d", user_id, len(_profile_cache))
        return _profile_cache[user_id]

    logger.info("Cache 2 MISS (Pattern A) — user_id=%s, fetching from User Service", user_id)
    try:
        with httpx.Client(timeout=10.0, verify=settings.USER_SERVICE_VERIFY_SSL) as client:
            resp = client.get(
                settings.GET_USERS_URL,
                params={"id": user_id},
                headers=_make_headers(token),
            )
            resp.raise_for_status()

        data = resp.json()
        raw = data.get("response_data") or {}
        profile = _parse_profile(raw)

        if profile:
            _profile_cache[user_id] = profile
            logger.info("Cache 2 STORE (Pattern A) — user_id=%s name=%r role=%r, cache_size=%d",
                        user_id, profile.name, profile.role, len(_profile_cache))

        return profile

    except Exception as exc:
        logger.warning("Pattern A failed for user_id=%s: %s", user_id, exc)
        return None


# ── Pattern B — Batch lookup ───────────────────────────────────────────────

def get_users_batch(user_ids: List[int], token: str) -> Dict[int, UserProfile]:
    """
    Pattern B: resolve a list of user_ids to a {user_id: UserProfile} dict.

    Flow:
      1. Split user_ids into cache HITs and MISSes.
      2. HIT profiles returned immediately from _profile_cache.
      3. MISS ids → single POST /users/batch call to User Service.
      4. Store each fetched profile in _profile_cache.
      5. Merge and return combined dict.
    """
    result: Dict[int, UserProfile] = {}
    miss_ids: List[int] = []

    for uid in user_ids:
        if uid in _profile_cache:
            result[uid] = _profile_cache[uid]
        else:
            miss_ids.append(uid)

    logger.info("Cache 2 (Pattern B) — %d HITs, %d MISSes (ids=%s), cache_size=%d",
                len(result), len(miss_ids), miss_ids, len(_profile_cache))

    if not miss_ids:
        return result

    try:
        with httpx.Client(timeout=10.0, verify=settings.USER_SERVICE_VERIFY_SSL) as client:
            resp = client.post(
                settings.GET_USER_BATCH_URL,
                json={"user_ids": miss_ids},
                headers=_make_headers(token),
            )
            resp.raise_for_status()

        data = resp.json()
        raw_list = data.get("response_data") or []

        stored = 0
        for item in raw_list:
            profile = _parse_profile(item)
            if profile:
                _profile_cache[profile.id] = profile
                result[profile.id] = profile
                stored += 1
        logger.info("Cache 2 STORE (Pattern B) — stored %d profiles, cache_size=%d", stored, len(_profile_cache))

    except Exception as exc:
        logger.warning("Pattern B batch fetch failed for ids=%s: %s", miss_ids, exc)

    return result


# ── Pattern C — Paginated list (pickers) ──────────────────────────────────

def get_users_list(token: str, skip: int = 0, limit: int = 10) -> Dict:
    """
    Pattern C: fetch a paginated user list from the User Service.

    Used by recipient/nominee/manager pickers in the UI.

    Flow:
      1. Check _picker_cache for this (skip, limit) key — return on HIT (5 min TTL).
      2. On MISS — GET /users?skip={skip}&limit={limit} with auth header.
         (User Service uses the auth token to filter by org/company automatically.)
      3. Parse profiles, populate _profile_cache as a side-effect.
      4. Cache the list response in _picker_cache.
      5. Return {"items": [UserProfile, ...], "total": int, "skip": int, "limit": int}.
    """
    cache_key = f"list:{skip}:{limit}"
    if cache_key in _picker_cache:
        cached = _picker_cache[cache_key]
        logger.info("Cache 2 HIT  (Pattern C) — key=%r, total=%d users, picker_cache_size=%d",
                    cache_key, cached.get('total', 0), len(_picker_cache))
        return cached

    logger.info("Cache 2 MISS (Pattern C) — key=%r, fetching from User Service (skip=%d, limit=%d)",
                cache_key, skip, limit)
    try:
        with httpx.Client(timeout=10.0, verify=settings.USER_SERVICE_VERIFY_SSL) as client:
            resp = client.get(
                settings.GET_USERS_URL,
                params={"skip": skip, "limit": limit},
                headers=_make_headers(token),
            )
            resp.raise_for_status()

        data = resp.json()
        raw_list = data.get("response_data") or []

        items: List[UserProfile] = []
        for item in raw_list:
            profile = _parse_profile(item)
            if profile:
                _profile_cache[profile.id] = profile  # populate Cache 2 as side-effect
                items.append(profile)

        # Log a sample of roles to verify the fix
        role_sample = [(p.name, p.role) for p in items[:5]]
        logger.info("Cache 2 STORE (Pattern C) — stored %d users, profile_cache_size=%d, role_sample=%s",
                    len(items), len(_profile_cache), role_sample)

        result = {"items": items, "total": len(items), "skip": skip, "limit": limit}
        _picker_cache[cache_key] = result
        return result

    except Exception as exc:
        logger.warning("Pattern C list fetch failed (skip=%s, limit=%s): %s", skip, limit, exc)
        return {"items": [], "total": 0, "skip": skip, "limit": limit}


# ── Cache management ───────────────────────────────────────────────────────

def invalidate_user(user_id: int) -> None:
    """Remove a single user from Cache 2 (e.g. after a profile update)."""
    _profile_cache.pop(user_id, None)


def invalidate_all_profiles() -> None:
    """Clear all user profiles and picker responses from memory."""
    _profile_cache.clear()
    _picker_cache.clear()
    logger.info("Cache 2 cleared (profiles and pickers)")


# ── Convenience helpers (used by services that no longer query the Users table) ──

def get_all_cached_profiles() -> Dict[int, UserProfile]:
    """Return a snapshot of all currently cached user profiles.

    Used by the celebrations job and analytics — avoids a DB table scan.
    Callers should first warm the cache via ``get_users_list(token, 0, 10000)``
    to ensure completeness.
    """
    return dict(_profile_cache)


def get_users_by_role(token: str, roles: List[str]) -> List[UserProfile]:
    """Return profiles matching one of *roles* (case-insensitive).

    Fetches all users (up to 10 000) and filters in memory.
    """
    all_data = get_users_list(token, skip=0, limit=10_000)
    return [
        p for p in all_data.get("items", [])
        if p.role and p.role.upper() in {r.upper() for r in roles}
    ]


def get_dept_head(token: str, department_id: int) -> Optional[UserProfile]:
    """Return the DEPT_HEAD profile for *department_id*, or None."""
    matches = get_users_by_role(token, ["DEPT_HEAD"])
    for p in matches:
        if p.department_id == department_id:
            return p
    return None
