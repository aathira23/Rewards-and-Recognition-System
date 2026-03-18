"""
Celebrations job - Automated birthday and anniversary recognition.
PRODUCTION: Uses unified CelebrationService for consistency.
"""
from app.core.database import SessionLocal
from app.core.config import settings
from app.services.celebration_service import CelebrationService


def process_celebrations():
    """
    Background job to process daily celebrations.

    Should be run daily (e.g., via cron or scheduler at 9:00 AM).
    Processes birthdays and work anniversaries for the current date.
    
    Usage:
        - Cron: 0 9 * * * /path/to/python /path/to/celebrations_job.py
        - Manual: python app/jobs/celebrations_job.py
    """
    db = SessionLocal()
    try:
        print("🎉 Starting celebration processing...")

        # Use SYSTEM_TOKEN so email service can look up users via User Service
        token = settings.SYSTEM_TOKEN if settings.AUTH_MODE == "user_service" else None
        service = CelebrationService(db, token=token)
        result = service.process_today_celebrations()

        print("✅ Celebration processing complete:")
        print(f"   - Birthdays processed: {result['birthdays']}")
        print(f"   - Anniversaries processed: {result['anniversaries']}")
        print(f"   - Date: {result['date']}")

    except Exception as e:
        db.rollback()
        print(f"❌ Error processing celebrations: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


if __name__ == "__main__":
    # For manual execution or testing
    process_celebrations()
