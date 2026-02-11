"""
Seed script to populate the database with demo rewards and policies.
"""
from app.core.database import SessionLocal
from app.models.rewards import Reward
from app.models.points_policy import PointsPolicy
from app.utils.enums import RewardType

def seed():
    db = SessionLocal()
    
    # 1. Add Demo Rewards (Merch & Vouchers)
    rewards = [
        Reward(name="Amazon Gift Card - $50", reward_type=RewardType.GIFT_CARD.value, points_required=500),
        Reward(name="Starbucks Coffee Voucher", reward_type=RewardType.GIFT_CARD.value, points_required=150),
        Reward(name="Ashok Leyland Branded Backpack", reward_type=RewardType.MERCH.value, points_required=1200),
        Reward(name="Premium Leather Notebook", reward_type=RewardType.MERCH.value, points_required=450),
    ]
    
    # 2. Add Conversion Policies
    policies = [
        PointsPolicy(
            recognition_type="CONVERSION",
            conversion_reward_type="PAYROLL",
            conversion_rate=0.1, # 10 pts = $1
            points=0 # dummy
        ),
        PointsPolicy(
            recognition_type="CONVERSION",
            conversion_reward_type="CSR",
            conversion_rate=0.15, # Better rate for charity
            points=0 # dummy
        ),
        PointsPolicy(
            recognition_type="CELEBRATION",
            event_key="BIRTHDAY",
            points=500
        ),
        PointsPolicy(
            recognition_type="CELEBRATION",
            event_key="ANNIVERSARY",
            points=1000
        )
    ]
    
    try:
        # Clear existing for fresh seed if needed (optional)
        # db.query(Reward).delete()
        # db.query(PointsPolicy).delete()

        db.add_all(rewards)
        db.add_all(policies)
        db.commit()
        print("Demo data seeded successfully!")
    except Exception as e:
        print(f"Error seeding data: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
