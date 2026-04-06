from typing import Optional, List, Dict, Any, Tuple
from datetime import date, datetime

from sqlalchemy import func, or_, and_
from sqlalchemy.orm import Session, joinedload

from app.models.awards import Award
from app.models.award_types import AwardType
from app.models.award_approvals import AwardApproval
from app.utils.enums import AwardStatus, ApprovalStatus


class AwardsRepository:
    def __init__(self, db: Session):
        self.db = db

    # --- Award CRUD ---
    def get_by_id(self, award_id: int) -> Optional[Award]:
        return self.db.query(Award).filter(Award.id == award_id).first()

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
    ) -> Award:
        award = Award(
            nominee_id=nominee_id,
            nominator_id=nominator_id,
            award_type_id=award_type_id,
            status=status,
            points_awarded=points,
            citation=citation,
            persona_type=persona_type,
            persona_label=persona_label,
        )
        self.db.add(award)
        self.db.flush()
        self.db.refresh(award)
        return award

    def find_pending_nomination(
        self, nominee_id: int, award_type_id: int
    ) -> Optional[Award]:
        return self.db.query(Award).filter(
            Award.nominee_id == nominee_id,
            Award.award_type_id == award_type_id,
            Award.status == AwardStatus.PENDING.value,
        ).first()

    # --- Award Types ---
    def get_award_type_by_id(self, type_id: int, active_only: bool = False) -> Optional[AwardType]:
        query = self.db.query(AwardType).filter(AwardType.id == type_id)
        if active_only:
            query = query.filter(AwardType.is_active == True)
        return query.first()

    def get_award_types(
        self, active_only: bool = True, eligibility_rules: Optional[List[str]] = None
    ) -> List[AwardType]:
        query = self.db.query(AwardType)
        if active_only:
            query = query.filter(AwardType.is_active == True)
        if eligibility_rules:
            query = query.filter(AwardType.eligibility_rule.in_(eligibility_rules))
        return query.all()

    def get_award_type_by_key(self, award_key: str) -> Optional[AwardType]:
        return self.db.query(AwardType).filter(AwardType.award_key == award_key).first()

    def get_award_type_by_name(self, name: str) -> Optional[AwardType]:
        return self.db.query(AwardType).filter(
            func.lower(AwardType.name) == name.lower()
        ).first()

    def create_award_type(self, **kwargs) -> AwardType:
        award_type = AwardType(**kwargs)
        self.db.add(award_type)
        self.db.commit()
        self.db.refresh(award_type)
        return award_type

    def save_award_type(self, award_type: AwardType) -> AwardType:
        self.db.commit()
        self.db.refresh(award_type)
        return award_type

    # --- Approvals ---
    def create_approval(
        self,
        award_id: int,
        approver_id: int,
        approval_level: str,
        status: str,
        comments: Optional[str] = None,
    ) -> AwardApproval:
        approval = AwardApproval(
            award_id=award_id,
            approver_id=approver_id,
            approval_level=approval_level,
            status=status,
            comments=comments,
        )
        self.db.add(approval)
        self.db.flush()
        return approval

    def get_approved_levels(self, award_id: int) -> List[str]:
        approvals = self.db.query(AwardApproval).filter(
            AwardApproval.award_id == award_id,
            AwardApproval.status == ApprovalStatus.APPROVED.value,
        ).all()
        return [str(a.approval_level).strip().upper() for a in approvals]

    def get_approvals_for_award(self, award_id: int) -> List[AwardApproval]:
        return self.db.query(AwardApproval).filter(
            AwardApproval.award_id == award_id,
        ).all()

    def get_approvals_by_user(self, user_id: int) -> List[AwardApproval]:
        return (
            self.db.query(AwardApproval)
            .filter(AwardApproval.approver_id == user_id)
            .order_by(AwardApproval.created_at.desc())
            .all()
        )

    def get_approvals_for_awards(self, award_ids: List[int]) -> List[AwardApproval]:
        return (
            self.db.query(AwardApproval)
            .filter(AwardApproval.award_id.in_(award_ids))
            .order_by(AwardApproval.created_at.desc())
            .all()
        )

    # --- Nominations visibility ---
    def get_involved_award_ids(self, user_id: int) -> set:
        rows = self.db.query(Award.id).outerjoin(AwardApproval).filter(
            or_(
                Award.nominator_id == user_id,
                Award.nominee_id == user_id,
                AwardApproval.approver_id == user_id,
            )
        ).all()
        return {r[0] for r in rows}

    def get_pending_awards_not_in(self, exclude_ids: set) -> List[Award]:
        return (
            self.db.query(Award)
            .filter(
                Award.status == AwardStatus.PENDING.value,
                ~Award.id.in_(exclude_ids) if exclude_ids else True,
            )
            .options(
                joinedload(Award.award_type),
                joinedload(Award.approvals),
            )
            .all()
        )

    def get_filtered_awards(
        self,
        award_ids: set,
        status_filter: Optional[str],
        skip: int,
        limit: int,
    ) -> Tuple[int, List[Award]]:
        query = self.db.query(Award).filter(Award.id.in_(award_ids))
        if status_filter:
            query = query.filter(Award.status == status_filter)
        total = query.count()
        awards = query.order_by(Award.created_at.desc()).offset(skip).limit(limit).all()
        return total, awards

    # --- Transaction helpers ---
    def commit(self) -> None:
        self.db.commit()

    def refresh(self, obj) -> None:
        self.db.refresh(obj)
