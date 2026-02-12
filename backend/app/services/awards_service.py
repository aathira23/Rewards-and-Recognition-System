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
        """
        Approve an award nomination with multi-level workflow.
        
        The award type defines the required approval workflow (e.g., "MANAGER,DEPT_HEAD,HR").
        Approvals must be completed in sequence. Once all required approvals are obtained,
        the award is marked as APPROVED and points are awarded.
        """
        award = self.db.query(Award).filter(Award.id == award_id).first()
        if not award:
            raise HTTPException(status_code=404, detail="Award nomination not found.")
        
        if award.status != AwardStatus.PENDING.value:
            raise HTTPException(status_code=400, detail=f"Award is already {award.status}")

        # 1. Get required approval workflow from award type
        required_levels = self._get_required_approval_levels(award.award_type)
        
        if not required_levels:
            # No workflow defined, default to single approval
            required_levels = [approval_level]
        
        # 2. Check if this approval level is required and not already approved
        existing_approvals = self._get_existing_approvals(award_id)
        
        if approval_level in existing_approvals:
            raise HTTPException(
                status_code=400, 
                detail=f"{approval_level} has already approved this nomination"
            )
        
        # 3. Check if this is the next required approval level
        next_required_level = self._get_next_required_level(required_levels, existing_approvals)
        
        if approval_level != next_required_level:
            raise HTTPException(
                status_code=400,
                detail=f"Approval must be done in order. Next required level: {next_required_level}"
            )
        
        # 4. Create approval record
        approval = AwardApproval(
            award_id=award_id,
            approver_id=approver_id,
            approval_level=approval_level,
            status=ApprovalStatus.APPROVED.value,
            comments=comments
        )
        self.db.add(approval)
        self.db.flush()
        
        # 5. Check if all required approvals are now complete
        all_approvals = existing_approvals + [approval_level]
        
        if self._all_approvals_complete(required_levels, all_approvals):
            # All approvals obtained - mark as APPROVED and award points
            award.status = AwardStatus.APPROVED.value
            
            # Award points to nominee
            self.points_service.award_points(
                user_id=award.nominee_id,
                points=award.points_awarded,
                source_type=ReferenceType.AWARD.value,
                source_id=award.id
            )
            
            # Notify nominee
            self.notification_service.create_notification(
                user_id=award.nominee_id,
                message=f"Congratulations! Your {award.award_type.name} award has been fully approved. {award.points_awarded} points awarded!",
                source_type=ReferenceType.AWARD.value,
                source_id=award.id
            )
        else:
            # More approvals needed - notify next approver
            next_level = self._get_next_required_level(required_levels, all_approvals)
            if next_level:
                # Find users with the next approval level and notify them
                # For now, we'll just log that more approvals are needed
                pass

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
        description: Optional[str] = None,
        approval_workflow: Optional[str] = None
    ) -> AwardType:
        """Create a new award type (admin only)."""
        award_type = AwardType(
            award_key=award_key,
            name=name,
            points=points,
            frequency=frequency,
            eligibility_rule=eligibility_rule,
            description=description,
            approval_workflow=approval_workflow
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
    
    # --- Multi-Level Approval Helper Methods ---
    
    def _get_required_approval_levels(self, award_type: AwardType) -> List[str]:
        """
        Get the list of required approval levels from award type.
        
        Returns:
            List of approval levels in order (e.g., ["MANAGER", "DEPT_HEAD", "HR"])
        """
        if not award_type.approval_workflow:
            # Default workflow if not specified
            return ["MANAGER", "HR"]
        
        # Parse comma-separated workflow
        levels = [level.strip().upper() for level in award_type.approval_workflow.split(",")]
        return levels
    
    def _get_existing_approvals(self, award_id: int) -> List[str]:
        """
        Get list of approval levels that have already approved this award.
        
        Returns:
            List of approval levels that have approved (e.g., ["MANAGER"])
        """
        approvals = self.db.query(AwardApproval).filter(
            AwardApproval.award_id == award_id,
            AwardApproval.status == ApprovalStatus.APPROVED.value
        ).all()
        
        return [approval.approval_level for approval in approvals]
    
    def _get_next_required_level(self, required_levels: List[str], completed_levels: List[str]) -> Optional[str]:
        """
        Determine the next required approval level.
        
        Args:
            required_levels: All required approval levels in order
            completed_levels: Levels that have already approved
            
        Returns:
            Next required approval level or None if all complete
        """
        for level in required_levels:
            if level not in completed_levels:
                return level
        return None
    
    def _all_approvals_complete(self, required_levels: List[str], completed_levels: List[str]) -> bool:
        """
        Check if all required approvals have been obtained.
        
        Args:
            required_levels: All required approval levels
            completed_levels: Levels that have approved
            
        Returns:
            True if all required approvals are complete
        """
        return all(level in completed_levels for level in required_levels)
    
    def get_approval_status(self, award_id: int) -> Dict[str, Any]:
        """
        Get detailed approval status for an award.
        
        Returns:
            Dict with approval progress information
        """
        award = self.db.query(Award).filter(Award.id == award_id).first()
        if not award:
            return None
        
        required_levels = self._get_required_approval_levels(award.award_type)
        completed_levels = self._get_existing_approvals(award_id)
        next_level = self._get_next_required_level(required_levels, completed_levels)
        
        # Get approval details
        approvals = self.db.query(AwardApproval).filter(
            AwardApproval.award_id == award_id
        ).all()
        
        approval_details = [
            {
                "level": approval.approval_level,
                "approver_id": approval.approver_id,
                "approver_name": approval.approver.name if approval.approver else "Unknown",
                "status": approval.status,
                "comments": approval.comments,
                "approved_at": approval.created_at.isoformat()
            }
            for approval in approvals
        ]
        
        return {
            "award_id": award_id,
            "award_status": award.status,
            "required_levels": required_levels,
            "completed_levels": completed_levels,
            "next_required_level": next_level,
            "is_complete": self._all_approvals_complete(required_levels, completed_levels),
            "approval_details": approval_details
        }
