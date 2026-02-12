"""
Awards service - Business logic for award nominations and approvals.
"""
from sqlalchemy.orm import Session
from typing import Optional, List, Dict, Any
from datetime import datetime
from fastapi import HTTPException

from app.models.awards import Award
from app.models.award_types import AwardType
from app.models.award_approvals import AwardApproval
from app.models.users import User
from app.services.points_service import PointsService
from app.services.notification_service import NotificationService
from app.utils.enums import AwardStatus, ApprovalStatus, ReferenceType, UserRole

class AwardsService:
    """Service for managing award nominations and approvals."""

    def __init__(self, db: Session):
        self.db = db
        self.points_service = PointsService(db)
        self.notification_service = NotificationService(db)

    def nominate_for_award(
        self,
        nominator_id: int,
        nominee_id: int,
        award_type_id: int,
        justification: Optional[str] = None
    ) -> Award:
        """Create an award nomination."""
        # 1. Verify eligibility rules
        if nominator_id == nominee_id:
            raise HTTPException(status_code=400, detail="You cannot nominate yourself for an award.")

        award_type = self.db.query(AwardType).filter(AwardType.id == award_type_id, AwardType.is_active == True).first()
        if not award_type:
            raise HTTPException(status_code=404, detail="Award type not found or inactive.")

        # 2. Create award record with PENDING status
        award = Award(
            nominee_id=nominee_id,
            nominator_id=nominator_id,
            award_type_id=award_type_id,
            status=AwardStatus.PENDING.value,
            points_awarded=award_type.points
        )
        self.db.add(award)
        self.db.commit()
        self.db.refresh(award)

        # 3. Create notification for nominee
        self.notification_service.create_notification(
            user_id=nominee_id,
            message=f"You have been nominated for a {award_type.name} award by {award.nominator.name}!",
            source_type=ReferenceType.AWARD.value,
            source_id=award.id
        )
        
        # 4. Create notification for manager (if nominee has a manager)
        if award.nominee.manager_id:
            self.notification_service.create_notification(
                user_id=award.nominee.manager_id,
                message=f"New Award Nomination: {award.nominee.name} has been nominated for {award_type.name}.",
                source_type=ReferenceType.AWARD.value,
                source_id=award.id
            )

        return award

    def approve_nomination(
        self,
        award_id: int,
        approver_id: int,
        approval_level: str,
        comments: Optional[str] = None
    ) -> Award:
        """Approve an award nomination."""
        award = self.db.query(Award).filter(Award.id == award_id).first()
        if not award:
            raise HTTPException(status_code=404, detail="Award nomination not found.")
        
        if award.status != AwardStatus.PENDING.value:
            raise HTTPException(status_code=400, detail=f"Award is already {award.status}")

        # 1. Create approval record
        approval = AwardApproval(
            award_id=award_id,
            approver_id=approver_id,
            approval_level=approval_level,
            status=ApprovalStatus.APPROVED.value,
            comments=comments
        )
        self.db.add(approval)

        # 2. Update status to APPROVED (Assume 1-level for now)
        award.status = AwardStatus.APPROVED.value
        
        # 3. Award points
        self.points_service.award_points(
            user_id=award.nominee_id,
            points=award.points_awarded,
            source_type=ReferenceType.AWARD.value,
            source_id=award.id
        )

        self.db.commit()
        self.db.refresh(award)
        return award

    def reject_nomination(
        self,
        award_id: int,
        approver_id: int,
        approval_level: str,
        comments: str
    ) -> Award:
        """Reject an award nomination."""
        award = self.db.query(Award).filter(Award.id == award_id).first()
        if not award:
            raise HTTPException(status_code=404, detail="Award nomination not found.")

        if award.status != AwardStatus.PENDING.value:
            raise HTTPException(status_code=400, detail=f"Award is already {award.status}")

        # 1. Create approval record with REJECTED status
        approval = AwardApproval(
            award_id=award_id,
            approver_id=approver_id,
            approval_level=approval_level,
            status=ApprovalStatus.REJECTED.value,
            comments=comments
        )
        self.db.add(approval)

        # 2. Update award status to REJECTED
        award.status = AwardStatus.REJECTED.value
        
        self.db.commit()
        self.db.refresh(award)
        return award

    def get_nominations(
        self,
        user_id: int,
        role: str,
        status_filter: Optional[str] = None,
        skip: int = 0,
        limit: int = 20
    ) -> List[Award]:
        """Get award nominations based on user role."""
        query = self.db.query(Award)
        
        if role == UserRole.EMPLOYEE.value:
            # Employee sees nominations they made or received
            query = query.filter((Award.nominator_id == user_id) | (Award.nominee_id == user_id))
        elif role == UserRole.MANAGER.value:
            # Manager sees all nominations (could be refined to subordinates)
            pass 
        elif role in [UserRole.HR.value, UserRole.DEPT_HEAD.value]:
            # HR/Dept Head sees all
            pass

        if status_filter:
            query = query.filter(Award.status == status_filter)

        return query.order_by(Award.created_at.desc()).offset(skip).limit(limit).all()

    def get_nomination(self, award_id: int) -> Optional[Award]:
        """Get specific nomination details."""
        return self.db.query(Award).filter(Award.id == award_id).first()

    def get_award_types(self, active_only: bool = True) -> List[AwardType]:
        """Get all award types."""
        query = self.db.query(AwardType)
        if active_only:
            query = query.filter(AwardType.is_active == True)
        return query.all()

    def create_award_type(
        self,
        award_key: str,
        name: str,
        points: int,
        frequency: str,
        eligibility_rule: str,
        description: Optional[str] = None
    ) -> AwardType:
        """Create a new award type (admin only)."""
        award_type = AwardType(
            award_key=award_key,
            name=name,
            points=points,
            frequency=frequency,
            eligibility_rule=eligibility_rule,
            description=description
        )
        self.db.add(award_type)
        self.db.commit()
        self.db.refresh(award_type)
        return award_type

    def update_award_type(self, type_id: int, updates: Dict[str, Any]) -> Optional[AwardType]:
        """Update an award type."""
        award_type = self.db.query(AwardType).filter(AwardType.id == type_id).first()
        if not award_type:
            return None
        
        for field, value in updates.items():
            if value is not None:
                setattr(award_type, field, value)
        
        self.db.commit()
        self.db.refresh(award_type)
        return award_type
