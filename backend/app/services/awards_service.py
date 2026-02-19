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
        """
        Create an award nomination.
        - HR nominations are auto-approved.
        - Managers and Dept Heads' own level is marked as approved automatically.
        - Employees can nominate; their nominations follow the full workflow.
        """
        nominator = self.db.query(User).filter(User.id == nominator_id).first()
        if not nominator:
            raise HTTPException(status_code=404, detail="Nominator not found.")

        # 1. Verify eligibility rules
        if nominator_id == nominee_id:
            raise HTTPException(status_code=400, detail="You cannot nominate yourself for an award.")

        award_type = self.db.query(AwardType).filter(AwardType.id == award_type_id, AwardType.is_active == True).first()
        if not award_type:
            raise HTTPException(status_code=404, detail="Award type not found or inactive.")

        # Prevent duplicate pending nominations for same nominee and award type
        existing_nom = self.db.query(Award).filter(
            Award.nominee_id == nominee_id,
            Award.award_type_id == award_type_id,
            Award.status == AwardStatus.PENDING.value
        ).first()
        if existing_nom:
            raise HTTPException(status_code=400, detail="A pending nomination for this nominee and award type already exists.")

        # --- Eligibility checks based on nominator role ---
        nominee = self.db.query(User).filter(User.id == nominee_id).first()
        if not nominee:
            raise HTTPException(status_code=404, detail="Nominee not found.")

        # Managers may only nominate their direct reports
        if nominator.role == UserRole.MANAGER.value:
            if nominee.manager_id != nominator_id:
                raise HTTPException(status_code=403, detail="Managers can only nominate their direct reports.")

        # Dept Heads may only nominate employees within their department
        if nominator.role == UserRole.DEPT_HEAD.value:
            if nominee.department_id != nominator.department_id:
                raise HTTPException(status_code=403, detail="Dept Heads can only nominate employees within their department.")

        # HR may nominate anyone; Employees follow existing rules (no extra restriction)

        # 2. Create award record with PENDING status
        award = Award(
            nominee_id=nominee_id,
            nominator_id=nominator_id,
            award_type_id=award_type_id,
            status=AwardStatus.PENDING.value,
            points_awarded=award_type.points,
            justification=justification
        )
        self.db.add(award)
        self.db.flush() # Use flush to get award.id before commit
        
        # Refresh to load the award_type relationship
        self.db.refresh(award)

        # 3. Handle Auto-Approval for Nominator's Own Level (Only for Manager+, not Employee)
        # HR nominations are fully auto-approved.
        # Managers and Dept Heads' own level is marked as approved automatically.
        # Employees' nominations follow the full workflow, no auto-approvals.
        
        current_approvals = [] # Keep track of approvals added in this step
        
        if nominator.role in (UserRole.HR.value, UserRole.ADMIN.value):
            # HR nominations are fully auto-approved
            award.status = AwardStatus.APPROVED.value
            required_levels = self._get_required_approval_levels(award_type)
            for level in required_levels:
                approval = AwardApproval(
                    award_id=award.id,
                    approver_id=nominator_id,
                    approval_level=level,
                    status=ApprovalStatus.APPROVED.value,
                    comments="Auto-approved by HR nominator"
                )
                self.db.add(approval)
                current_approvals.append(level)
            
            # Award points immediately if HR auto-approved
            self.points_service.award_points(
                user_id=award.nominee_id,
                points=award.points_awarded,
                source_type=ReferenceType.AWARD.value,
                source_id=award.id
            )
            
            # Notify nominee of approval
            self.notification_service.create_notification(
                user_id=award.nominee_id,
                message=f"Congratulations! Your {award.award_type.name} award has been fully approved by HR. {award.points_awarded} points awarded!",
                source_type=ReferenceType.AWARD.value,
                source_id=award.id
            )

        elif nominator.role != UserRole.EMPLOYEE.value: # Manager or Dept Head
            # Add automatic approval ONLY for the nominator's own level
            required_levels = self._get_required_approval_levels(award_type)
            nominator_level = nominator.role # e.g., "MANAGER" or "DEPT_HEAD"
            
            # Only auto-approve the nominator's own level (not preceding levels)
            approval = AwardApproval(
                award_id=award.id,
                approver_id=nominator_id,
                approval_level=nominator_level,
                status=ApprovalStatus.APPROVED.value,
                comments=f"Auto-approved by {nominator_level} nominator"
            )
            self.db.add(approval)
            current_approvals.append(nominator_level)
            
            # Check if all approvals are now complete due to nominator's role
            if self._all_approvals_complete(required_levels, current_approvals):
                award.status = AwardStatus.APPROVED.value
                self.points_service.award_points(
                    user_id=award.nominee_id,
                    points=award.points_awarded,
                    source_type=ReferenceType.AWARD.value,
                    source_id=award.id
                )
                self.notification_service.create_notification(
                    user_id=award.nominee_id,
                    message=f"Congratulations! Your {award.award_type.name} award has been fully approved. {award.points_awarded} points awarded!",
                    source_type=ReferenceType.AWARD.value,
                    source_id=award.id
                )
            else:
                # Notify next approver if more approvals are needed
                next_level = self._get_next_required_level(required_levels, current_approvals)
                if next_level:
                    # Logic to notify the next approver (e.g., Dept Head if Manager approved)
                    pass # Placeholder for actual notification logic

        self.db.commit()
        self.db.refresh(award)

        # 4. Create notification for nominee (if not already approved)
        if award.status == AwardStatus.PENDING.value:
            self.notification_service.create_notification(
                user_id=nominee_id,
                message=f"You have been nominated for a {award_type.name} award by {nominator.name}!",
                source_type=ReferenceType.AWARD.value,
                source_id=award.id
            )
        
        # 5. Create notification for manager (if nominee has a manager and award is pending)
        if award.status == AwardStatus.PENDING.value and award.nominee.manager_id:
            self.notification_service.create_notification(
                user_id=award.nominee.manager_id,
                message=f"New Award Nomination: {award.nominee.name} has been nominated for {award_type.name}.",
                source_type=ReferenceType.AWARD.value,
                source_id=award.id
            )

        if award.status != 'PENDING':
            award.next_required_level = None
        else:
            required_levels = self._get_required_approval_levels(award_type)
            completed_levels = self._get_existing_approvals(award.id)
            award.next_required_level = self._get_next_required_level(required_levels, completed_levels)

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
        required_levels = [lvl.strip().upper() for lvl in self._get_required_approval_levels(award.award_type)]
        
        if not required_levels:
            # No workflow defined, default to single approval
            required_levels = [approval_level]
        
        # 2. Check if this approval level is required and not already approved
        existing_approvals = self._get_existing_approvals(award_id)
        
        approval_level = str(approval_level).strip().upper()
        if approval_level in existing_approvals:
            raise HTTPException(
                status_code=400, 
                detail=f"{approval_level} has already approved this nomination"
            )
        
        # 3. Check if this is the next required approval level
        next_required_level = self._get_next_required_level(required_levels, existing_approvals)
        
        if approval_level != next_required_level:
            # Include debug details to help diagnose ordering issues
            raise HTTPException(
                status_code=400,
                detail=f"Approval must be done in order. Next required level: {next_required_level}. Current completed: {existing_approvals}"
            )
        
        # 4. Create approval record
        approval = AwardApproval(
            award_id=award_id,
            approver_id=approver_id,
            approval_level=approval_level,
            status=ApprovalStatus.APPROVED.value,
            comments=f"Approved by {approval_level}"
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
        
        if award.status != 'PENDING':
            award.next_required_level = None
        else:
            required_levels = self._get_required_approval_levels(award.award_type)
            completed_levels = self._get_existing_approvals(award.id)
            award.next_required_level = self._get_next_required_level(required_levels, completed_levels)
            
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
            comments=f"Rejected by {approval_level}"
        )
        self.db.add(approval)

        # 2. Update award status to REJECTED
        award.status = AwardStatus.REJECTED.value
        
        self.db.commit()
        self.db.refresh(award)
        award.next_required_level = None
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
        
        # By default, only HR (and optionally Dept Head) may view all nominations.
        # Other roles (Employee, Manager) see only nominations they are part of (nominator or nominee).
        if role in [UserRole.HR.value, UserRole.ADMIN.value, UserRole.DEPT_HEAD.value]:
            # HR and Dept Head can see all nominations
            pass
        else:
            # Employees and Managers see only nominations they made or received
            query = query.filter((Award.nominator_id == user_id) | (Award.nominee_id == user_id))

        if status_filter:
            query = query.filter(Award.status == status_filter)

        awards = query.order_by(Award.created_at.desc()).offset(skip).limit(limit).all()
        
        # Attach next_required_level to each award for the API response
        for award in awards:
            if award.status != 'PENDING':
                award.next_required_level = None
                continue
                
            required_levels = self._get_required_approval_levels(award.award_type)
            completed_levels = self._get_existing_approvals(award.id)
            award.next_required_level = self._get_next_required_level(required_levels, completed_levels)
            
        return awards

    def get_nomination(self, award_id: int) -> Optional[Award]:
        """Get specific nomination details."""
        award = self.db.query(Award).filter(Award.id == award_id).first()
        if award:
            if award.status != 'PENDING':
                award.next_required_level = None
            else:
                required_levels = self._get_required_approval_levels(award.award_type)
                completed_levels = self._get_existing_approvals(award.id)
                award.next_required_level = self._get_next_required_level(required_levels, completed_levels)
        return award

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
        # Prevent duplicate award_key or name (case-insensitive)
        from sqlalchemy import func
        existing_key = self.db.query(AwardType).filter(AwardType.award_key == award_key).first()
        if existing_key:
            raise HTTPException(status_code=400, detail="Award type with this key already exists")

        existing_name = self.db.query(AwardType).filter(func.lower(AwardType.name) == name.lower()).first()
        if existing_name:
            raise HTTPException(status_code=400, detail="Award type with this name already exists")

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
            # Default workflow: MANAGER -> DEPT_HEAD -> HR
            return ["MANAGER", "DEPT_HEAD", "HR"]
        
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
        
        # Normalize stored approval level strings to uppercase for reliable comparisons
        return [str(approval.approval_level).strip().upper() for approval in approvals]
    
    def _get_next_required_level(self, required_levels: List[str], completed_levels: List[str]) -> Optional[str]:
        """
        Determine the next required approval level.
        
        Args:
            required_levels: All required approval levels in order
            completed_levels: Levels that have already approved
            
        Returns:
            Next required approval level or None if all complete
        """
        # If there are no required levels, nothing to do
        if not required_levels:
            return None

        # Normalize completed levels and consider only those present in required_levels
        completed_set = {str(l).strip().upper() for l in completed_levels if l}

        # Find the highest-positioned completed level in the ordered required_levels
        max_index = -1
        for idx, level in enumerate(required_levels):
            if level in completed_set:
                max_index = idx

        # If none of the required levels have been completed, the next required is the first
        if max_index == -1:
            return required_levels[0]

        # If the highest completed level is the last in the workflow, there is no next level
        if max_index + 1 >= len(required_levels):
            return None

        # Otherwise, return the level immediately following the highest completed one
        return required_levels[max_index + 1]
    
    def _all_approvals_complete(self, required_levels: List[str], completed_levels: List[str]) -> bool:
        """
        Check if all required approvals have been obtained.
        
        Args:
            required_levels: All required approval levels
            completed_levels: Levels that have approved
            
        Returns:
            True if all required approvals are complete
        """
        if not required_levels:
            return True

        # Normalize completed levels
        completed_set = {str(l).strip().upper() for l in completed_levels if l}

        # Find highest-positioned completed level within the required_levels order
        max_index = -1
        for idx, level in enumerate(required_levels):
            if level in completed_set:
                max_index = idx

        # If none completed, require all required_levels
        start_idx = 0 if max_index == -1 else max_index

        # Effective required levels start from the highest completed level (inclusive)
        effective_required = required_levels[start_idx:]

        return all(level in completed_set for level in effective_required)
    
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
