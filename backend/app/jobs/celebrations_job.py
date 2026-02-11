"""
Celebrations job - Automated birthday and anniversary recognition.
"""
from datetime import date
from sqlalchemy import extract
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models.users import User
from app.models.celebrations import Celebration
from app.models.points_policy import PointsPolicy
from app.models.notifications import Notification
from app.services.points_service import PointsService
from app.services.recognition_service import RecognitionService
from app.utils.enums import ReferenceType


def process_celebrations():
    """
    Background job to process daily celebrations.

    Should be run daily (e.g., via cron or scheduler).
    Processes birthdays and work anniversaries for the current date.
    """
    db = SessionLocal()
    try:
        today = date.today()

        log_msg = f"--- Processing celebrations for {today} ---"
        print(log_msg)

        # Process birthdays
        process_birthdays(db, today)

        # Process work anniversaries
        process_anniversaries(db, today)

        db.commit()
        print("--- Celebrations processing complete ---")
    except Exception as e:
        db.rollback()
        print(f"Error processing celebrations: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


def process_birthdays(db: Session, today: date):
    """Process birthday celebrations for today."""
    # 1. Query users with birth_date matching today (day and month)
    users = db.query(User).filter(
        extract('month', User.birth_date) == today.month,
        extract('day', User.birth_date) == today.day
    ).all()

    if not users:
        print("No birthdays today.")
        return

    # 2. Get points value from policy
    policy = db.query(PointsPolicy).filter(
        PointsPolicy.recognition_type == "CELEBRATION",
        PointsPolicy.event_key == "BIRTHDAY",
        PointsPolicy.is_active == True
    ).first()
    points = policy.points if policy else 500  # Default to 500

    points_service = PointsService(db)
    recognition_service = RecognitionService(db)

    for user in users:
        # 3. Check if celebration already exists for this year
        existing = db.query(Celebration).filter(
            Celebration.user_id == user.id,
            Celebration.celebration_type == "BIRTHDAY",
            Celebration.year == today.year
        ).first()

        if existing:
            continue

        print(f"Processing birthday for {user.name} (ID: {user.id})")

        # 4. Create celebration record
        celebration = Celebration(
            user_id=user.id,
            celebration_type="BIRTHDAY",
            year=today.year,
            points_awarded=points
        )
        db.add(celebration)
        db.flush() # Get ID

        # 5. Award points
        points_service.award_points(
            user_id=user.id,
            points=points,
            source_type=ReferenceType.CELEBRATION.value,
            source_id=celebration.id
        )

        # 6. Create recognition feed entry
        recognition_service.create_feed_entry(
            actor_id=1, # System/Admin actor
            receiver_id=user.id,
            source_type="CELEBRATION",
            source_id=celebration.id,
            message=f"Happy Birthday, {user.name}! Enjoy your birthday reward points! 🎂"
        )

        # 7. Send notification
        notification = Notification(
            user_id=user.id,
            message=f"Happy Birthday! You've been awarded {points} reward points. Have a great day!",
            source_type=ReferenceType.CELEBRATION.value,
            source_id=celebration.id
        )
        db.add(notification)


def process_anniversaries(db: Session, today: date):
    """Process work anniversary celebrations for today."""
    # 1. Query users with date_of_joining matching today (day and month)
    users = db.query(User).filter(
        extract('month', User.date_of_joining) == today.month,
        extract('day', User.date_of_joining) == today.day
    ).all()

    if not users:
        print("No work anniversaries today.")
        return

    # 2. Get points value from policy
    policy = db.query(PointsPolicy).filter(
        PointsPolicy.recognition_type == "CELEBRATION",
        PointsPolicy.event_key == "ANNIVERSARY",
        PointsPolicy.is_active == True
    ).first()
    # Base points for anniversary, could multiply by years if needed
    base_points = policy.points if policy else 1000

    points_service = PointsService(db)
    recognition_service = RecognitionService(db)

    for user in users:
        # Calculate years of service
        years = today.year - user.date_of_joining.year
        if years <= 0: # Joined this year
            continue

        # 3. Check if celebration already exists for this year
        existing = db.query(Celebration).filter(
            Celebration.user_id == user.id,
            Celebration.celebration_type == "ANNIVERSARY",
            Celebration.year == today.year
        ).first()

        if existing:
            continue

        print(f"Processing {years}-year anniversary for {user.name} (ID: {user.id})")

        # Award multiplier? (Optional business logic)
        points = base_points # Or base_points * years

        # 4. Create celebration record
        celebration = Celebration(
            user_id=user.id,
            celebration_type="ANNIVERSARY",
            year=today.year,
            points_awarded=points
        )
        db.add(celebration)
        db.flush()

        # 5. Award points
        points_service.award_points(
            user_id=user.id,
            points=points,
            source_type=ReferenceType.CELEBRATION.value,
            source_id=celebration.id
        )

        # 6. Create recognition feed entry
        recognition_service.create_feed_entry(
            actor_id=1,
            receiver_id=user.id,
            source_type="CELEBRATION",
            source_id=celebration.id,
            message=f"Congratulations to {user.name} on their {years}-year work anniversary! 🎉 Thank you for your dedication."
        )

        # 7. Send notification
        notification = Notification(
            user_id=user.id,
            message=f"Happy Work Anniversary! Celebrating {years} years with us. You've earned {points} reward points!",
            source_type=ReferenceType.CELEBRATION.value,
            source_id=celebration.id
        )
        db.add(notification)


if __name__ == "__main__":
    # For manual execution or testing
    process_celebrations()
