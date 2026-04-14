from typing import Optional, List
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.badges import Badge
from app.models.ecards import ECard
from app.models.recognition_feed import RecognitionFeed
from app.models.points_policy import PointsPolicy
from app.utils.query_loader import QueryLoader


class RecognitionRepository:
    def __init__(self, db: Session):
        self.db = db
        loader = QueryLoader()
        self.badge_q = loader.get_queries(Badge)
        self.ecard_q = loader.get_queries(ECard)
        self.feed_q = loader.get_queries(RecognitionFeed)
        self.policy_q = loader.get_queries(PointsPolicy)

    # ── Badges ───────────────────────────────────────────────────────────────

    def get_badges(self, active_only: bool = True) -> List:
        q = self.badge_q.GET_ALL_ACTIVE if active_only else self.badge_q.GET_ALL
        return self.db.execute(q).mappings().fetchall()

    def get_badge_by_id(self, badge_id: int):
        return self.db.execute(self.badge_q.GET_BY_ID, {"id": badge_id}).mappings().fetchone()

    def get_badge_by_name(self, name: str):
        return self.db.execute(self.badge_q.GET_BY_NAME, {"name": name}).mappings().fetchone()

    def create_badge(self, name: str, description: str = None, icon_url: str = None):
        result = self.db.execute(
            self.badge_q.CREATE,
            {"name": name, "description": description, "icon_url": icon_url,
             "points": None, "is_active": True},
        )
        self.db.commit()
        return self.db.execute(self.badge_q.GET_BY_ID, {"id": result.lastrowid}).mappings().fetchone()

    def save_badge(self, badge_id: int, **kwargs):
        self.db.execute(self.badge_q.UPDATE, {"id": badge_id, **kwargs})
        self.db.commit()
        return self.db.execute(self.badge_q.GET_BY_ID, {"id": badge_id}).mappings().fetchone()

    # ── ECards ───────────────────────────────────────────────────────────────

    def count_ecards_since(self, sender_id: int, since: datetime) -> int:
        return (
            self.db.execute(
                self.ecard_q.COUNT_SINCE,
                {"sender_id": sender_id, "since": since},
            ).scalar()
            or 0
        )

    def get_last_ecard(self, sender_id: int, since: Optional[datetime] = None):
        if since:
            return (
                self.db.execute(
                    self.ecard_q.GET_LAST_BY_SENDER_SINCE,
                    {"sender_id": sender_id, "since": since},
                )
                .mappings()
                .fetchone()
            )
        return (
            self.db.execute(
                self.ecard_q.GET_LAST_BY_SENDER, {"sender_id": sender_id}
            )
            .mappings()
            .fetchone()
        )

    def create_ecard(
        self,
        sender_id: int,
        receiver_id: int,
        badge_id: int,
        points: int,
        message: str = None,
        persona_type: str = "PERSONAL",
        persona_label: str = None,
    ):
        result = self.db.execute(
            self.ecard_q.CREATE,
            {
                "sender_id": sender_id,
                "receiver_id": receiver_id,
                "badge_id": badge_id,
                "points_awarded": points,
                "message": message,
                "persona_type": persona_type,
                "persona_label": persona_label,
            },
        )
        self.db.commit()
        return self.db.execute(self.ecard_q.GET_BY_ID, {"id": result.lastrowid}).mappings().fetchone()

    def get_ecards_received(self, user_id: int) -> List:
        return (
            self.db.execute(self.ecard_q.GET_RECEIVED, {"receiver_id": user_id})
            .mappings()
            .fetchall()
        )

    def get_ecards_sent(self, user_id: int) -> List:
        return (
            self.db.execute(self.ecard_q.GET_SENT, {"sender_id": user_id})
            .mappings()
            .fetchall()
        )

    # ── ECard Policy ─────────────────────────────────────────────────────────

    def get_ecard_policy(self):
        return self.db.execute(self.policy_q.GET_ECARD_POLICY).mappings().fetchone()

    def get_celebration_policy(self, event_key: str):
        return (
            self.db.execute(
                self.policy_q.GET_CELEBRATION_POLICY, {"event_key": event_key}
            )
            .mappings()
            .fetchone()
        )



