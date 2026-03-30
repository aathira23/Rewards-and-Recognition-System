"""
Celebration service - Production-ready unified celebration processing.
"""
from typing import Optional
from sqlalchemy.orm import Session
from datetime import date, timedelta
from typing import List, Dict, Any
from app.services.points_service import PointsService
from app.services.recognition_service import RecognitionService
from app.services.notification_service import NotificationService
from app.utils.enums import ReferenceType
from app.repository.celebration_repository import CelebrationRepository


class CelebrationService:
    """Service for managing automated celebrations (birthdays and work anniversaries)."""

    def __init__(self, db: Session, token: Optional[str] = None):
        self.db = db
        self._token = token
        self.repository = CelebrationRepository(db)
        self.points_service = PointsService(db)
        self.recognition_service = RecognitionService(db, token=token)
        self.notification_service = NotificationService(db, token=token)

    def get_upcoming_celebrations(self, days: int = 7) -> List[Dict[str, Any]]:
        """Get users with birthdays or anniversaries in the next N days."""
        today = date.today()
        upcoming = []

        # Check for next N days
        for i in range(days + 1):
            target_date = today + timedelta(days=i)

            # Birthdays
            birthday_users = self.repository.get_users_by_date_field(
                "birth_date", target_date.month, target_date.day
            )

            for user in birthday_users:
                upcoming.append({
                    "user_id": user.id,
                    "user_name": user.name,
                    "celebration_type": "BIRTHDAY",
                    "date": target_date.strftime("%Y-%m-%d"),
                    "year": target_date.year,
                    "points_awarded": 0  # Placeholder as it hasn't happened yet
                })

            # Anniversaries
            anniversary_users = self.repository.get_users_by_date_field(
                "date_of_joining", target_date.month, target_date.day
            )

            for user in anniversary_users:
                years = target_date.year - user.date_of_joining.year
                if years > 0:
                    upcoming.append({
                        "user_id": user.id,
                        "user_name": user.name,
                        "celebration_type": "ANNIVERSARY",
                        "date": target_date.strftime("%Y-%m-%d"),
                        "year": target_date.year,
                        "years_of_service": years,
                        "points_awarded": 0
                    })

        return upcoming

    def get_celebration_history(self, page: int = 1, per_page: int = 20):
        """Get list of past celebration awards. Returns (total, items)."""
        from app.utils.constants import clamp_pagination
        page, per_page, skip = clamp_pagination(page, per_page)
        return self.repository.get_history_paginated(skip, per_page)

    def _get_points_from_policy(self, event_key: str, default: int) -> int:
        """Get points value from PointsPolicy or return default."""
        points = self.repository.get_policy_points(event_key)
        return points if points is not None else default

    def process_today_celebrations(self) -> Dict[str, int]:
        """
        Process today's birthdays and anniversaries - PRODUCTION UNIFIED METHOD.
        
        This method is used by both:
        - Background job (celebrations_job.py)
        - API endpoint (POST /celebrations/process-today)
        
        Returns:
            Dict with counts of processed birthdays and anniversaries
        """
        today = date.today()
        birthday_count = 0
        anniversary_count = 0

        # Get points from policy (single source of truth)
        birthday_points = self._get_points_from_policy("BIRTHDAY", default=500)
        anniversary_base_points = self._get_points_from_policy("ANNIVERSARY", default=1000)

        # Process Birthdays
        birthday_count = self._process_birthdays(today, birthday_points)

        # Process Anniversaries
        anniversary_count = self._process_anniversaries(today, anniversary_base_points)

        self.db.commit()
        return {
            "birthdays": birthday_count,
            "anniversaries": anniversary_count,
            "date": today.strftime("%Y-%m-%d")
        }

    def _process_birthdays(self, today: date, points: int) -> int:
        """Process birthday celebrations for a specific date."""
        count = 0

        users = self.repository.get_users_by_date_field(
            "birth_date", today.month, today.day
        )

        for user in users:
            # Check if already processed this year
            existing = self.repository.get_celebration(
                user.id, "BIRTHDAY", today.year
            )

            if existing:
                continue

            # Create celebration record
            celebration = self.repository.create_celebration(
                user.id, "BIRTHDAY", today.year, points
            )

            # Award points
            self.points_service.award_points(
                user_id=user.id,
                points=points,
                source_type=ReferenceType.CELEBRATION.value,
                source_id=celebration.id
            )

            # Create recognition feed entry
            self.recognition_service.create_feed_entry(
                actor_id=1,  # System actor
                receiver_id=user.id,
                source_type="CELEBRATION",
                source_id=celebration.id,
                message=f"Happy Birthday, {user.name}! Enjoy your birthday reward points! 🎂"
            )

            # Send notification
            self.notification_service.create_notification(
                user_id=user.id,
                message=f"🎉 Happy Birthday! You've been awarded {points} reward points. Have a great day!",
                source_type=ReferenceType.CELEBRATION.value,
                source_id=celebration.id,
                email_context={
                    "colleague_name": user.name,
                    "event_type": "Birthday",
                    "event_date": str(today),
                    "recognize_url": "",
                },
            )

            count += 1

        return count

    def _process_anniversaries(self, today: date, base_points: int) -> int:
        """Process work anniversary celebrations for a specific date."""
        count = 0

        users = self.repository.get_users_by_date_field(
            "date_of_joining", today.month, today.day
        )

        for user in users:
            # Calculate years of service
            years = today.year - user.date_of_joining.year
            if years <= 0:  # Joined this year, no anniversary yet
                continue

            # Check if already processed this year
            existing = self.repository.get_celebration(
                user.id, "ANNIVERSARY", today.year
            )

            if existing:
                continue

            # Calculate points (use base_points or multiply by years as per policy)
            points = base_points  # Can be changed to base_points * years if needed

            # Create celebration record
            celebration = self.repository.create_celebration(
                user.id, "ANNIVERSARY", today.year, points
            )

            # Award points
            self.points_service.award_points(
                user_id=user.id,
                points=points,
                source_type=ReferenceType.CELEBRATION.value,
                source_id=celebration.id
            )

            # Create recognition feed entry
            self.recognition_service.create_feed_entry(
                actor_id=1,  # System actor
                receiver_id=user.id,
                source_type="CELEBRATION",
                source_id=celebration.id,
                message=f"Congratulations to {user.name} on their {years}-year work anniversary! 🎉 Thank you for your dedication."
            )

            # Send notification
            self.notification_service.create_notification(
                user_id=user.id,
                message=f"🎊 Happy Work Anniversary! Celebrating {years} year{'s' if years > 1 else ''} with us. You've earned {points} reward points!",
                source_type=ReferenceType.CELEBRATION.value,
                source_id=celebration.id,
                email_context={
                    "colleague_name": user.name,
                    "event_type": f"{years}-Year Work Anniversary",
                    "event_date": str(today),
                    "recognize_url": "",
                },
            )

            count += 1

        return count

    # ────────────────────────────────────────────────────────────────
    # Manual life-event celebrations (HR-only)
    # ────────────────────────────────────────────────────────────────

    # Default points when no PointsPolicy rule exists for the event key
    _LIFE_EVENT_DEFAULTS = {
        "BIRTH": 750,
        "MARRIAGE": 1000,
    }

    # Human-readable labels used in messages
    _LIFE_EVENT_LABELS = {
        "BIRTH": ("New Baby", "🍼"),
        "MARRIAGE": ("Marriage", "💍"),
    }

    def trigger_manual_celebration(
        self, user_id: int, celebration_type: str, hr_actor_id: int
    ) -> Dict[str, Any]:
        """
        Manually trigger a BIRTH or MARRIAGE celebration for an employee.

        Called exclusively by HR/Admin via POST /celebrations/trigger.
        Unlike automated events there is no date-field to scan, so HR
        controls when this fires.  We prevent duplicate triggers within
        the same calendar year to avoid accidental double-awards.

        Returns a dict describing what was done.
        """
        from app.models.users import User
        from app.utils.enums import CelebrationType

        if celebration_type not in (CelebrationType.BIRTH.value, CelebrationType.MARRIAGE.value):
            raise ValueError(f"celebration_type must be BIRTH or MARRIAGE, got '{celebration_type}'")

        today = date.today()
        year = today.year

        # Prevent double-award in the same calendar year
        existing = self.repository.get_celebration(user_id, celebration_type, year)
        if existing:
            label, _ = self._LIFE_EVENT_LABELS[celebration_type]
            raise ValueError(
                f"A {label} celebration was already awarded to user {user_id} in {year}"
            )

        # Resolve employee
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError(f"User {user_id} not found")

        points = self._get_points_from_policy(
            celebration_type,
            default=self._LIFE_EVENT_DEFAULTS[celebration_type],
        )
        label, emoji = self._LIFE_EVENT_LABELS[celebration_type]

        # Record celebration
        celebration = self.repository.create_celebration(user_id, celebration_type, year, points)

        # Award points
        self.points_service.award_points(
            user_id=user_id,
            points=points,
            source_type=ReferenceType.CELEBRATION.value,
            source_id=celebration.id,
        )

        # Recognition feed entry
        if celebration_type == CelebrationType.BIRTH.value:
            feed_message = (
                f"Congratulations to {user.name} on the arrival of their new baby! "
                f"Wishing your family joy and happiness! {emoji}"
            )
        else:  # MARRIAGE
            feed_message = (
                f"Congratulations to {user.name} on their marriage! "
                f"Wishing you a lifetime of happiness together! {emoji}"
            )

        self.recognition_service.create_feed_entry(
            actor_id=hr_actor_id,
            receiver_id=user_id,
            source_type="CELEBRATION",
            source_id=celebration.id,
            message=feed_message,
        )

        # Notification to employee
        if celebration_type == CelebrationType.BIRTH.value:
            notif_message = (
                f"{emoji} Congratulations on your new baby! You've been awarded "
                f"{points} reward points to celebrate this special milestone."
            )
        else:
            notif_message = (
                f"{emoji} Congratulations on your marriage! You've been awarded "
                f"{points} reward points to celebrate this wonderful occasion."
            )

        self.notification_service.create_notification(
            user_id=user_id,
            message=notif_message,
            source_type=ReferenceType.CELEBRATION.value,
            source_id=celebration.id,
            email_context={
                "colleague_name": user.name,
                "event_type": label,
                "event_date": str(today),
                "recognize_url": "",
            },
        )

        self.db.commit()
        return {
            "user_id": user_id,
            "user_name": user.name,
            "celebration_type": celebration_type,
            "points_awarded": points,
            "year": year,
        }
