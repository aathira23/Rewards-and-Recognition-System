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
        role=raw.get("role") or raw.get("role_name"),
        org_id=_safe_int(raw.get("comp_id")),
        department_id=_safe_int(raw.get("bu_id")),
        department_name=raw.get("bu_name"),
        emp_id=raw.get("emp_id"),
        designation=raw.get("desig_name"),
        img_path=raw.get("img_path"),
        dob=raw.get("dob"),
        date_of_joining=raw.get("date_of_joining"),
        is_active=raw.get("is_active"),
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
        return _profile_cache[user_id]

    try:
        with httpx.Client(timeout=10.0, verify=False) as client:
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

    if not miss_ids:
        return result

    try:
        with httpx.Client(timeout=10.0, verify=False) as client:
            resp = client.post(
                settings.GET_USER_BATCH_URL,
                json={"user_ids": miss_ids},
                headers=_make_headers(token),
            )
            resp.raise_for_status()

        data = resp.json()
        raw_list = data.get("response_data") or []

        for item in raw_list:
            profile = _parse_profile(item)
            if profile:
                _profile_cache[profile.id] = profile
                result[profile.id] = profile

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
        return _picker_cache[cache_key]

    try:
        with httpx.Client(timeout=10.0, verify=False) as client:
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
