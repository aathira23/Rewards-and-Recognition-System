from typing import Optional, List, Tuple

from sqlalchemy.orm import Session

from app.models.awards import Award
from app.models.award_types import AwardType
from app.models.award_approvals import AwardApproval
from app.utils.query_loader import QueryLoader


class AwardsRepository:
    def __init__(self, db: Session):
        self.db = db
        loader = QueryLoader()
        self.q = loader.get_queries(Award)
        self.type_q = loader.get_queries(AwardType)
        self.approval_q = loader.get_queries(AwardApproval)

    # ── helpers ──────────────────────────────────────────────────────────────

    def _award_by_id(self, aid: int):
        return self.db.execute(self.q.GET_BY_ID, {"id": aid}).mappings().fetchone()

    def _approval_by_id(self, aid: int):
        return self.db.execute(self.approval_q.GET_BY_ID, {"id": aid}).mappings().fetchone()

    # ── Award CRUD ───────────────────────────────────────────────────────────

    def get_by_id(self, award_id: int):
        return self._award_by_id(award_id)

    def create_award(
        self,
        nominee_id: int,
        nominator_id: int,
        award_type_id: int,
        status: str,
        points: int,
        citation: Optional[str] = None,
        persona_type: Optional[str] = None,
        persona_label: Optional[str] = None,
    ):
        result = self.db.execute(
            self.q.CREATE,
            {
                "nominee_id": nominee_id,
                "nominator_id": nominator_id,
                "award_type_id": award_type_id,
                "status": status,
                "points_awarded": points,
                "citation": citation,
                "persona_type": persona_type,
                "persona_label": persona_label,
            },
        )
        self.db.flush()
        return self._award_by_id(result.lastrowid)

    def find_pending_nomination(self, nominee_id: int, award_type_id: int):
        return (
            self.db.execute(
                self.q.FIND_PENDING_NOMINATION,
                {"nominee_id": nominee_id, "award_type_id": award_type_id},
            )
            .mappings()
            .fetchone()
        )

    # ── Award Types ──────────────────────────────────────────────────────────

    def get_award_type_by_id(self, type_id: int, active_only: bool = False):
        q = self.type_q.GET_BY_ID_ACTIVE if active_only else self.type_q.GET_BY_ID
        return self.db.execute(q, {"id": type_id}).mappings().fetchone()

    def get_award_types(
        self, active_only: bool = True, eligibility_rules: Optional[List[str]] = None
    ) -> List:
        if eligibility_rules:
            return (
                self.db.execute(
                    self.type_q.GET_ACTIVE_WITH_ELIGIBILITY,
                    {"eligibility_rules": tuple(eligibility_rules)},
                )
                .mappings()
                .fetchall()
            )
        q = self.type_q.GET_ALL_ACTIVE if active_only else self.type_q.GET_ALL
        return self.db.execute(q).mappings().fetchall()

    def get_award_type_by_key(self, award_key: str):
        return (
            self.db.execute(self.type_q.GET_BY_KEY, {"award_key": award_key})
            .mappings()
            .fetchone()
        )

    def get_award_type_by_name(self, name: str):
        return (
            self.db.execute(self.type_q.GET_BY_NAME, {"name": name})
            .mappings()
            .fetchone()
        )

    def create_award_type(self, **kwargs):
        result = self.db.execute(self.type_q.CREATE, kwargs)
        self.db.commit()
        return (
            self.db.execute(self.type_q.GET_BY_ID, {"id": result.lastrowid})
            .mappings()
            .fetchone()
        )

    def save_award_type(self, award_type_id: int, **kwargs):
        self.db.execute(self.type_q.UPDATE, {"id": award_type_id, **kwargs})
        self.db.commit()
        return (
            self.db.execute(self.type_q.GET_BY_ID, {"id": award_type_id})
            .mappings()
            .fetchone()
        )

    # ── Approvals ────────────────────────────────────────────────────────────

    def create_approval(
        self,
        award_id: int,
        approver_id: int,
        approval_level: str,
        status: str,
        comments: Optional[str] = None,
    ):
        result = self.db.execute(
            self.approval_q.CREATE,
            {
                "award_id": award_id,
                "approver_id": approver_id,
                "approval_level": approval_level,
                "status": status,
                "comments": comments,
            },
        )
        self.db.flush()
        return self._approval_by_id(result.lastrowid)

    def get_approved_levels(self, award_id: int) -> List[str]:
        rows = (
            self.db.execute(
                self.approval_q.GET_APPROVED_LEVELS, {"award_id": award_id}
            )
            .mappings()
            .fetchall()
        )
        return [str(r["approval_level"]).strip().upper() for r in rows]

    def get_approvals_for_award(self, award_id: int) -> List:
        return (
            self.db.execute(
                self.approval_q.GET_BY_AWARD_ID, {"award_id": award_id}
            )
            .mappings()
            .fetchall()
        )

    def get_approvals_by_user(self, user_id: int) -> List:
        return (
            self.db.execute(
                self.approval_q.GET_BY_APPROVER, {"approver_id": user_id}
            )
            .mappings()
            .fetchall()
        )

    def get_approvals_for_awards(self, award_ids: List[int]) -> List:
        if not award_ids:
            return []
        return (
            self.db.execute(
                self.approval_q.GET_BY_AWARD_IDS, {"award_ids": tuple(award_ids)}
            )
            .mappings()
            .fetchall()
        )

    # ── Nominations visibility ───────────────────────────────────────────────

    def get_involved_award_ids(self, user_id: int) -> set:
        rows = (
            self.db.execute(self.q.GET_INVOLVED_IDS, {"user_id": user_id})
            .mappings()
            .fetchall()
        )
        return {r["id"] for r in rows}

    def get_pending_awards_not_in(self, exclude_ids: set) -> List:
        if exclude_ids:
            return (
                self.db.execute(
                    self.q.GET_PENDING_EXCLUDING,
                    {"exclude_ids": tuple(exclude_ids)},
                )
                .mappings()
                .fetchall()
            )
        return self.db.execute(self.q.GET_PENDING_NO_EXCLUSION).mappings().fetchall()

    def get_filtered_awards(
        self,
        award_ids: set,
        status_filter: Optional[str],
        skip: int,
        limit: int,
    ) -> Tuple[int, List]:
        ids = tuple(award_ids) if award_ids else (0,)
        total = self.db.execute(
            self.q.GET_FILTERED_COUNT,
            {"award_ids": ids, "status": status_filter},
        ).scalar()
        items = (
            self.db.execute(
                self.q.GET_FILTERED,
                {"award_ids": ids, "status": status_filter, "limit": limit, "skip": skip},
            )
            .mappings()
            .fetchall()
        )
        return total, list(items)

    # ── Transaction helpers ──────────────────────────────────────────────────

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, obj) -> None:
        pass  # not needed with raw SQL



