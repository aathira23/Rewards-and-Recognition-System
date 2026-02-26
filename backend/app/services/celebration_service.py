"""
Celebration service - Production-ready unified celebration processing.
"""
from sqlalchemy.orm import Session
from sqlalchemy import extract
from datetime import date, timedelta
from typing import List, Dict, Any, Optional
from app.models.users import User
from app.models.celebrations import Celebration
from app.models.points_policy import PointsPolicy
from app.services.points_service import PointsService
from app.services.recognition_service import RecognitionService
from app.services.notification_service import NotificationService
from app.utils.enums import ReferenceType


class CelebrationService:
    """Service for managing automated celebrations (birthdays and work anniversaries)."""
    
    def __init__(self, db: Session):
        self.db = db
        self.points_service = PointsService(db)
        self.recognition_service = RecognitionService(db)
        self.notification_service = NotificationService(db)

    def get_upcoming_celebrations(self, days: int = 7) -> List[Dict[str, Any]]:
        """Get users with birthdays or anniversaries in the next N days."""
        today = date.today()
        upcoming = []
        
        # Check for next N days
        for i in range(days + 1):
            target_date = today + timedelta(days=i)
            
            # Birthdays
            birthday_users = self.db.query(User).filter(
                extract('month', User.birth_date) == target_date.month,
                extract('day', User.birth_date) == target_date.day
            ).all()
            
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
            anniversary_users = self.db.query(User).filter(
                extract('month', User.date_of_joining) == target_date.month,
                extract('day', User.date_of_joining) == target_date.day
            ).all()
            
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
        query = self.db.query(Celebration).order_by(Celebration.created_at.desc())
        total = query.count()
        items = query.offset(skip).limit(per_page).all()
        return total, items

    def _get_points_from_policy(self, event_key: str, default: int) -> int:
        """Get points value from PointsPolicy or return default."""
        policy = self.db.query(PointsPolicy).filter(
            PointsPolicy.recognition_type == "CELEBRATION",
            PointsPolicy.event_key == event_key,
            PointsPolicy.is_active == True
        ).first()
        return policy.points if policy else default

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
        
        users = self.db.query(User).filter(
            extract('month', User.birth_date) == today.month,
            extract('day', User.birth_date) == today.day
        ).all()
        
        for user in users:
            # Check if already processed this year
            existing = self.db.query(Celebration).filter(
                Celebration.user_id == user.id,
                Celebration.celebration_type == "BIRTHDAY",
                Celebration.year == today.year
            ).first()
            
            if existing:
                continue
            
            # Create celebration record
            celebration = Celebration(
                user_id=user.id,
                celebration_type="BIRTHDAY",
                year=today.year,
                points_awarded=points
            )
            self.db.add(celebration)
            self.db.flush()  # Get celebration ID
            
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
                source_id=celebration.id
            )
            
            count += 1
            
        return count
    
    def _process_anniversaries(self, today: date, base_points: int) -> int:
        """Process work anniversary celebrations for a specific date."""
        count = 0
        
        users = self.db.query(User).filter(
            extract('month', User.date_of_joining) == today.month,
            extract('day', User.date_of_joining) == today.day
        ).all()
        
        for user in users:
            # Calculate years of service
            years = today.year - user.date_of_joining.year
            if years <= 0:  # Joined this year, no anniversary yet
                continue
            
            # Check if already processed this year
            existing = self.db.query(Celebration).filter(
                Celebration.user_id == user.id,
                Celebration.celebration_type == "ANNIVERSARY",
                Celebration.year == today.year
            ).first()
            
            if existing:
                continue
            
            # Calculate points (use base_points or multiply by years as per policy)
            points = base_points  # Can be changed to base_points * years if needed
            
            # Create celebration record
            celebration = Celebration(
                user_id=user.id,
                celebration_type="ANNIVERSARY",
                year=today.year,
                points_awarded=points
            )
            self.db.add(celebration)
            self.db.flush()  # Get celebration ID
            
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
                source_id=celebration.id
            )
            
            count += 1
            
        return count
