"""
Awards service - Business logic for award nominations and approvals.
"""
from __future__ import annotations

from sqlalchemy.orm import Session
from typing import Optional, List, Dict, Any
from fastapi import HTTPException

from app.models.award_types import AwardType
from app.repository.awards_repository import AwardsRepository
from app.services.points_service import PointsService
from app.services.notification_service import NotificationService
from app.services.recognition_service import RecognitionService
from app.utils.enums import AwardStatus, ApprovalStatus, ReferenceType, UserRole

class AwardsService:
    """Service for managing award nominations and approvals."""

    def __init__(self, db: Session, token: Optional[str] = None):
        self.db = db
        self._token = token
        self.repository = AwardsRepository(db)
        self.points_service = PointsService(db)
        self.notification_service = NotificationService(db, token=self._token)
        self.recognition_service = RecognitionService(db)

    def _get_user_name(self, user_id: int) -> str:
        """Resolve user name via User Service (with cache), fallback to local DB."""
        if self._token:
            from app.services.user_profiles_client import get_user_profile
            profile = get_user_profile(user_id, self._token)
            if profile:
                return profile.name
        local = self.repository.get_user_by_id(user_id)
        return local.name if local else f"User #{user_id}"

    def _get_user_names_batch(self, user_ids: set) -> Dict[int, str]:
        """Batch-resolve user names via User Service, fallback to local DB."""
        if not user_ids:
            return {}
        if self._token:
            from app.services.user_profiles_client import get_users_batch
            profiles = get_users_batch(list(user_ids), self._token)
            return {uid: p.name for uid, p in profiles.items()}
        from app.models.users import User
        rows = self.db.query(User).filter(User.id.in_(user_ids)).all()
        return {u.id: u.name for u in rows}

    def nominate_for_award(
        self,
        nominator_id: int,
        nominee_id: int,
        award_type_id: int,
        citation: Optional[str] = None
    ) -> Award:
        """
        Create an award nomination.
        - HR nominations are auto-approved.
        - Managers and Dept Heads' own level is marked as approved automatically.
        - Employees can nominate; their nominations follow the full workflow.
        """
        nominator = self.repository.get_user_by_id(nominator_id)
        if not nominator:
            raise HTTPException(status_code=404, detail="Nominator not found.")
        nominator_name = self._get_user_name(nominator_id)

        # 1. Verify eligibility rules
        if nominator_id == nominee_id:
            raise HTTPException(status_code=400, detail="You cannot nominate yourself for an award.")

        award_type = self.repository.get_award_type_by_id(award_type_id, active_only=True)
        if not award_type:
            raise HTTPException(status_code=404, detail="Award type not found or inactive.")

        # Prevent duplicate pending nominations for same nominee and award type
        existing_nom = self.repository.find_pending_nomination(nominee_id, award_type_id)
        if existing_nom:
            raise HTTPException(status_code=400, detail="A pending nomination for this nominee and award type already exists.")

        # --- Eligibility checks based on nominator role ---
        # Validate nominee exists via User Service first, then local DB
        nominee_name = None
        nominee_dept_id = None
        nominee_manager_id = None
        if self._token:
            from app.services.user_profiles_client import get_user_profile
            nominee_profile = get_user_profile(nominee_id, self._token)
            if nominee_profile:
                nominee_name = nominee_profile.name
                nominee_dept_id = nominee_profile.department_id
        if not nominee_name:
            nominee_local = self.repository.get_user_by_id(nominee_id)
            if not nominee_local:
                raise HTTPException(status_code=404, detail="Nominee not found.")
            nominee_name = nominee_local.name
            nominee_dept_id = nominee_local.department_id
            nominee_manager_id = getattr(nominee_local, 'manager_id', None)

        # Managers may only nominate their direct reports (skip if manager_id unavailable)
        if nominator.role == UserRole.MANAGER.value and nominee_manager_id is not None:
            if nominee_manager_id != nominator_id:
                raise HTTPException(status_code=403, detail="Managers can only nominate their direct reports.")

        # Dept Heads may only nominate employees within their department
        if nominator.role == UserRole.DEPT_HEAD.value:
            if nominee_dept_id != nominator.department_id:
                raise HTTPException(status_code=403, detail="Dept Heads can only nominate employees within their department.")

        # HR may nominate anyone; Employees follow existing rules (no extra restriction)

        # 1c. Role-based Authorization Check (Ensures consistency with the listing API)
        if not self._is_user_eligible_to_nominate(nominator.role or "EMPLOYEE", award_type):
            raise HTTPException(
                status_code=403,
                detail=f"Your role ({nominator.role or 'EMPLOYEE'}) is not authorized to nominate for the '{award_type.name}' award."
            )

        # 2. Create award record with PENDING status
        award = self.repository.create_award(
            nominee_id=nominee_id,
            nominator_id=nominator_id,
            award_type_id=award_type_id,
            status=AwardStatus.PENDING.value,
            points=award_type.points,
            citation=citation,
        )

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
                self.repository.create_approval(
                    award_id=award.id,
                    approver_id=nominator_id,
                    approval_level=level,
                    status=ApprovalStatus.APPROVED.value,
                    comments="Auto-approved by HR nominator",
                )
                current_approvals.append(level)

            # Create feed entry for Award
            self.recognition_service.create_feed_entry(
                actor_id=award.nominator_id,
                receiver_id=award.nominee_id,
                source_type=ReferenceType.AWARD.value,
                source_id=award.id,
                message=f"Honored with the {award.award_type.name} Award! 🎉"
            )

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
                source_id=award.id,
                email_event_type="AWARD_APPROVED",
                email_context={
                    "item_type": f"{award.award_type.name} Award",
                    "status": "Approved",
                    "approver_name": "HR",
                    "comment": "",
                    "points_amount": award.points_awarded,
                    "details_url": "",
                },
            )

        elif nominator.role != UserRole.EMPLOYEE.value: # Manager or Dept Head
            # Add automatic approval ONLY for the nominator's own level
            required_levels = self._get_required_approval_levels(award_type)
            nominator_level = nominator.role # e.g., "MANAGER" or "DEPT_HEAD"

            # Only auto-approve the nominator's own level (not preceding levels)
            self.repository.create_approval(
                award_id=award.id,
                approver_id=nominator_id,
                approval_level=nominator_level,
                status=ApprovalStatus.APPROVED.value,
                comments=f"Auto-approved by {nominator_level} nominator",
            )
            current_approvals.append(nominator_level)

            # Check if all approvals are now complete due to nominator's role
            if self._all_approvals_complete(required_levels, current_approvals):
                award.status = AwardStatus.APPROVED.value

                # Create feed entry for Award
                self.recognition_service.create_feed_entry(
                    actor_id=award.nominator_id,
                    receiver_id=award.nominee_id,
                    source_type=ReferenceType.AWARD.value,
                    source_id=award.id,
                    message=f"Honored with the {award.award_type.name} Award! 🎉"
                )

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
                    source_id=award.id,
                    email_event_type="AWARD_APPROVED",
                    email_context={
                        "item_type": f"{award.award_type.name} Award",
                        "status": "Approved",
                        "approver_name": nominator_name,
                        "comment": "",
                        "points_amount": award.points_awarded,
                        "details_url": "",
                    },
                )
            else:
                # Notify next approver in the nominee's approval chain
                next_level = self._get_next_required_level(required_levels, current_approvals)
                if next_level:
                    self._notify_next_approver(award, next_level)

        self.repository.commit()
        self.repository.refresh(award)

        # 4. Create notification for nominee (if not already approved)
        if award.status == AwardStatus.PENDING.value:
            self.notification_service.create_notification(
                user_id=nominee_id,
                message=f"You have been nominated for a {award_type.name} award by {nominator_name}!",
                source_type=ReferenceType.AWARD.value,
                source_id=award.id,
                email_event_type="NOMINATION_SUBMITTED",
                email_context={
                    "item_type": f"{award_type.name} Award",
                    "status": "Submitted",
                    "approver_name": nominator_name,
                    "comment": "",
                    "details_url": "",
                },
            )

        # 5. Notify the next required approver in the nominee's department chain
        if award.status == AwardStatus.PENDING.value:
            required_levels_now = self._get_required_approval_levels(award_type)
            completed_levels_now = self.repository.get_approved_levels(award.id)
            next_level_now = self._get_next_required_level(required_levels_now, completed_levels_now)
            if next_level_now:
                self._notify_next_approver(award, next_level_now)

        if award.status != 'PENDING':
            award.next_required_level = None
        else:
            required_levels = self._get_required_approval_levels(award_type)
            completed_levels = self.repository.get_approved_levels(award.id)
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
        award = self.repository.get_by_id(award_id)
        if not award:
            raise HTTPException(status_code=404, detail="Award nomination not found.")

        if award.status != AwardStatus.PENDING.value:
            raise HTTPException(status_code=400, detail=f"Award is already {award.status}")

        # 0. Prevent self-approval
        if award.nominee_id == approver_id:
            raise HTTPException(
                status_code=403,
                detail="You cannot approve your own award nomination."
            )

        # 1. Get required approval workflow from award type
        required_levels = [lvl.strip().upper() for lvl in self._get_required_approval_levels(award.award_type)]

        if not required_levels:
            # No workflow defined, default to single approval
            required_levels = [approval_level]

        # 2. Check if this approval level is required and not already approved
        existing_approvals = self.repository.get_approved_levels(award_id)

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

        # 3b. For MANAGER-level approval, enforce that only the nominee's direct manager
        #     may approve — prevents any random manager from acting on the nomination.
        if approval_level == 'MANAGER':
            nominee_local = self.repository.get_user_by_id(award.nominee_id)
            if nominee_local and getattr(nominee_local, 'manager_id', None) is not None:
                if nominee_local.manager_id != approver_id:
                    raise HTTPException(
                        status_code=403,
                        detail="Only the nominee's direct manager can approve at the MANAGER level."
                    )

        # 3c. For DEPT_HEAD-level approval, enforce that only the nominee's dept head
        #     may approve — prevents the nominator's dept head from acting on cross-dept
        #     nominations.
        if approval_level == 'DEPT_HEAD':
            nominee_dept_id = None
            if self._token:
                from app.services.user_profiles_client import get_user_profile
                np = get_user_profile(award.nominee_id, self._token)
                if np:
                    nominee_dept_id = np.department_id
            if nominee_dept_id is None:
                nominee_local = self.repository.get_user_by_id(award.nominee_id)
                if nominee_local:
                    nominee_dept_id = nominee_local.department_id
            if nominee_dept_id:
                nominee_dept_head = self.repository.get_dept_head(nominee_dept_id)
                if nominee_dept_head and nominee_dept_head.id != approver_id:
                    raise HTTPException(
                        status_code=403,
                        detail="Only the nominee's department head can approve at the DEPT_HEAD level."
                    )

        # 4. Create approval record
        self.repository.create_approval(
            award_id=award_id,
            approver_id=approver_id,
            approval_level=approval_level,
            status=ApprovalStatus.APPROVED.value,
            comments=comments if comments else f"Approved by {approval_level}",
        )

        # 5. Check if all required approvals are now complete
        all_approvals = existing_approvals + [approval_level]

        if self._all_approvals_complete(required_levels, all_approvals):
            # All approvals obtained - mark as APPROVED and award points
            award.status = AwardStatus.APPROVED.value

            # Create feed entry for Award
            self.recognition_service.create_feed_entry(
                actor_id=award.nominator_id,
                receiver_id=award.nominee_id,
                source_type=ReferenceType.AWARD.value,
                source_id=award.id,
                message=f"Honored with the {award.award_type.name} Award! 🎉"
            )

            # Award points to nominee
            self.points_service.award_points(
                user_id=award.nominee_id,
                points=award.points_awarded,
                source_type=ReferenceType.AWARD.value,
                source_id=award.id
            )

            # Notify nominee (with email)
            approver_name = self._get_user_name(approver_id)
            self.notification_service.create_notification(
                user_id=award.nominee_id,
                message=f"Congratulations! Your {award.award_type.name} award has been fully approved. {award.points_awarded} points awarded!",
                source_type=ReferenceType.AWARD.value,
                source_id=award.id,
                email_event_type="AWARD_APPROVED",
                email_context={
                    "item_type": f"{award.award_type.name} Award",
                    "status": "Approved",
                    "approver_name": approver_name,
                    "comment": comments or "",
                    "points_amount": award.points_awarded,
                    "details_url": "",
                },
            )
        else:
            # More approvals needed - notify the next approver in the nominee's chain
            next_level = self._get_next_required_level(required_levels, all_approvals)
            if next_level:
                self._notify_next_approver(award, next_level)

        self.repository.commit()
        self.repository.refresh(award)

        if award.status != 'PENDING':
            award.next_required_level = None
        else:
            required_levels = self._get_required_approval_levels(award.award_type)
            completed_levels = self.repository.get_approved_levels(award.id)
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
        award = self.repository.get_by_id(award_id)
        if not award:
            raise HTTPException(status_code=404, detail="Award nomination not found.")

        if award.status != AwardStatus.PENDING.value:
            raise HTTPException(status_code=400, detail=f"Award is already {award.status}")

        # 0. Prevent self-action (rejecting own award)
        if award.nominee_id == approver_id:
            raise HTTPException(
                status_code=403,
                detail="You cannot reject your own award nomination."
            )

        # For MANAGER-level rejection, enforce that only the nominee's direct manager may reject.
        if approval_level.upper() == 'MANAGER':
            nominee_local = self.repository.get_user_by_id(award.nominee_id)
            if nominee_local and getattr(nominee_local, 'manager_id', None) is not None:
                if nominee_local.manager_id != approver_id:
                    raise HTTPException(
                        status_code=403,
                        detail="Only the nominee's direct manager can reject at the MANAGER level."
                    )

        # 1. Create approval record with REJECTED status
        self.repository.create_approval(
            award_id=award_id,
            approver_id=approver_id,
            approval_level=approval_level,
            status=ApprovalStatus.REJECTED.value,
            comments=comments if comments else None,
        )

        # 2. Update award status to REJECTED
        award.status = AwardStatus.REJECTED.value

        # 3. Notify nominee
        self.notification_service.create_notification(
            user_id=award.nominee_id,
            message=f"Update on your nomination: The {award.award_type.name} award nomination has not been approved at this time.",
            source_type=ReferenceType.AWARD.value,
            source_id=award.id,
            email_event_type="AWARD_REJECTED",
            email_context={
                "item_type": f"{award.award_type.name} Award",
                "status": "Not Approved",
                "approver_name": approval_level,
                "comment": comments or "",
                "details_url": "",
            },
        )

        # 4. Notify nominator (the person who submitted it)
        approver_name = self._get_user_name(approver_id)
        nominee_name = self._get_user_name(award.nominee_id)
        level_label = {'MANAGER': 'Manager', 'DEPT_HEAD': 'Dept Head', 'HR': 'HR', 'ADMIN': 'Admin'}.get(approval_level.upper(), approval_level.replace('_', ' ').title())
        self.notification_service.create_notification(
            user_id=award.nominator_id,
            message=f"Your nomination for {nominee_name} ({award.award_type.name}) was rejected by your {level_label} {approver_name}. Reason: {comments}",
            source_type=ReferenceType.AWARD.value,
            source_id=award.id,
            email_event_type="AWARD_REJECTED",
            email_context={
                "item_type": f"{award.award_type.name} Award",
                "status": "Not Approved",
                "approver_name": approver_name,
                "comment": comments or "",
                "details_url": "",
            },
        )

        self.repository.commit()
        self.repository.refresh(award)
        award.next_required_level = None
        return award

    def get_nominations(
        self,
        user_id: int,
        role: str,
        status_filter: Optional[str] = None,
        page: int = 1,
        per_page: int = 20
    ):
        """Get award nominations based on user role. Returns (total, items)."""
        from app.utils.constants import clamp_pagination
        page, per_page, skip = clamp_pagination(page, per_page)

        # Visibility rules:
        
        # 1. Identify award IDs where the user is directly involved
        # (Nominator, Nominee, or someone who has already provided an approval record)
        visible_ids = self.repository.get_involved_award_ids(user_id)
        
        # 2. Check PENDING awards to determine if it is currently the user's turn
        # We only check awards that aren't already identified as visible
        pending_candidates = self.repository.get_pending_awards_not_in(visible_ids)
        
        for award in pending_candidates:
            req_levels = self._get_required_approval_levels(award.award_type)
            # Find completed levels from existing approvals
            comp_levels = [
                str(ap.approval_level).strip().upper() 
                for ap in award.approvals 
                if ap.status == ApprovalStatus.APPROVED.value
            ]
            next_lvl = self._get_next_required_level(req_levels, comp_levels)
            
            if next_lvl and next_lvl.upper() == role.upper():
                # Resolve nominee info: prefer User Service, fallback to local
                nominee_dept_id = None
                nominee_manager_id = None
                if self._token:
                    from app.services.user_profiles_client import get_user_profile
                    np = get_user_profile(award.nominee_id, self._token)
                    if np:
                        nominee_dept_id = np.department_id
                nominee_local = self.repository.get_user_by_id(award.nominee_id)
                if nominee_local:
                    if nominee_dept_id is None:
                        nominee_dept_id = nominee_local.department_id
                    nominee_manager_id = getattr(nominee_local, 'manager_id', None)

                # For MANAGER role, only the nominee's direct manager may see it
                if next_lvl.upper() == 'MANAGER':
                    if nominee_manager_id is not None and nominee_manager_id == user_id:
                        visible_ids.add(award.id)
                    elif nominee_manager_id is None:
                        # manager_id unknown — allow visibility so it's not hidden
                        visible_ids.add(award.id)
                elif next_lvl.upper() == 'DEPT_HEAD':
                    # Only the nominee's own dept head may see it
                    nominee_dept_head = (
                        self.repository.get_dept_head(nominee_dept_id)
                        if nominee_dept_id else None
                    )
                    if nominee_dept_head and nominee_dept_head.id == user_id:
                        visible_ids.add(award.id)
                else:
                    visible_ids.add(award.id)

        # 3. Restrict final query to visible IDs
        total, awards = self.repository.get_filtered_awards(visible_ids, status_filter, skip, per_page)

        # Attach next_required_level to each award for the API response
        for award in awards:
            if award.status != 'PENDING':
                award.next_required_level = None
                continue

            required_levels = self._get_required_approval_levels(award.award_type)
            completed_levels = self.repository.get_approved_levels(award.id)
            award.next_required_level = self._get_next_required_level(required_levels, completed_levels)

        # Attach latest human reviewer comment (single batched query, no N+1)
        if awards:
            award_ids = [a.id for a in awards]
            all_aps = self.repository.get_approvals_for_awards(award_ids)
            latest_map: Dict[int, AwardApproval] = {}
            for ap in all_aps:
                if ap.award_id not in latest_map:
                    latest_map[ap.award_id] = ap
            _approver_ids = {ap.approver_id for ap in latest_map.values() if ap.approver_id}
            _approvers_map = self._get_user_names_batch(_approver_ids)
            for award in awards:
                ap = latest_map.get(award.id)
                award.reviewer_comment = None
                award.reviewer_name = None
                award.reviewer_level = None
                if not ap:
                    continue
                c = ap.comments or ''
                cl = c.lower()
                # Skip system-generated scaffolding comments
                is_system = (
                    cl.startswith('auto-approved by')
                    or cl.startswith('approved by ')
                    or cl.startswith('rejected by ')
                )
                if is_system:
                    continue
                # Human action — attach reviewer info
                award.reviewer_name = _approvers_map.get(ap.approver_id) if ap.approver_id else None
                award.reviewer_level = ap.approval_level
                if c:
                    award.reviewer_comment = c

        return total, awards

    def get_nomination(self, award_id: int):
        """Get specific nomination details."""
        award = self.repository.get_by_id(award_id)
        if award:
            if award.status != 'PENDING':
                award.next_required_level = None
            else:
                required_levels = self._get_required_approval_levels(award.award_type)
                completed_levels = self.repository.get_approved_levels(award.id)
                award.next_required_level = self._get_next_required_level(required_levels, completed_levels)
        return award

    def get_my_approval_history(self, user_id: int) -> List[dict]:
        """
        Return all nominations where the current user has an AwardApproval record.
        Reads directly from award_approvals joined with awards — no filtering
        on nomination status so the user sees both in-progress and finalised ones.
        """
        approvals = self.repository.get_approvals_by_user(user_id)
        # Batch-fetch user names for nominees and nominators
        _user_id_set = {ap.award.nominee_id for ap in approvals if ap.award} | {ap.award.nominator_id for ap in approvals if ap.award}
        _users_map = self._get_user_names_batch(_user_id_set)
        result = []
        for ap in approvals:
            award = ap.award
            if not award:
                continue
            result.append({
                'my_action':          ap.status,
                'my_action_at':       ap.created_at,
                'my_level':           ap.approval_level,
                'my_comments':        ap.comments,
                'nomination_id':      award.id,
                'nominee_id':         award.nominee_id,
                'nominator_id':       award.nominator_id,
                'award_type_name':    award.award_type.name if award.award_type else '',
                'points_awarded':     award.points_awarded,
                'citation':           award.citation,
                'nomination_status':  award.status,
                'nominee_name':       _users_map.get(award.nominee_id, f'User #{award.nominee_id}'),
                'nominator_name':     _users_map.get(award.nominator_id, f'User #{award.nominator_id}'),
                'created_at':         award.created_at,
            })
        return result

    # Roles allowed to use each eligibility rule
    _ROLE_ELIGIBLE_RULES: Dict[str, List[str]] = {
        UserRole.EMPLOYEE.value:  ['PEER'],
        UserRole.MANAGER.value:   ['PEER', 'MANAGER_ONLY'],
        UserRole.DEPT_HEAD.value: ['PEER', 'MANAGER_ONLY', 'SENIOR_MGMT'],
        UserRole.HR.value:        ['PEER', 'MANAGER_ONLY', 'SENIOR_MGMT'],
        UserRole.ADMIN.value:     ['PEER', 'MANAGER_ONLY', 'SENIOR_MGMT'],
    }

    def get_award_types(
        self,
        active_only: bool = True,
        user_role: Optional[str] = None
    ):
        """Get award types visible to the requesting user's role based on eligibility rules."""
        role_to_check = (user_role or "EMPLOYEE").upper()
        
        # Admin/HR see all
        if role_to_check in (UserRole.HR.value, UserRole.ADMIN.value):
            eligibility_rules = None
        else:
            eligibility_rules = self._ROLE_ELIGIBLE_RULES.get(role_to_check, ['PEER'])
        
        return self.repository.get_award_types(
            active_only=active_only,
            eligibility_rules=eligibility_rules,
        )

    def _is_user_eligible_to_nominate(self, user_role: Optional[str], award_type: AwardType) -> bool:
        """
        Check if the nominator's role is authorized to nominate this award type.
        
        Criteria:
        1. Base eligibility check (PEER vs MANAGER_ONLY, etc.)
        2. HR/ADMIN bypass further checks.
        3. Employees can nominate anything matching their eligibility rules (usually PEER).
        4. Management roles must be present in the approval_workflow for non-PEER awards.
        """
        user_role = user_role.upper()
        
        # 1. Base eligibility check
        allowed_rules = self._ROLE_ELIGIBLE_RULES.get(user_role, ['PEER'])
        if award_type.eligibility_rule not in allowed_rules:
            return False
            
        # 2. Administrative Exception
        if user_role in (UserRole.HR.value, UserRole.ADMIN.value):
            return True
            
        # 3. Employee Exception: Employees initiate but never approve.
        if user_role == UserRole.EMPLOYEE.value:
            return True

        # 4. Management Restriction: For non-PEER awards, check role in workflow
        if award_type.eligibility_rule == 'PEER':
            return True
            
        workflow = self._get_required_approval_levels(award_type)
        return user_role in workflow

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
        existing_key = self.repository.get_award_type_by_key(award_key)
        if existing_key:
            raise HTTPException(status_code=400, detail="Award type with this key already exists")

        existing_name = self.repository.get_award_type_by_name(name)
        if existing_name:
            raise HTTPException(status_code=400, detail="Award type with this name already exists")

        return self.repository.create_award_type(
            award_key=award_key,
            name=name,
            points=points,
            frequency=frequency,
            eligibility_rule=eligibility_rule,
            description=description,
            approval_workflow=approval_workflow,
        )

    def update_award_type(self, type_id: int, updates: Dict[str, Any]):
        """Update an award type."""
        award_type = self.repository.get_award_type_by_id(type_id)
        if not award_type:
            return None

        for field, value in updates.items():
            if value is not None:
                setattr(award_type, field, value)

        return self.repository.save_award_type(award_type)

    # --- Multi-Level Approval Helper Methods ---

    def _notify_next_approver(self, award: Award, next_level: str) -> None:
        """
        Send a pending-approval notification to the correct person based on the
        nominee's department chain, not the nominator's.
        """
        nominee_name = self._get_user_name(award.nominee_id)

        # Resolve nominee's department_id and manager_id
        nominee_dept_id = None
        nominee_manager_id = None
        if self._token:
            from app.services.user_profiles_client import get_user_profile
            np = get_user_profile(award.nominee_id, self._token)
            if np:
                nominee_dept_id = np.department_id
        nominee_local = self.repository.get_user_by_id(award.nominee_id)
        if nominee_local:
            if nominee_dept_id is None:
                nominee_dept_id = nominee_local.department_id
            nominee_manager_id = getattr(nominee_local, 'manager_id', None)

        msg = (
            f"New Award Nomination: {nominee_name} has been nominated for "
            f"{award.award_type.name} and requires your approval."
        )

        if next_level == 'MANAGER':
            if nominee_manager_id:
                self.notification_service.create_notification(
                    user_id=nominee_manager_id,
                    message=msg,
                    source_type=ReferenceType.AWARD.value,
                    source_id=award.id,
                )
        elif next_level == 'DEPT_HEAD':
            dept_head = self.repository.get_dept_head(nominee_dept_id) if nominee_dept_id else None
            if dept_head:
                self.notification_service.create_notification(
                    user_id=dept_head.id,
                    message=msg,
                    source_type=ReferenceType.AWARD.value,
                    source_id=award.id,
                )
        elif next_level in ('HR', 'ADMIN'):
            hr_users = self.repository.get_hr_users()
            for hr_user in hr_users:
                self.notification_service.create_notification(
                    user_id=hr_user.id,
                    message=msg,
                    source_type=ReferenceType.AWARD.value,
                    source_id=award.id,
                )

    def _get_required_approval_levels(self, award_type: AwardType) -> List[str]:
        """
        Get the list of required approval levels from award type.
        
        Returns:
            List of approval levels in order (e.g., ["MANAGER", "DEPT_HEAD", "HR"])
        """
        if not award_type.approval_workflow or not award_type.approval_workflow.strip():
            # Default workflow: MANAGER -> DEPT_HEAD -> HR
            return ["MANAGER", "DEPT_HEAD", "HR"]

        # Parse comma-separated workflow, drop any blank tokens
        levels = [level.strip().upper() for level in award_type.approval_workflow.split(",") if level.strip()]
        return levels if levels else ["MANAGER", "DEPT_HEAD", "HR"]

    def _get_existing_approvals(self, award_id: int) -> List[str]:
        """Get list of approval levels that have already approved this award."""
        return self.repository.get_approved_levels(award_id)

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
        award = self.repository.get_by_id(award_id)
        if not award:
            return None

        required_levels = self._get_required_approval_levels(award.award_type)
        completed_levels = self.repository.get_approved_levels(award_id)
        next_level = self._get_next_required_level(required_levels, completed_levels)

        # Get approval details
        approvals = self.repository.get_approvals_for_award(award_id)
        _approver_ids = {ap.approver_id for ap in approvals if ap.approver_id}
        _approvers_map = self._get_user_names_batch(_approver_ids)

        approval_details = [
            {
                "level": approval.approval_level,
                "approver_id": approval.approver_id,
                "approver_name": _approvers_map.get(approval.approver_id, "Unknown") if approval.approver_id else "Unknown",
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
