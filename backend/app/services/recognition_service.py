from __future__ import annotations

import logging
from sqlalchemy.orm import Session
from typing import Optional, List, Any, Dict
from datetime import datetime, timezone, timedelta
from cachetools import TTLCache

from app.services.points_service import PointsService
from app.services.notification_service import NotificationService
from app.utils.enums import ReferenceType
from app.core.config import settings
from app.repository.recognition_repository import RecognitionRepository

logger = logging.getLogger(__name__)

# Module-level caches
_badge_cache: TTLCache = TTLCache(maxsize=100, ttl=60 * 60)       # 1 h
_ecard_policy_cache: TTLCache = TTLCache(maxsize=10, ttl=60 * 60) # 1 h
_leaderboard_cache: TTLCache = TTLCache(maxsize=50, ttl=60 * 60)  # 1 h


class RecognitionService:
    """Service for managing recognitions and leaderboard."""

    def __init__(self, db: Session, token: Optional[str] = None):
        self.db = db
        self._token = token
        self.repository = RecognitionRepository(db)
        self.points_service = PointsService(db)
        self.notification_service = NotificationService(db, token=self._token)

    # --- Badge Management ---
    def get_badges(self, active_only: bool = True):
        """Get all badges (served from 1 h cache)."""
        cache_key = f"badges:{active_only}"
        if cache_key in _badge_cache:
            return _badge_cache[cache_key]
        result = self.repository.get_badges(active_only)
        _badge_cache[cache_key] = result
        return result

    def get_badge_by_id(self, badge_id: int):
        """Get a badge by ID (served from 1 h cache)."""
        cache_key = f"badge:{badge_id}"
        if cache_key in _badge_cache:
            return _badge_cache[cache_key]
        badge = self.repository.get_badge_by_id(badge_id)
        if badge:
            _badge_cache[cache_key] = badge
        return badge

    def create_badge(self, name: str, description: str = None, icon_url: str = None):
        """Create a new badge."""
        existing = self.repository.get_badge_by_name(name)
        if existing:
            raise ValueError("Badge with this name already exists")
        result = self.repository.create_badge(name, description, icon_url)
        _badge_cache.clear()  # invalidate badge caches on create
        return result

    def update_badge(self, badge_id: int, data: Dict[str, Any]):
        """Update an existing badge."""
        badge = self.repository.get_badge_by_id(badge_id)
        if not badge:
            raise ValueError("Badge not found")
        for key, value in data.items():
            if value is not None:
                setattr(badge, key, value)
        result = self.repository.save_badge(badge)
        _badge_cache.clear()  # invalidate badge caches on update
        return result

    # --- eCard / Recognition Logic ---
    def _get_ecard_policy(self):
        """Return the generic ECARD policy row from cache (1 h TTL), or None."""
        cache_key = "ecard_policy"
        if cache_key in _ecard_policy_cache:
            policy = _ecard_policy_cache[cache_key]
            # Ensure the object is bound to the current session to avoid DetachedInstanceError
            if policy:
                return self.db.merge(policy, load=False)
            return None
        policy = self.repository.get_ecard_policy()
        _ecard_policy_cache[cache_key] = policy
        return policy

    def _check_monthly_limit(self, sender_id: int, policy) -> None:
        """Raise ValueError if sender has hit their monthly eCard limit."""
        if not policy or not policy.monthly_limit:
            return
        start_of_month = datetime.now(timezone.utc).replace(
            day=1, hour=0, minute=0, second=0, microsecond=0
        )
        monthly_sent = self.repository.count_ecards_since(sender_id, start_of_month)
        if monthly_sent >= policy.monthly_limit:
            raise ValueError(
                f"You have reached your monthly eCard limit of {policy.monthly_limit}. "
                "Your limit resets at the start of next month."
            )

    def _check_cooldown(self, sender_id: int, policy) -> None:
        """Raise ValueError if sender is still within the cooldown window."""
        if not policy:
            return

        if getattr(policy, 'consecutive_limit', None):
            n = int(policy.consecutive_limit)
            now_utc = datetime.now(timezone.utc)
            window_start = now_utc - timedelta(hours=int(getattr(settings, 'ECARD_CONSECUTIVE_WINDOW_HOURS', 24)))
            window_count = self.repository.count_ecards_since(sender_id, window_start)
            if window_count >= n:
                last_ecard = self.repository.get_last_ecard(sender_id, since=window_start)
                if getattr(policy, 'cooldown_hours', None) is not None:
                    cooldown_hours = int(policy.cooldown_hours)
                else:
                    cooldown_hours = int(getattr(settings, 'ECARD_DEFAULT_COOLDOWN_HOURS', 24))

                cooldown_end = last_ecard.created_at + timedelta(hours=cooldown_hours)
                if now_utc < cooldown_end:
                    hours_left = max(1, int((cooldown_end - now_utc).total_seconds() / 3600) + 1)
                    raise ValueError(
                        f"Please wait {hours_left} more hour(s) before sending another eCard "
                        f"(cooldown: {cooldown_hours} hour(s) after {policy.consecutive_limit} sends in the window)."
                    )
            return

        if getattr(policy, 'cooldown_days', None):
            last_ecard = self.repository.get_last_ecard(sender_id)
            if not last_ecard:
                return
            cooldown_end = last_ecard.created_at + timedelta(days=policy.cooldown_days)
            now_utc = datetime.now(timezone.utc)
            if now_utc < cooldown_end:
                hours_left = max(1, int((cooldown_end - now_utc).total_seconds() / 3600) + 1)
                raise ValueError(
                    f"Please wait {hours_left} more hour(s) before sending another eCard "
                    f"(cooldown: {policy.cooldown_days} day(s) between sends)."
                )

    # ── Persona helpers ─────────────────────────────────────────────

    def _resolve_persona_label(
        self, sender_id: int, persona_type: str, persona_label: Optional[str]
    ) -> Optional[str]:
        """Return the display label for the chosen persona.

        PERSONAL  → None (caller should resolve from user profile as before)
        DEPARTMENT → user's department name (or the explicit label if given)
        """
        if persona_type == "PERSONAL":
            return None

        if persona_type == "DEPARTMENT":
            if persona_label:
                return persona_label
            # Derive from the sender's profile via User Service
            if self._token:
                from app.services.user_profiles_client import get_user_profile
                profile = get_user_profile(sender_id, self._token)
                if profile and profile.department_name:
                    return profile.department_name
            return "Your Department"

        return None

    def send_ecard(
        self,
        sender_id: int,
        receiver_id: int,
        badge_id: int,
        message: Optional[str] = None,
        token: Optional[str] = None,
        persona_type: str = "PERSONAL",
        persona_label: Optional[str] = None,
    ) -> ECard:
        """Send an eCard recognition.

        persona_type: PERSONAL (default) — shown as the sender's name.
                      DEPARTMENT — shown as the sender's department name
                      (fully anonymous; actual sender_id kept only for audit).
        """
        if sender_id == receiver_id:
            raise ValueError("You cannot send a recognition to yourself.")

        # 1. Validate badge
        badge = self.get_badge_by_id(badge_id)
        if not badge or not badge.is_active:
            raise ValueError("Invalid or inactive badge selected.")

        # 2. Get ECARD policy (points, monthly_limit, cooldown_days)
        policy = self._get_ecard_policy()

        # 3. Determine points for this eCard
        #    Priority: badge.points > policy.points > fallback 50
        if badge.points is not None:
            points = badge.points
        elif policy:
            points = policy.points
        else:
            points = 50

        # 4. Enforce monthly limit and cooldown (raises ValueError if blocked)
        self._check_monthly_limit(sender_id, policy)
        self._check_cooldown(sender_id, policy)

        # 5. Resolve persona display label
        resolved_label = self._resolve_persona_label(sender_id, persona_type, persona_label)

        # 6. Create eCard record (sender_id always stored for audit)
        ecard = self.repository.create_ecard(
            sender_id=sender_id,
            receiver_id=receiver_id,
            badge_id=badge_id,
            points=points,
            message=message,
            persona_type=persona_type,
            persona_label=resolved_label,
        )

        # 7. Award points to receiver
        self.points_service.award_points(
            user_id=receiver_id,
            points=points,
            source_type=ReferenceType.ECARD.value,
            source_id=ecard.id
        )

        # 8. Create recognition feed entry (actor_label used for anonymous display)
        self.create_feed_entry(
            actor_id=sender_id,
            receiver_id=receiver_id,
            source_type="ECARD",
            source_id=ecard.id,
            message=message or f"Recognized with {badge.name}",
            actor_label=resolved_label,
        )

        # 9. Build display name for notification / email
        if resolved_label:
            # Department persona → fully anonymous; show department name
            display_name = resolved_label
        else:
            # Personal persona → show sender's real name
            display_name = "A colleague"
            if self._token:
                from app.services.user_profiles_client import get_user_profile
                sender_profile = get_user_profile(sender_id, self._token)
                if sender_profile:
                    display_name = sender_profile.name

        self.notification_service.create_notification(
            user_id=receiver_id,
            message=f"{display_name} appreciated you with a '{badge.name}' badge! {points} points earned.",
            source_type=ReferenceType.ECARD.value,
            source_id=ecard.id,
            email_context={
                "sender_name": display_name,
                "badge_name": badge.name,
                "recognition_message": message or "",
                "points": points,
                "view_url": "",
            },
        )

        return ecard

    def get_recognition_feed(self, page: int = 1, per_page: int = 20):
        """Get company-wide recognition feed. Returns (total, items)."""
        from app.utils.constants import clamp_pagination
        page, per_page, skip = clamp_pagination(page, per_page)
        total, items = self.repository.get_feed_paginated(skip, per_page)

        # Inflate eCard details (specifically badges) for feed items
        for item in items:
            if item.source_type == "ECARD":
                badge = self.repository.get_badge_for_ecard(item.source_id)
                if badge:
                    item.badge = badge

        return total, items

    def get_appreciation_overview(self, user_id: int) -> Dict[str, Any]:
        """Get recognitions received and sent by a user."""
        from app.schemas.ecards import ECardResponse

        received = self.repository.get_ecards_received(user_id)
        sent = self.repository.get_ecards_sent(user_id)

        # Limit context for the sender's UI
        policy = self._get_ecard_policy()
        start_of_month = datetime.now(timezone.utc).replace(
            day=1, hour=0, minute=0, second=0, microsecond=0
        )
        monthly_sent = self.repository.count_ecards_since(user_id, start_of_month)

        next_available_at = None
        # Determine next available send time according to configured policy.
        if policy:
            # If a consecutive_limit is configured, count only eCards within a
            # recent window (hours). When threshold is reached, compute the
            # cooldown using policy values or fallbacks.
            if getattr(policy, 'consecutive_limit', None):
                n = int(policy.consecutive_limit)
                now_utc = datetime.now(timezone.utc)
                window_start = now_utc - timedelta(hours=int(getattr(settings, 'ECARD_CONSECUTIVE_WINDOW_HOURS', 24)))
                window_count = self.repository.count_ecards_since(user_id, window_start)
                if window_count >= n:
                    last = self.repository.get_last_ecard(user_id, since=window_start)
                    if getattr(policy, 'cooldown_hours', None) is not None:
                        cooldown_hours = int(policy.cooldown_hours)
                    else:
                        cooldown_hours = int(getattr(settings, 'ECARD_DEFAULT_COOLDOWN_HOURS', 24))
                    cooldown_end = last.created_at + timedelta(hours=cooldown_hours)
                    if now_utc < cooldown_end:
                        next_available_at = cooldown_end.isoformat()
            # Legacy: only when consecutive_limit is NOT configured.
            elif getattr(policy, 'cooldown_days', None):
                last_ecard = self.repository.get_last_ecard(user_id)
                if last_ecard:
                    cooldown_end = last_ecard.created_at + timedelta(days=policy.cooldown_days)
                    if datetime.now(timezone.utc) < cooldown_end:
                        next_available_at = cooldown_end.isoformat()

        return {
            "received": [ECardResponse.model_validate(r).model_dump() for r in received],
            "sent": [ECardResponse.model_validate(s).model_dump() for s in sent],
            "total_received": len(received),
            "total_sent": len(sent),
            "monthly_sent": monthly_sent,
            "monthly_limit": policy.monthly_limit if policy else None,
            "consecutive_limit": getattr(policy, 'consecutive_limit', None) if policy else None,
            "cooldown_hours": getattr(policy, 'cooldown_hours', None) if policy else None,
            "next_available_at": next_available_at,
        }

    def create_feed_entry(
        self,
        actor_id: int,
        receiver_id: Optional[int],
        source_type: str,
        source_id: int,
        message: str,
        actor_label: Optional[str] = None,
    ):
        """Create a new entry in the recognition feed."""
        return self.repository.create_feed_entry(
            actor_id=actor_id,
            receiver_id=receiver_id,
            source_type=source_type,
            source_id=source_id,
            message=message,
            actor_label=actor_label,
        )

    # --- Automated Logic ---
    def create_automated_recognition(
        self,
        user_id: int,
        celebration_type: str, # BIRTHDAY or ANNIVERSARY
        message: str
    ) -> RecognitionFeed:
        """Logic for automated system recognitions."""
        # 1. Fetch points from policy
        policy = self.repository.get_celebration_policy(celebration_type)
        points = policy.points if policy else 500

        # 2. Award points
        # Find an admin user to act as the "system" sender
        system_actor_id = 1
        if self._token:
            from app.services.user_profiles_client import get_users_by_role
            admins = get_users_by_role(self._token, ["ADMIN"])
            if admins:
                system_actor_id = admins[0].id

        entry = self.create_feed_entry(
            actor_id=system_actor_id,
            receiver_id=user_id,
            source_type="CELEBRATION",
            source_id=0, # System generated
            message=message
        )

        # Award points via points service
        self.points_service.award_points(
            user_id=user_id,
            points=points,
            source_type=ReferenceType.CELEBRATION.value,
            source_id=entry.id
        )
        return entry

    # --- Leaderboard ---
    def get_leaderboard(self, period: str = "MONTHLY", metric: str = "POINTS", limit: int = 10) -> List[Dict[str, Any]]:
        """Calculate leaderboard ranking (served from 1 h cache)."""
        cache_key = f"{period}:{metric}:{limit}"
        if cache_key in _leaderboard_cache:
            logger.debug("Leaderboard cache HIT — key=%s", cache_key)
            return _leaderboard_cache[cache_key]

        # Determine start date. For 'ALL_TIME' do not apply a date filter.
        start_date: Optional[datetime] = datetime.now().replace(
            day=1, hour=0, minute=0, second=0, microsecond=0
        )
        if period == "YEARLY":
            start_date = start_date.replace(month=1)
        elif period == "ALL_TIME":
            start_date = None

        if metric == "POINTS":
            results = self.repository.get_points_leaderboard(start_date, limit)
        else:
            results = self.repository.get_recognition_leaderboard(start_date, limit)

        # Batch-resolve user names/departments via User Service
        user_ids = [r[0] for r in results]
        profiles_map = {}
        if self._token and user_ids:
            from app.services.user_profiles_client import get_users_batch
            profiles_map = get_users_batch(user_ids, self._token)

        leaderboard = []
        for rank, (user_id, score, secondary) in enumerate(results, start=1):
            profile = profiles_map.get(user_id)
            leaderboard.append({
                "user_id": user_id,
                "name": profile.name if profile else f"User {user_id}",
                "department_name": profile.department_name if profile else None,
                "rank": rank,
                "score": int(score or 0),
                "recognitions_received": int(secondary or 0) if metric == "POINTS" else int(score or 0)
            })

        _leaderboard_cache[cache_key] = leaderboard
        logger.debug("Leaderboard cache STORE — key=%s, entries=%d", cache_key, len(leaderboard))
        return leaderboard
