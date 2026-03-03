from sqlalchemy.orm import Session, joinedload
from typing import Optional, List, Any, Dict
from datetime import datetime

from app.models.badges import Badge
from app.models.ecards import ECard
from app.models.recognition_feed import RecognitionFeed
from app.models.points_policy import PointsPolicy
from app.models.users import User
from app.services.points_service import PointsService
from app.services.notification_service import NotificationService
from app.utils.enums import ReferenceType


class RecognitionService:
    """Service for managing recognitions and leaderboard."""

    def __init__(self, db: Session):
        self.db = db
        self.points_service = PointsService(db)
        self.notification_service = NotificationService(db)

    # --- Badge Management ---
    def get_badges(self, active_only: bool = True) -> List[Badge]:
        """Get all badges."""
        query = self.db.query(Badge)
        if active_only:
            query = query.filter(Badge.is_active == True)
        return query.all()

    def get_badge_by_id(self, badge_id: int) -> Optional[Badge]:
        """Get a badge by ID."""
        return self.db.query(Badge).filter(Badge.id == badge_id).first()

    def create_badge(self, name: str, description: str = None, icon_url: str = None) -> Badge:
        """Create a new badge."""
        # Prevent creating duplicate badges by name (case-insensitive)
        from sqlalchemy import func
        existing = self.db.query(Badge).filter(func.lower(Badge.name) == name.lower()).first()
        if existing:
            raise ValueError("Badge with this name already exists")

        badge = Badge(name=name, description=description, icon_url=icon_url)
        self.db.add(badge)
        self.db.commit()
        self.db.refresh(badge)
        return badge

    def update_badge(self, badge_id: int, data: Dict[str, Any]) -> Badge:
        """Update an existing badge."""
        badge = self.get_badge_by_id(badge_id)
        if not badge:
            raise ValueError("Badge not found")
        for key, value in data.items():
            if value is not None:
                setattr(badge, key, value)
        self.db.commit()
        self.db.refresh(badge)
        return badge

    # --- eCard / Recognition Logic ---
    def send_ecard(
        self,
        sender_id: int,
        receiver_id: int,
        badge_id: int,
        message: Optional[str] = None
    ) -> ECard:
        """Send an eCard recognition."""
        if sender_id == receiver_id:
            raise ValueError("You cannot send a recognition to yourself.")

        # 1. Validate badge
        badge = self.get_badge_by_id(badge_id)
        if not badge or not badge.is_active:
            raise ValueError("Invalid or inactive badge selected.")

        # 2. Get points value — priority:
        #    1) badge.points column (set per-badge via HR Badges tab)
        #    2) generic ECARD policy row (event_key IS NULL) — org-wide default
        #    3) hardcoded fallback of 50
        if badge.points is not None:
            points = badge.points
        else:
            generic_policy = self.db.query(PointsPolicy).filter(
                PointsPolicy.recognition_type == "ECARD",
                PointsPolicy.event_key == None,
                PointsPolicy.is_active == True
            ).first()
            points = generic_policy.points if generic_policy else 50

        # 3. Create eCard record
        ecard = ECard(
            sender_id=sender_id,
            receiver_id=receiver_id,
            badge_id=badge_id,
            points_awarded=points,
            message=message
        )
        self.db.add(ecard)
        self.db.commit()
        self.db.refresh(ecard)

        # 4. Award points to receiver
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
        sender = self.db.query(User).filter(User.id == sender_id).first()
        sender_name = sender.name if sender else "A colleague"
        self.notification_service.create_notification(
            user_id=receiver_id,
            message=f"{sender_name} appreciated you with a '{badge.name}' badge! {points} points earned.",
            source_type=ReferenceType.ECARD.value,
            source_id=ecard.id
        )

        return ecard

    def get_recognition_feed(self, page: int = 1, per_page: int = 20):
        """Get company-wide recognition feed. Returns (total, items)."""
        from app.utils.constants import clamp_pagination
        page, per_page, skip = clamp_pagination(page, per_page)
        query = self.db.query(RecognitionFeed).options(
            joinedload(RecognitionFeed.actor),
            joinedload(RecognitionFeed.receiver)
        ).filter(RecognitionFeed.source_type != "MANAGER_REWARD")
        total = query.count()
        items = query.order_by(RecognitionFeed.created_at.desc()).offset(skip).limit(per_page).all()

        # Inflate eCard details (specifically badges) for feed items
        from app.models.badges import Badge
        from app.models.ecards import ECard

        for item in items:
            if item.source_type == "ECARD":
                # Fetch badge info via eCard relation
                badge = self.db.query(Badge).join(ECard).filter(ECard.id == item.source_id).first()
                if badge:
                    # Attach to object for Pydantic schema to pick up
                    item.badge = badge

        return total, items

    def get_appreciation_overview(self, user_id: int) -> Dict[str, Any]:
        """Get recognitions received and sent by a user."""
        from app.schemas.ecards import ECardResponse

        received = self.db.query(ECard).options(
            joinedload(ECard.sender),
            joinedload(ECard.badge)
        ).filter(ECard.receiver_id == user_id).order_by(ECard.created_at.desc()).all()

        sent = self.db.query(ECard).options(
            joinedload(ECard.receiver),
            joinedload(ECard.badge)
        ).filter(ECard.sender_id == user_id).order_by(ECard.created_at.desc()).all()

        return {
            "received": [ECardResponse.model_validate(r).model_dump() for r in received],
            "sent": [ECardResponse.model_validate(s).model_dump() for s in sent],
            "total_received": len(received),
            "total_sent": len(sent)
        }
    def create_feed_entry(
        self,
        actor_id: int,
        receiver_id: Optional[int],
        source_type: str,
        source_id: int,
        message: str
    ) -> RecognitionFeed:
        """Create a new entry in the recognition feed."""
        entry = RecognitionFeed(
            actor_id=actor_id,
            receiver_id=receiver_id,
            source_type=source_type,
            source_id=source_id,
            message=message
        )
        self.db.add(entry)
        self.db.commit()
        self.db.refresh(entry)
        return entry

    # --- Automated Logic ---
    def create_automated_recognition(
        self,
        user_id: int,
        celebration_type: str, # BIRTHDAY or ANNIVERSARY
        message: str
    ) -> RecognitionFeed:
        """Logic for automated system recognitions."""
        # 1. Fetch points from policy
        policy = self.db.query(PointsPolicy).filter(
            PointsPolicy.recognition_type == "CELEBRATION",
            PointsPolicy.event_key == celebration_type,
            PointsPolicy.is_active == True
        ).first()
        points = policy.points if policy else 500

        # 2. Award points
        # In a real system, we'd also create a record in 'celebrations' table
        # For simplicity and feed logic, we directly feed the recognition feed

        # Find an admin user to act as the "system" sender
        admin = self.db.query(User).filter(User.role == "ADMIN").first()
        system_actor_id = admin.id if admin else 1 # fallback to 1 if no admin found

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
        from sqlalchemy import func, desc
        from app.models.points_ledger import PointsLedger
        from app.models.wallets import Wallet
        from app.models.ecards import ECard

        # Determine start date. For 'ALL_TIME' do not apply a date filter.
        start_date: Optional[datetime] = datetime.now().replace(
            day=1, hour=0, minute=0, second=0, microsecond=0
        )
        if period == "YEARLY":
            start_date = start_date.replace(month=1)
        elif period == "ALL_TIME":
            start_date = None

        # Base Query
        if metric == "POINTS":
            # Rank by total points received (excluding budget allocations)
            query = self.db.query(
                User,
                func.sum(PointsLedger.points).label("total_score"),
                func.count(PointsLedger.id).label("count")
            ).join(Wallet, User.id == Wallet.user_id
            ).join(PointsLedger, Wallet.id == PointsLedger.target_wallet_id
            ).filter(
                PointsLedger.transaction_type == "CREDIT",
                PointsLedger.reference_type != "BUDGET_ALLOCATION",  # Exclude HR budget allocations
            )
            if start_date is not None:
                query = query.filter(PointsLedger.created_at >= start_date)
            results = query.group_by(User.id).order_by(desc("total_score")).limit(limit).all()
        else:
            # Rank by number of recognitions (eCards) received
            query = self.db.query(
                User,
                func.count(ECard.id).label("total_score"),
                func.sum(ECard.points_awarded).label("points")
            ).join(ECard, User.id == ECard.receiver_id)
            if start_date is not None:
                query = query.filter(ECard.created_at >= start_date)
            results = query.group_by(User.id).order_by(desc("total_score")).limit(limit).all()

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
