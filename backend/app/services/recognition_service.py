from __future__ import annotations

from sqlalchemy.orm import Session
from typing import Optional, List, Any, Dict
from datetime import datetime, timezone, timedelta

from app.services.points_service import PointsService
from app.services.notification_service import NotificationService
from app.utils.enums import ReferenceType
from app.core.config import settings
from app.repository.recognition_repository import RecognitionRepository


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
        """Get all badges."""
        return self.repository.get_badges(active_only)

    def get_badge_by_id(self, badge_id: int):
        """Get a badge by ID."""
        return self.repository.get_badge_by_id(badge_id)

    def create_badge(self, name: str, description: str = None, icon_url: str = None):
        """Create a new badge."""
        existing = self.repository.get_badge_by_name(name)
        if existing:
            raise ValueError("Badge with this name already exists")
        return self.repository.create_badge(name, description, icon_url)

    def update_badge(self, badge_id: int, data: Dict[str, Any]):
        """Update an existing badge."""
        badge = self.repository.get_badge_by_id(badge_id)
        if not badge:
            raise ValueError("Badge not found")
        for key, value in data.items():
            if value is not None:
                setattr(badge, key, value)
        return self.repository.save_badge(badge)

    # --- eCard / Recognition Logic ---
    def _get_ecard_policy(self):
        """Return the generic (event_key IS NULL) ECARD policy row, or None."""
        return self.repository.get_ecard_policy()

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

    def send_ecard(
        self,
        sender_id: int,
        receiver_id: int,
        badge_id: int,
        message: Optional[str] = None,
        token: Optional[str] = None
    ) -> ECard:
        """Send an eCard recognition."""
        if sender_id == receiver_id:
            raise ValueError("You cannot send a recognition to yourself.")

        # 0. Lazy sync recipient if missing (for User Service mode)
        from app.core.config import settings
        if settings.AUTH_MODE == "user_service" and token:
            self._sync_recipient(receiver_id, token)

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

        # 5. Create eCard record
        ecard = self.repository.create_ecard(
            sender_id=sender_id,
            receiver_id=receiver_id,
            badge_id=badge_id,
            points=points,
            message=message,
        )

        # 6. Award points to receiver
        self.points_service.award_points(
            user_id=receiver_id,
            points=points,
            source_type=ReferenceType.ECARD.value,
            source_id=ecard.id
        )

        # 5. Create recognition feed entry
        self.create_feed_entry(
            actor_id=sender_id,
            receiver_id=receiver_id,
            source_type="ECARD",
            source_id=ecard.id,
            message=message or f"Recognized with {badge.name}"
        )

        # 6. Create notification for receiver
        sender_name = "A colleague"
        if self._token:
            from app.services.user_profiles_client import get_user_profile
            sender_profile = get_user_profile(sender_id, self._token)
            if sender_profile:
                sender_name = sender_profile.name
        if sender_name == "A colleague":
            sender = self.repository.get_user_by_id(sender_id)
            if sender:
                sender_name = sender.name
        self.notification_service.create_notification(
            user_id=receiver_id,
            message=f"{sender_name} appreciated you with a '{badge.name}' badge! {points} points earned.",
            source_type=ReferenceType.ECARD.value,
            source_id=ecard.id,
            email_context={
                "sender_name": sender_name,
                "badge_name": badge.name,
                "recognition_message": message or "",
                "points": points,
                "view_url": "",
            },
        )

        return ecard

    def _sync_recipient(self, user_id: int, token: str) -> None:
        """Fetch user from User Service and upsert locally if missing."""
        from app.models.users import User
        user = self.db.query(User).filter(User.id == user_id).first()
        if user:
            return

        from app.services import user_profiles_client
        from app.services.user_sync_service import sync_user_data
        try:
            profile = user_profiles_client.get_user_profile(user_id, token)
            if profile:
                sync_user_data(self.db, profile)
        except Exception:
            self.db.rollback()
            import logging
            logging.getLogger(__name__).warning("Failed to sync recipient %s", user_id, exc_info=True)

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
        message: str
    ):
        """Create a new entry in the recognition feed."""
        return self.repository.create_feed_entry(
            actor_id=actor_id,
            receiver_id=receiver_id,
            source_type=source_type,
            source_id=source_id,
            message=message,
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
        admin = self.repository.get_admin_user()
        system_actor_id = admin.id if admin else 1

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
        """Calculate leaderboard ranking."""
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

        leaderboard = []
        for rank, (user, score, secondary) in enumerate(results, start=1):
            leaderboard.append({
                "user_id": user.id,
                "name": user.name,
                "department_name": user.department.name if user.department else None,
                "rank": rank,
                "score": int(score or 0),
                "recognitions_received": int(secondary or 0) if metric == "POINTS" else int(score or 0)
            })

        return leaderboard
