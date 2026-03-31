"""
Points service - Business logic for points management, FIFO deductions, and ledger tracking.
Aligned with UI requirements for rich descriptions.
"""
from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional, Tuple
from datetime import date, datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import desc
from cachetools import TTLCache

from app.models.points_ledger import PointsLedger
from app.utils.enums import TransactionType, ReferenceType, WalletType
from app.repository.points_repository import PointsRepository

logger = logging.getLogger(__name__)

# Module-level cache: user_id → aggregates dict.  5 min TTL, up to 5 000 users.
_aggregates_cache: TTLCache = TTLCache(maxsize=5_000, ttl=5 * 60)


class PointsService:
    """Service for managing points, FIFO deductions, and ledger tracking."""

    def __init__(self, db: Session):
        self.db = db
        self.repository = PointsRepository(db)

    def get_employee_wallet(self, user_id: int):
        """Get or create employee wallet."""
        wallet = self.repository.get_employee_wallet(user_id)
        if not wallet:
            wallet = self.repository.create_employee_wallet(user_id)
        return wallet

    def get_user_balance(self, user_id: int) -> int:
        """Get total available points for a user across all non-expired batches."""
        return self.repository.get_available_balance(user_id)

    def get_pending_conversion_points(self, user_id: int) -> int:
        """Get total points locked in pending conversion requests."""
        return self.repository.get_pending_conversion_points(user_id)

    def award_points(
        self,
        user_id: int,
        points: int,
        source_type: str,
        source_id: int,
        expiry_days: int = 365
    ) -> PointsBatch:
        """Award points to a user, create a batch, and update wallet with safety checks."""
        # 1. Check System-Wide Monthly Budget Cap
        from app.services.config_service import ConfigService
        config_service = ConfigService(self.db)
        cap_val = config_service.get_config("SYSTEM MONTHLY BUDGET CAP")

        if cap_val:
            try:
                cap = int(cap_val)
                first_day = date.today().replace(day=1)
                month_total = self.repository.get_month_credits(first_day)

                if month_total + points > cap:
                    available = max(0, cap - month_total)
                    raise ValueError(
                        f"System-wide monthly budget cap reached. "
                        f"Remaining budget: {available}, Requested: {points}"
                    )
            except ValueError as e:
                if "System-wide" in str(e): raise e
                pass

        # 2. If this is a manager->employee transfer, deduct manager budget centrally
        if source_type == ReferenceType.MANAGER_REWARD.value:
            manager_wallet = self.repository.get_manager_wallet(source_id)
            if not manager_wallet or manager_wallet.balance < points:
                raise ValueError(f"Insufficient manager budget. Available: {manager_wallet.balance if manager_wallet else 0}, Requested: {points}")

            manager_wallet.balance -= points
            self.repository.add_ledger_entry(
                points=points,
                transaction_type=TransactionType.DEBIT.value,
                reference_type=ReferenceType.MANAGER_REWARD.value,
                reference_id=user_id,
                source_wallet_id=manager_wallet.id,
            )

        # 2. Proceed with awarding (credit to employee)
        expiry_date = date.today() + timedelta(days=expiry_days)
        batch = self.repository.create_batch(
            user_id=user_id,
            points=points,
            source_type=source_type,
            source_id=source_id,
            expiry_date=expiry_date,
        )

        wallet = self.get_employee_wallet(user_id)
        wallet.balance += points

        self.repository.add_ledger_entry(
            points=points,
            transaction_type=TransactionType.CREDIT.value,
            reference_type=source_type,
            reference_id=source_id,
            target_wallet_id=wallet.id,
        )

        self.repository.commit()
        self.repository.refresh(batch)
        self.invalidate_aggregates(user_id)
        return batch

    def deduct_points(self, user_id: int, points: int, reference_type: str, reference_id: int):
        """Deduct points from user using FIFO (oldest batches first)."""
        if points <= 0:
            return

        wallet = self.get_employee_wallet(user_id)
        if wallet.balance < points:
            raise ValueError(f"Insufficient points. Available: {wallet.balance}, Requested: {points}")

        batches = self.repository.get_fifo_batches(user_id)

        remaining_to_deduct = points
        for batch in batches:
            if remaining_to_deduct <= 0:
                break
            deduction = min(batch.remaining_points, remaining_to_deduct)
            batch.remaining_points -= deduction
            remaining_to_deduct -= deduction

        if remaining_to_deduct > 0:
            raise ValueError("Insufficient non-expired points to complete deduction.")

        wallet.balance -= points
        self.repository.add_ledger_entry(
            points=points,
            transaction_type=TransactionType.DEBIT.value,
            reference_type=reference_type,
            reference_id=reference_id,
            source_wallet_id=wallet.id,
        )
        self.repository.commit()
        self.invalidate_aggregates(user_id)

    def invalidate_aggregates(self, user_id: int) -> None:
        """Remove cached aggregates for a user after a points mutation."""
        _aggregates_cache.pop(user_id, None)

    def get_aggregates(self, user_id: int) -> Dict[str, int]:
        """Compute dashboard metrics: balance, earned, redeemed, pending.

        Results are served from an in-memory TTL cache (5 min) to avoid
        8 separate DB round-trips on every dashboard load.
        """
        if user_id in _aggregates_cache:
            logger.debug("Aggregates cache HIT — user_id=%s", user_id)
            return _aggregates_cache[user_id]

        wallet = self.get_employee_wallet(user_id)
        balance = self.get_user_balance(user_id)

        earned = self.repository.get_total_credits(wallet.id)
        redeemed = self.repository.get_total_redeemed(user_id)
        converted = self.repository.get_total_converted(user_id)
        pending_count = self.repository.get_pending_conversion_count(user_id)

        today = date.today()
        expiring_today = self.repository.get_expiring_points(user_id, today)

        import calendar
        _, last_day = calendar.monthrange(today.year, today.month)
        end_of_month = date(today.year, today.month, last_day)
        expiring_this_month = self.repository.get_expiring_points_range(user_id, today, end_of_month)

        result = {
            "balance": balance,
            "total_earned": int(earned),
            "total_redeemed": int(redeemed),
            "total_converted": int(converted),
            "pending_count": int(expiring_today), # Repurposing as legacy support if needed
            "expiring_soon": int(expiring_today + expiring_this_month),
            "expiring_today": int(expiring_today),
            "expiring_this_month": int(expiring_this_month),
        }
        _aggregates_cache[user_id] = result
        logger.debug("Aggregates cache STORE — user_id=%s", user_id)
        return result

    def fetch_ledger_history(
        self,
        user_id: int,
        category: Optional[str] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        page: int = 1,
        per_page: int = 20,
        wallet_type: str = "EMPLOYEE"
    ) -> Tuple[int, List[Dict[str, Any]]]:
        """Fetch paginated points history including merged pending/expired entries."""
        from app.utils.constants import clamp_pagination
        page, per_page, skip = clamp_pagination(page, per_page)

        if wallet_type == "MANAGER":
             wallet = self.repository.get_manager_wallet(user_id)
        else:
             wallet = self.get_employee_wallet(user_id)

        if not wallet:
            return 0, []

        q = self.repository.get_ledger_query(wallet.id)

        if start_date:
            try:
                start_dt = datetime.strptime(start_date, "%Y-%m-%d")
                q = q.filter(PointsLedger.created_at >= start_dt)
            except ValueError: pass
        if end_date:
            try:
                end_dt = datetime.strptime(end_date, "%Y-%m-%d")
                q = q.filter(PointsLedger.created_at <= end_dt)
            except ValueError: pass

        # ── Expired-only view ──────────────────────────────────
        if category and category.lower() == "expired":
            total, rows = self.repository.get_expired_batches_paginated(user_id, skip, per_page)
            items = [{
                "id": f"batch-{b.id}",
                "date": b.expiry_date.strftime("%d/%m/%Y"),
                "created_at_full": b.expiry_date.isoformat() if b.expiry_date else "",
                "description": f"Points Expired - {b.source_type}",
                "type": "Expired",
                "points": f"-{int(b.remaining_points)}",
                "direction": "Debit",
                "reference_type": "EXPIRY",
            } for b in rows]
            return total, items

        # ── Pending-only view ──────────────────────────────────
        if category and category.lower() == "pending":
            total, pending_rows = self.repository.get_pending_conversions_paginated(user_id, skip, per_page)
            items = []
            for p in pending_rows:
                req_date = p.requested_at.strftime("%d/%m/%Y") if p.requested_at else "Pending"
                req_full = p.requested_at.isoformat() if p.requested_at else ""
                items.append({
                    "id": f"conv-{p.id}",
                    "date": req_date,
                    "created_at_full": req_full,
                    "description": f"Conversion Request: {p.conversion_type}\nAwaiting HR Approval",
                    "type": "Pending",
                    "points": f"-{int(p.points_converted)}",
                    "direction": "Debit",
                    "reference_type": "CONVERSION",
                })
            return total, items

        # ── Category-filtered view (received / spent) ─────────
        if category:
            cat = category.lower()
            if cat == "received":
                q = q.filter(PointsLedger.transaction_type == TransactionType.CREDIT.value)
            elif cat == "spent":
                q = q.filter(PointsLedger.transaction_type == TransactionType.DEBIT.value)

        # ── Count & fetch page from ledger ─────────────────────
        ledger_total = q.count()

        # Count extra items (expired batches + pending conversions) for "all" view
        extra_expired_count = 0
        extra_pending_count = 0
        if not category and wallet_type == "EMPLOYEE":
            _, expired_all = self.repository.get_expired_batches_paginated(user_id, 0, 999999)
            extra_expired_count = len(expired_all)
            extra_pending_count = self.repository.get_pending_conversion_count(user_id)

        grand_total = ledger_total + extra_expired_count + extra_pending_count

        # For "all" view, pending + expired are prepended conceptually.
        # We put them on page 1, then ledger rows fill the remaining space.
        items: list = []
        if not category and wallet_type == "EMPLOYEE":
            # Extra items live in virtual positions 0..(extra_count-1)
            extra_count = extra_pending_count + extra_expired_count
            if skip < extra_count:
                # We need some extra items on this page
                extra_needed = min(per_page, extra_count - skip)
                # Collect pending first, then expired
                all_extras = []
                if extra_pending_count > 0:
                    pending_rows = self.repository.get_pending_conversions_all(user_id)
                    for p in pending_rows:
                        req_date = p.requested_at.strftime("%d/%m/%Y") if p.requested_at else "Pending"
                        req_full = p.requested_at.isoformat() if p.requested_at else ""
                        all_extras.append({
                            "id": f"conv-{p.id}",
                            "date": req_date,
                            "created_at_full": req_full,
                            "description": f"Conversion Request: {p.conversion_type}\nAwaiting HR Approval",
                            "type": "Pending",
                            "points": f"-{int(p.points_converted)}",
                            "direction": "Debit",
                            "reference_type": "CONVERSION",
                        })
                if extra_expired_count > 0:
                    expired_batches = self.repository.get_expired_batches(user_id)
                    for b in expired_batches:
                        all_extras.append({
                            "id": f"batch-{b.id}",
                            "date": b.expiry_date.strftime("%d/%m/%Y"),
                            "created_at_full": b.expiry_date.isoformat() if b.expiry_date else "",
                            "description": f"Points Expired - {b.source_type}",
                            "type": "Expired",
                            "points": f"-{int(b.remaining_points)}",
                            "direction": "Debit",
                            "reference_type": "EXPIRY",
                        })
                items = all_extras[skip:skip + extra_needed]
                # How many ledger rows still fit on this page?
                ledger_slots = per_page - len(items)
                if ledger_slots > 0:
                    ledger_rows = q.order_by(desc(PointsLedger.created_at)).limit(ledger_slots).all()
                    items.extend([self._map_ledger_row(r, wallet.id) for r in ledger_rows])
            else:
                # Past the extras - pure ledger rows
                ledger_skip = skip - extra_count
                ledger_rows = q.order_by(desc(PointsLedger.created_at)).offset(ledger_skip).limit(per_page).all()
                items = [self._map_ledger_row(r, wallet.id) for r in ledger_rows]
        else:
            rows = q.order_by(desc(PointsLedger.created_at)).offset(skip).limit(per_page).all()
            items = [self._map_ledger_row(r, wallet.id) for r in rows]

        return grand_total, items

    def _map_ledger_row(self, row: PointsLedger, wallet_id: int) -> Dict[str, Any]:
        is_credit = row.target_wallet_id == wallet_id
        points = int(row.points)
        description, type_badge = self._enrich_description(row, is_credit)
        return {
            "id": row.id,
            "date": row.created_at.strftime("%d/%m/%Y") if row.created_at else "",
            "created_at_full": row.created_at.isoformat() if row.created_at else "",
            "description": description,
            "type": type_badge,
            "points": f"+{points}" if is_credit else f"-{points}",
            "direction": "Credit" if is_credit else "Debit",
            "reference_type": (row.reference_type or "").upper(),
        }

    def _enrich_description(self, row: PointsLedger, is_credit: bool = True) -> Tuple[str, str]:
        """Logic to match the precise UI descriptions from the reference image."""
        ref_type = row.reference_type
        ref_id = row.reference_id
        if not ref_type: return "General Transaction", "Other"

        ref_upper = ref_type.upper()

        if ref_upper == ReferenceType.BUDGET_ALLOCATION.value:
            return "Budget Allocation\nReceived from HR", "Credit"

        # 1. Peer Appreciations (eCards)
        if ref_upper == ReferenceType.ECARD.value:
            ecard = self.repository.get_ecard(ref_id)
            if ecard:
                sender = self.repository.get_user(ecard.sender_id)
                badge = self.repository.get_badge(ecard.badge_id)
                badge_title = f"'{badge.name}'" if badge else "Recognition"
                sender_name = sender.name if sender else "a Peer"
                return f"{badge_title} Appreciation\nFrom: {sender_name}", "Earned"
            return "Recognition Reward", "Earned"

        # 2. Store Redemptions
        if ref_upper == ReferenceType.REDEMPTION.value:
            redemption = self.repository.get_redemption(ref_id)
            if redemption:
                reward = self.repository.get_reward(redemption.reward_id)
                reward_name = reward.name if reward else "Reward"
                return f"{reward_name} Redemption\nOrder ID: ALR-{redemption.id}", "Redeemed"
            return "Reward Redemption", "Redeemed"

        # 3. Anniversary / Birthday (Celebrations)
        if ref_upper == ReferenceType.CELEBRATION.value:
            # Matches format like: Milestone Achievement - 5 Years\nService Anniversary Bonus
            return "Celebration Milestone\nAnniversary/Birthday Bonus", "Earned"

        # 4. Official Awards
        if ref_upper == ReferenceType.AWARD.value:
            award = self.repository.get_award(ref_id)
            if award:
                award_type = self.repository.get_award_type(award.award_type_id)
                award_name = award_type.name if award_type else "Official Award"
                return f"{award_name}\nExcellence Award", "Earned"
            return "Official Award", "Earned"

        if ref_upper == ReferenceType.CONVERSION.value:
            conversion = self.repository.get_conversion(ref_id)
            ctype = conversion.conversion_type if conversion else "Cash"
            return f"Points Conversion - {ctype}\nCompleted Request", "Redeemed"

        if ref_upper == ReferenceType.MANAGER_REWARD.value:
            if is_credit:
                manager = self.repository.get_user(ref_id)
                manager_name = manager.name if manager else "Manager"
                return f"Direct Recognition Reward\nFrom: {manager_name}", "Earned"
            else:
                employee = self.repository.get_user(ref_id)
                employee_name = employee.name if employee else "Employee"
                return f"Budget Reward Sent\nTo: {employee_name}", "Spent"

        if ref_upper == ReferenceType.EXPIRY.value:
            return "Points Expired\nValidity Period Ended", "Expired"

        return f"{ref_type.title()} Reward", "Earned"

    def notify_upcoming_expiries(self, days: Optional[int] = None) -> Dict[str, Any]:
        """
        Notify users of points batches that will expire within the next `days` days.

        Aggregates expiring batches per user and sends a single notification
        (with email) per user via NotificationService.
        """
        from app.services.notification_service import NotificationService
        from app.core.config import settings

        if days is None:
            days = settings.POINTS_EXPIRY_REMINDER_DAYS

        today = date.today()
        cutoff = today + timedelta(days=days)

        upcoming_batches = self.repository.get_upcoming_expiry_batches(cutoff)

        if not upcoming_batches:
            return {
                "date": str(today),
                "days": days,
                "batches_notified": 0,
                "total_points_notified": 0
            }

        # Group batches by user, skipping already-notified ones
        from app.services.notification_service import NotificationService as NS2
        notification_repo = NS2(self.db)
        user_batches: Dict[int, list] = {}
        for batch in upcoming_batches:
            # Check if already notified via the repository lookup
            if self.repository.notification_exists(ReferenceType.EXPIRY.value, batch.id):
                continue
            user_batches.setdefault(batch.user_id, []).append(batch)

        notification_svc = NotificationService(self.db)
        batches_notified = 0
        total_points_notified = 0

        for user_id, batches in user_batches.items():
            # Use the earliest expiry date and total points for the email
            total_points = sum(b.remaining_points for b in batches)
            earliest_expiry = min(b.expiry_date for b in batches)
            days_left = (earliest_expiry - today).days

            message = (
                f"Reminder: {total_points} points will expire on "
                f"{earliest_expiry.isoformat()} (in {days_left} days). "
                f"Use them soon."
            )

            # Use the first batch id as source_id (for dedup tracking)
            notification_svc.create_notification(
                user_id=user_id,
                message=message,
                source_type=ReferenceType.EXPIRY.value,
                source_id=batches[0].id,
                email_event_type="POINTS_EXPIRY_REMINDER",
                email_context={
                    "points": total_points,
                    "expiry_date": earliest_expiry.isoformat(),
                },
            )

            batches_notified += len(batches)
            total_points_notified += total_points

        return {
            "date": str(today),
            "days": days,
            "batches_notified": batches_notified,
            "total_points_notified": total_points_notified
        }

    def expire_points_batches(self) -> Dict[str, Any]:
        """
        Expire old points batches.
        
        Finds batches past their expiry date and deducts remaining points.
        Should be called by scheduled job daily.
        
        Returns:
            Dictionary with expiry results (count, total_points_expired)
        """
        from app.models.notifications import Notification

        today = date.today()

        # Find expired batches with remaining points
        expired_batches = self.repository.get_all_expired_unprocessed()

        if not expired_batches:
            return {
                "date": str(today),
                "batches_expired": 0,
                "total_points_expired": 0
            }

        total_points_expired = 0
        batches_expired = 0

        for batch in expired_batches:
            points_to_expire = batch.remaining_points

            # 1. Get user's employee wallet
            wallet = self.get_employee_wallet(batch.user_id)

            # 2. Deduct remaining_points from wallet balance
            wallet.balance -= points_to_expire
            if wallet.balance < 0:
                wallet.balance = 0  # Safety net

            # 3. Create ledger entry for expiry
            self.repository.add_ledger_entry(
                source_wallet_id=wallet.id,
                points=points_to_expire,
                transaction_type=TransactionType.DEBIT.value,
                reference_type=ReferenceType.EXPIRY.value,
                reference_id=batch.id
            )

            # 4. Set batch.remaining_points to 0
            batch.remaining_points = 0

            # 5. Create notification
            notification = Notification(
                user_id=batch.user_id,
                message=f"Alert: {points_to_expire} points have expired from your account.",
                source_type=ReferenceType.EXPIRY.value,
                source_id=batch.id
            )
            self.repository.add(notification)

            total_points_expired += points_to_expire
            batches_expired += 1

        self.repository.commit()

        return {
            "date": str(today),
            "batches_expired": batches_expired,
            "total_points_expired": total_points_expired
        }


# --- BACKWARD COMPATIBILITY ---
def get_aggregates(db: Session, user_id: int):
    return PointsService(db).get_aggregates(user_id)

def fetch_ledger_history(db: Session, user_id: int, category=None, start_date=None, end_date=None, page=1, per_page=20):
    return PointsService(db).fetch_ledger_history(user_id, category, start_date, end_date, page, per_page)
