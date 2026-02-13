"""
Points expiry job - Expire old points batches.
PRODUCTION: Uses PointsService for consistency.
"""
from app.core.database import SessionLocal
from app.services.points_service import PointsService


def expire_points():
    """
    Background job to expire old points batches.

    Should be run daily (e.g., via cron or scheduler).
    Finds batches past their expiry date and deducts remaining points.
    
    Usage:
        - Cron: 0 0 * * * /path/to/python /path/to/points_expiry_job.py
        - Manual: python app/jobs/points_expiry_job.py
    """
    db = SessionLocal()
    try:
        print("⏰ Starting points expiry processing...")
        
        # Use service method
        service = PointsService(db)

        # 1. Notify users of upcoming expiries (pre-expiry reminders)
        reminder_result = service.notify_upcoming_expiries()
        print(f"🔔 Pre-expiry notifications created: {reminder_result['batches_notified']} batches, {reminder_result['total_points_notified']} points (window={reminder_result['days']}d)")

        # 2. Expire actual batches past their expiry date
        result = service.expire_points_batches()

        print(f"✅ Points expiry processing complete:")
        print(f"   - Pre-expiry reminders: {reminder_result['batches_notified']}")
        print(f"   - Batches expired: {result['batches_expired']}")
        print(f"   - Total points expired: {result['total_points_expired']}")
        print(f"   - Date: {result['date']}")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error expiring points: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


if __name__ == "__main__":
    # For manual execution or testing
    expire_points()
