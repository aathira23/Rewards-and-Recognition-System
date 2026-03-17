from typing import Optional, List, Tuple, Dict, Any
from datetime import date, datetime, timedelta

from sqlalchemy import func, or_, desc
from sqlalchemy.orm import Session, joinedload

from app.models.badges import Badge
from app.models.ecards import ECard
from app.models.recognition_feed import RecognitionFeed
from app.models.points_policy import PointsPolicy
from app.models.users import User


class RecognitionRepository:
    def __init__(self, db: Session):
        self.db = db

    # --- Badges ---
    def get_badges(self, active_only: bool = True) -> List[Badge]:
        query = self.db.query(Badge)
        if active_only:
            query = query.filter(Badge.is_active == True)
        return query.all()

    def get_badge_by_id(self, badge_id: int) -> Optional[Badge]:
        return self.db.query(Badge).filter(Badge.id == badge_id).first()

    def get_badge_by_name(self, name: str) -> Optional[Badge]:
        from sqlalchemy import func as sqlfunc
        return self.db.query(Badge).filter(sqlfunc.lower(Badge.name) == name.lower()).first()

    def create_badge(self, name: str, description: str = None, icon_url: str = None) -> Badge:
        badge = Badge(name=name, description=description, icon_url=icon_url)
        self.db.add(badge)
        self.db.commit()
        self.db.refresh(badge)
        return badge

    def save_badge(self, badge: Badge) -> Badge:
        self.db.commit()
        self.db.refresh(badge)
        return badge

    # --- ECards ---
    def count_ecards_since(self, sender_id: int, since: datetime) -> int:
        return self.db.query(ECard).filter(
            ECard.sender_id == sender_id,
            ECard.created_at >= since,
        ).count()

    def get_last_ecard(self, sender_id: int, since: Optional[datetime] = None) -> Optional[ECard]:
        query = self.db.query(ECard).filter(ECard.sender_id == sender_id)
        if since:
            query = query.filter(ECard.created_at >= since)
        return query.order_by(ECard.created_at.desc()).first()

    def create_ecard(
        self, sender_id: int, receiver_id: int, badge_id: int, points: int, message: str = None
    ) -> ECard:
        ecard = ECard(
            sender_id=sender_id,
            receiver_id=receiver_id,
            badge_id=badge_id,
            points_awarded=points,
            message=message,
        )
        self.db.add(ecard)
        self.db.commit()
        self.db.refresh(ecard)
        return ecard

    def get_ecards_received(self, user_id: int) -> List[ECard]:
        return (
            self.db.query(ECard)
            .options(joinedload(ECard.badge))
            .filter(ECard.receiver_id == user_id)
            .order_by(ECard.created_at.desc())
            .all()
        )

    def get_ecards_sent(self, user_id: int) -> List[ECard]:
        return (
            self.db.query(ECard)
            .options(joinedload(ECard.badge))
            .filter(ECard.sender_id == user_id)
            .order_by(ECard.created_at.desc())
            .all()
        )

    # --- ECard Policy ---
    def get_ecard_policy(self) -> Optional[PointsPolicy]:
        return self.db.query(PointsPolicy).filter(
            PointsPolicy.recognition_type == "ECARD",
            PointsPolicy.event_key == None,
            PointsPolicy.is_active == True,
        ).first()

    def get_celebration_policy(self, event_key: str) -> Optional[PointsPolicy]:
        return self.db.query(PointsPolicy).filter(
            PointsPolicy.recognition_type == "CELEBRATION",
            PointsPolicy.event_key == event_key,
            PointsPolicy.is_active == True,
        ).first()

    # --- Recognition Feed ---
    def create_feed_entry(
        self, actor_id: int, receiver_id: Optional[int], source_type: str, source_id: int, message: str
    ) -> RecognitionFeed:
        entry = RecognitionFeed(
            actor_id=actor_id,
            receiver_id=receiver_id,
            source_type=source_type,
            source_id=source_id,
            message=message,
        )
        self.db.add(entry)
        self.db.commit()
        self.db.refresh(entry)
        return entry

    def get_feed_paginated(self, skip: int, limit: int) -> Tuple[int, List[RecognitionFeed]]:
        query = (
            self.db.query(RecognitionFeed)
            .filter(RecognitionFeed.source_type != "MANAGER_REWARD")
        )
        total = query.count()
        items = query.order_by(RecognitionFeed.created_at.desc()).offset(skip).limit(limit).all()
        return total, items

    def get_badge_for_ecard(self, ecard_source_id: int) -> Optional[Badge]:
        return self.db.query(Badge).join(ECard).filter(ECard.id == ecard_source_id).first()

    # --- User lookup ---
    def get_user_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def get_admin_user(self) -> Optional[User]:
        return self.db.query(User).filter(User.role == "ADMIN").first()

    # --- Leaderboard ---
    def get_points_leaderboard(
        self, start_date: Optional[datetime], limit: int
    ) -> List[Tuple]:
        from app.models.points_ledger import PointsLedger
        from app.models.wallets import Wallet

        query = self.db.query(
            User,
            func.sum(PointsLedger.points).label("total_score"),
            func.count(PointsLedger.id).label("count"),
        ).join(
            Wallet, User.id == Wallet.user_id
        ).join(
            PointsLedger, Wallet.id == PointsLedger.target_wallet_id
        ).filter(
            PointsLedger.transaction_type == "CREDIT",
            PointsLedger.reference_type != "BUDGET_ALLOCATION",
        )
        if start_date is not None:
            query = query.filter(PointsLedger.created_at >= start_date)
        return query.group_by(User.id).order_by(desc("total_score")).limit(limit).all()

    def get_recognition_leaderboard(
        self, start_date: Optional[datetime], limit: int
    ) -> List[Tuple]:
        query = self.db.query(
            User,
            func.count(ECard.id).label("total_score"),
            func.sum(ECard.points_awarded).label("points"),
        ).join(ECard, User.id == ECard.receiver_id)
        if start_date is not None:
            query = query.filter(ECard.created_at >= start_date)
        return query.group_by(User.id).order_by(desc("total_score")).limit(limit).all()
