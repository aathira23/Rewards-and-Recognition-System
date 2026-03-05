"""
Pending-approvals reminder job.

Finds managers / dept-heads / HR users who have un-actioned award nominations
or points-conversion requests, and sends them a reminder email.

PRODUCTION: run daily via cron or scheduler:
    0 9 * * 1-5 /path/to/python -m app.jobs.pending_approvals_job

Usage (manual):
    python -m app.jobs.pending_approvals_job
"""
from __future__ import annotations

import logging
from collections import defaultdict

from sqlalchemy import func
from sqlalchemy.orm import joinedload

from app.core.database import SessionLocal
from app.jobs.email_worker import enqueue_email
from app.models.awards import Award
from app.models.award_approvals import AwardApproval
from app.models.award_types import AwardType
from app.models.points_conversion import PointsConversion
from app.models.users import User
from app.utils.enums import AwardStatus, ConversionStatus, EmailEventType, UserRole

logger = logging.getLogger(__name__)


# ── Helpers (lightweight copies of AwardsService internals) ──────────────

def _get_required_levels(award_type: AwardType) -> list[str]:
    if award_type.approval_chain:
        return [lvl.strip().upper() for lvl in award_type.approval_chain.split(",")]
    return ["MANAGER", "DEPT_HEAD", "HR"]


def _get_existing_approvals(db, award_id: int) -> list[str]:
    rows = (
        db.query(AwardApproval.approval_level)
        .filter(
            AwardApproval.award_id == award_id,
            AwardApproval.status == "APPROVED",
        )
        .all()
    )
    return [r[0].upper() for r in rows]


def _get_next_required_level(required: list[str], completed: list[str]) -> str | None:
    for lvl in required:
        if lvl not in completed:
            return lvl
    return None


_LEVEL_TO_ROLES: dict[str, list[str]] = {
    "MANAGER":   [UserRole.MANAGER.value],
    "DEPT_HEAD": [UserRole.DEPT_HEAD.value],
    "HR":        [UserRole.HR.value, UserRole.ADMIN.value],
}


def send_pending_approval_reminders() -> int:
    """Send reminder emails to approvers with pending items.

    Returns the number of reminder emails enqueued.
    """
    db = SessionLocal()
    try:
        count = 0

        # ── 1. Pending award nominations (use approval chain) ────────────
        pending_awards = (
            db.query(Award)
            .options(joinedload(Award.award_type))
            .filter(Award.status == AwardStatus.PENDING.value)
            .all()
        )

        approver_award_counts: dict[int, int] = defaultdict(int)

        for award in pending_awards:
            required = _get_required_levels(award.award_type)
            completed = _get_existing_approvals(db, award.id)
            next_level = _get_next_required_level(required, completed)
            if not next_level:
                continue

            if next_level == "MANAGER":
                nominee = db.query(User).filter(User.id == award.nominee_id).first()
                if nominee and nominee.manager_id:
                    approver_award_counts[nominee.manager_id] += 1
            else:
                roles = _LEVEL_TO_ROLES.get(next_level, [])
                if roles:
                    users = db.query(User).filter(User.role.in_(roles)).all()
                    for u in users:
                        approver_award_counts[u.id] += 1

        # ── 2. Pending conversion requests (HR/Admin approve) ────────────
        pending_conversions_count = (
            db.query(func.count(PointsConversion.id))
            .filter(PointsConversion.status == ConversionStatus.PENDING.value)
            .scalar()
        ) or 0

        hr_user_ids: set[int] = set()
        if pending_conversions_count > 0:
            hr_users = (
                db.query(User)
                .filter(User.role.in_([UserRole.HR.value, UserRole.ADMIN.value]))
                .all()
            )
            hr_user_ids = {u.id for u in hr_users}

        # ── 3. Merge and send one reminder per approver ──────────────────
        all_approver_ids = set(approver_award_counts.keys()) | hr_user_ids

        for approver_id in all_approver_ids:
            award_count = approver_award_counts.get(approver_id, 0)
            conv_count = pending_conversions_count if approver_id in hr_user_ids else 0
            total = award_count + conv_count

            if total == 0:
                continue

            enqueue_email(
                event_type=EmailEventType.PENDING_APPROVALS_REMINDER,
                recipient_user_id=approver_id,
                context={
                    "pending_count": total,
                    "pending_awards": award_count,
                    "pending_conversions": conv_count,
                },
            )
            count += 1

        logger.info("Pending approval reminders sent: %d", count)
        return count

    except Exception:
        logger.exception("Error sending pending approval reminders")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    result = send_pending_approval_reminders()
    print(f"✅ Sent {result} pending-approval reminder(s).")
