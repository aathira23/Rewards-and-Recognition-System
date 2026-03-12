from typing import Optional, List, Tuple, Any
from datetime import date, datetime

from sqlalchemy import func, or_, desc
from sqlalchemy.orm import Session

from app.models.rewards import Reward
from app.models.redemptions import Redemption
from app.models.points_conversion import PointsConversion
from app.models.points_policy import PointsPolicy
from app.utils.enums import ConversionStatus


class StoreRepository:
    def __init__(self, db: Session):
        self.db = db

    # --- Rewards / Catalog ---
    def get_catalog_paginated(
        self, skip: int, limit: int, include_inactive: bool = False
    ) -> Tuple[int, List[Reward]]:
        query = self.db.query(Reward)
        if not include_inactive:
            query = query.filter(
                Reward.is_active == True,
                or_(Reward.stock_quantity == None, Reward.stock_quantity > 0),
            )
        total = query.count()
        items = query.offset(skip).limit(limit).all()
        return total, items

    def get_reward_by_id(self, reward_id: int) -> Optional[Reward]:
        return self.db.query(Reward).filter(Reward.id == reward_id).first()

    def create_reward(self, data: dict) -> Reward:
        reward = Reward(**data)
        self.db.add(reward)
        self.db.commit()
        self.db.refresh(reward)
        return reward

    def save_reward(self, reward: Reward) -> Reward:
        self.db.commit()
        self.db.refresh(reward)
        return reward

    # --- Redemptions ---
    def create_redemption(
        self, user_id: int, reward_id: int, points_used: int, status: str
    ) -> Redemption:
        redemption = Redemption(
            user_id=user_id,
            reward_id=reward_id,
            points_used=points_used,
            status=status,
        )
        self.db.add(redemption)
        self.db.commit()
        self.db.refresh(redemption)
        return redemption

    def get_redemptions_by_user(self, user_id: int) -> List[Redemption]:
        return (
            self.db.query(Redemption)
            .filter(Redemption.user_id == user_id)
            .order_by(Redemption.created_at.desc())
            .all()
        )

    # --- Conversions ---
    def create_conversion(
        self,
        user_id: int,
        points: int,
        cash_amount: float,
        conversion_type: str,
        status: str,
    ) -> PointsConversion:
        conversion = PointsConversion(
            user_id=user_id,
            points_converted=points,
            cash_amount=cash_amount,
            conversion_type=conversion_type,
            status=status,
        )
        self.db.add(conversion)
        self.db.commit()
        self.db.refresh(conversion)
        return conversion

    def get_conversion_by_id(self, conversion_id: int) -> Optional[PointsConversion]:
        return self.db.query(PointsConversion).filter(PointsConversion.id == conversion_id).first()

    def get_conversions_by_user(self, user_id: int) -> List[PointsConversion]:
        return (
            self.db.query(PointsConversion)
            .filter(PointsConversion.user_id == user_id)
            .order_by(PointsConversion.requested_at.desc())
            .all()
        )

    def get_all_conversions(self) -> List[PointsConversion]:
        return self.db.query(PointsConversion).order_by(PointsConversion.requested_at.desc()).all()

    def get_pending_conversions(self) -> List[PointsConversion]:
        return (
            self.db.query(PointsConversion)
            .filter(PointsConversion.status == ConversionStatus.PENDING.value)
            .all()
        )

    def save_conversion(self, conversion: PointsConversion) -> PointsConversion:
        self.db.commit()
        self.db.refresh(conversion)
        return conversion

    # --- Policies ---
    def get_policies(self, include_inactive: bool = False) -> List[PointsPolicy]:
        query = self.db.query(PointsPolicy)
        if not include_inactive:
            query = query.filter(PointsPolicy.is_active == True)
        return query.all()

    def get_policy_by_id(self, policy_id: int) -> Optional[PointsPolicy]:
        return self.db.query(PointsPolicy).filter(PointsPolicy.id == policy_id).first()

    def find_duplicate_policies(
        self, recognition_type: str, event_key: Optional[str] = None, conversion_reward_type: Optional[str] = None
    ) -> List[PointsPolicy]:
        if recognition_type == "CONVERSION":
            return self.db.query(PointsPolicy).filter(
                PointsPolicy.recognition_type == recognition_type,
                PointsPolicy.conversion_reward_type == conversion_reward_type,
            ).all()

        query = self.db.query(PointsPolicy).filter(
            PointsPolicy.recognition_type == recognition_type,
        )
        if event_key:
            query = query.filter(PointsPolicy.event_key == event_key)
        else:
            query = query.filter(PointsPolicy.event_key == None)
        return query.all()

    def create_policy(self, data: dict) -> PointsPolicy:
        policy = PointsPolicy(**data)
        self.db.add(policy)
        self.db.commit()
        self.db.refresh(policy)
        return policy

    def save_policy(self, policy: PointsPolicy) -> PointsPolicy:
        self.db.commit()
        self.db.refresh(policy)
        return policy
