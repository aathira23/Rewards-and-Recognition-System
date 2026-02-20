"""
Points service - Business logic for points management, FIFO deductions, and ledger tracking.
Aligned with UI requirements for rich descriptions.
"""
from typing import Any, Dict, List, Optional, Tuple
from datetime import date, datetime, timedelta
from sqlalchemy import or_, desc, func
from sqlalchemy.orm import Session

from app.models.wallets import Wallet
from app.models.points_ledger import PointsLedger
from app.models.points_conversion import PointsConversion
from app.models.points_batches import PointsBatch
from app.models.users import User
from app.models.ecards import ECard
from app.models.awards import Award
from app.models.award_types import AwardType
from app.models.badges import Badge
from app.models.rewards import Reward
from app.models.redemptions import Redemption
from app.utils.enums import TransactionType, ReferenceType, WalletType


class PointsService:
    """Service for managing points, FIFO deductions, and ledger tracking."""

    def __init__(self, db: Session):
        self.db = db

    def get_employee_wallet(self, user_id: int) -> Optional[Wallet]:
        """Get or create employee wallet."""
        wallet = self.db.query(Wallet).filter(
            Wallet.user_id == user_id, 
            Wallet.wallet_type == WalletType.EMPLOYEE.value
        ).first()
        if not wallet:
            wallet = Wallet(user_id=user_id, wallet_type=WalletType.EMPLOYEE.value, balance=0)
            self.db.add(wallet)
            self.db.commit()
            self.db.refresh(wallet)
        return wallet

    def get_user_balance(self, user_id: int) -> int:
        """Get total available points for a user across all non-expired batches."""
        today = date.today()
        total = self.db.query(func.sum(PointsBatch.remaining_points)).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.expiry_date >= today,
            PointsBatch.remaining_points > 0
        ).scalar() or 0
        return int(total)

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
        cap_val = config_service.get_config("SYSTEM_MONTHLY_BUDGET_CAP")
        
        if cap_val:
            try:
                cap = int(cap_val)
                # Calculate total awarded this month
                first_day = date.today().replace(day=1)
                month_total = self.db.query(func.sum(PointsLedger.points)).filter(
                    PointsLedger.transaction_type == TransactionType.CREDIT.value,
                    PointsLedger.created_at >= first_day
                ).scalar() or 0
                
                if month_total + points > cap:
                    available = max(0, cap - month_total)
                    raise ValueError(
                        f"System-wide monthly budget cap reached. "
                        f"Remaining budget: {available}, Requested: {points}"
                    )
            except ValueError as e:
                if "System-wide" in str(e): raise e
                # If int conversion fails, ignore the cap
                pass

        # 2. If this is a manager->employee transfer, deduct manager budget centrally
        if source_type == ReferenceType.MANAGER_REWARD.value:
            # source_id is expected to be the manager's user_id
            manager_wallet = self.db.query(Wallet).filter(
                Wallet.user_id == source_id,
                Wallet.wallet_type == WalletType.MANAGER.value
            ).first()
            if not manager_wallet or manager_wallet.balance < points:
                raise ValueError(f"Insufficient manager budget. Available: {manager_wallet.balance if manager_wallet else 0}, Requested: {points}")

            # Deduct from manager wallet and create debit ledger entry
            manager_wallet.balance -= points
            manager_debit = PointsLedger(
                source_wallet_id=manager_wallet.id,
                points=points,
                transaction_type=TransactionType.DEBIT.value,
                reference_type=ReferenceType.MANAGER_REWARD.value,
                reference_id=user_id
            )
            self.db.add(manager_debit)

        # 2. Proceed with awarding (credit to employee)
        expiry_date = date.today() + timedelta(days=expiry_days)
        batch = PointsBatch(
            user_id=user_id,
            points=points,
            remaining_points=points,
            source_type=source_type,
            source_id=source_id,
            expiry_date=expiry_date
        )
        self.db.add(batch)
        
        wallet = self.get_employee_wallet(user_id)
        wallet.balance += points
        
        ledger = PointsLedger(
            target_wallet_id=wallet.id,
            points=points,
            transaction_type=TransactionType.CREDIT.value,
            reference_type=source_type,
            reference_id=source_id
        )
        self.db.add(ledger)
        
        self.db.commit()
        self.db.refresh(batch)
        return batch

    def deduct_points(self, user_id: int, points: int, reference_type: str, reference_id: int):
        """Deduct points from user using FIFO (oldest batches first)."""
        if points <= 0:
            return
            
        wallet = self.get_employee_wallet(user_id)
        if wallet.balance < points:
            raise ValueError(f"Insufficient points. Available: {wallet.balance}, Requested: {points}")

        today = date.today()
        batches = self.db.query(PointsBatch).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.expiry_date >= today,
            PointsBatch.remaining_points > 0
        ).order_by(PointsBatch.expiry_date.asc()).all()

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
        ledger = PointsLedger(
            source_wallet_id=wallet.id,
            points=points,
            transaction_type=TransactionType.DEBIT.value,
            reference_type=reference_type,
            reference_id=reference_id
        )
        self.db.add(ledger)
        self.db.commit()

    def get_aggregates(self, user_id: int) -> Dict[str, int]:
        """Compute dashboard metrics: balance, earned, redeemed, pending."""
        wallet = self.get_employee_wallet(user_id)
        balance = self.get_user_balance(user_id)
        
        earned = self.db.query(func.sum(PointsLedger.points)).filter(
            PointsLedger.transaction_type == TransactionType.CREDIT.value,
            PointsLedger.target_wallet_id == wallet.id
        ).scalar() or 0
        
        redeemed = self.db.query(func.sum(Redemption.points_used)).filter(
            Redemption.user_id == user_id
        ).scalar() or 0
        
        pending_count = self.db.query(func.count(PointsConversion.id)).filter(
            PointsConversion.user_id == user_id,
            PointsConversion.status == "PENDING"
        ).scalar() or 0
        
        # Calculate points expiring today
        today = date.today()
        expiring_today = self.db.query(func.sum(PointsBatch.remaining_points)).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.remaining_points > 0,
            PointsBatch.expiry_date == today
        ).scalar() or 0

        # Calculate points expiring this month (from tomorrow until end of month)
        import calendar
        _, last_day = calendar.monthrange(today.year, today.month)
        end_of_month = date(today.year, today.month, last_day)
        
        expiring_this_month = self.db.query(func.sum(PointsBatch.remaining_points)).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.remaining_points > 0,
            PointsBatch.expiry_date > today,
            PointsBatch.expiry_date <= end_of_month
        ).scalar() or 0

        return {
            "balance": balance,
            "total_earned": int(earned),
            "total_redeemed": int(redeemed),
            "pending_count": int(expiring_today), # Repurposing as legacy support if needed
            "expiring_soon": int(expiring_today + expiring_this_month),
            "expiring_today": int(expiring_today),
            "expiring_this_month": int(expiring_this_month),
        }

    def fetch_ledger_history(
        self,
        user_id: int,
        category: Optional[str] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        page: int = 1,
        per_page: int = 20,
    ) -> Tuple[int, List[Dict[str, Any]]]:
        """Fetch paginated points history including merged pending/expired entries."""
        wallet = self.get_employee_wallet(user_id)
        if not wallet:
            return 0, []

        q = self.db.query(PointsLedger).filter(
            or_(PointsLedger.source_wallet_id == wallet.id, PointsLedger.target_wallet_id == wallet.id)
        )

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

        # Handle specific category filtering
        include_pending = True
        if category:
            cat = category.lower()
            if cat == "received":
                q = q.filter(PointsLedger.transaction_type == TransactionType.CREDIT.value)
                include_pending = False
            elif cat == "spent":
                q = q.filter(PointsLedger.transaction_type == TransactionType.DEBIT.value)
                include_pending = False
            elif cat == "pending":
                # Only show pending conversions, hide all ledger records
                q = q.filter(PointsLedger.id == -1)
                include_pending = True
            elif cat == "expired":
                include_pending = False
                # Return expired batches
                today = date.today()
                batch_q = self.db.query(PointsBatch).filter(
                    PointsBatch.user_id == user_id,
                    PointsBatch.expiry_date <= today,
                    PointsBatch.remaining_points > 0
                )
                total = batch_q.count()
                rows = batch_q.order_by(desc(PointsBatch.expiry_date)).offset((page-1)*per_page).limit(per_page).all()
                items = [{
                    "id": f"batch-{b.id}",
                    "date": b.expiry_date.strftime("%d/%m/%Y"),
                    "description": f"Points Expired - {b.source_type}",
                    "type": "Expired",
                    "points": f"-{int(b.remaining_points)}"
                } for b in rows]
                return total, items

        total_ledger = q.count()
        rows = q.order_by(desc(PointsLedger.created_at)).offset((page - 1) * per_page).limit(per_page).all()
        items = [self._map_ledger_row(r, wallet.id) for r in rows]

        # Merge Pending Conversions
        if include_pending and (not category or category.lower() == "pending"):
            pending_q = self.db.query(PointsConversion).filter(
                PointsConversion.status == "PENDING"
            )
            # Find conversions belonging to this user
            user_pending = [p for p in pending_q.all() if p.user_id == user_id]
            
            # Update total count
            total_ledger += len(user_pending)
            
            # Only add to results if we are on the first page
            if page == 1:
                # Add in reverse chronological order (assuming list is chronological)
                for p in reversed(user_pending):
                    req_date = p.requested_at.strftime("%d/%m/%Y") if p.requested_at else "Pending"
                    items.insert(0, {
                        "id": f"conv-{p.id}",
                        "date": req_date,
                        "description": f"Conversion Request: {p.conversion_type}\nAwaiting HR Approval",
                        "type": "Pending",
                        "points": f"-{int(p.points_converted)}"
                    })

        return total_ledger, items

    def _map_ledger_row(self, row: PointsLedger, wallet_id: int) -> Dict[str, Any]:
        is_credit = row.target_wallet_id == wallet_id
        points = int(row.points)
        description, type_badge = self._enrich_description(row)
        return {
            "id": row.id,
            "date": row.created_at.strftime("%d/%m/%Y") if row.created_at else "",
            "description": description,
            "type": type_badge,
            "points": f"+{points}" if is_credit else f"-{points}",
        }

    def _enrich_description(self, row: PointsLedger) -> Tuple[str, str]:
        """Logic to match the precise UI descriptions from the reference image."""
        ref_type = row.reference_type
        ref_id = row.reference_id
        if not ref_type: return "General Transaction", "Other"
        
        ref_upper = ref_type.upper()
        
        # 1. Peer Appreciations (eCards)
        if ref_upper == ReferenceType.ECARD.value:
            ecard = self.db.query(ECard).filter(ECard.id == ref_id).first()
            if ecard:
                sender = self.db.query(User).filter(User.id == ecard.sender_id).first()
                badge = self.db.query(Badge).filter(Badge.id == ecard.badge_id).first()
                badge_title = f"'{badge.name}'" if badge else "Recognition"
                sender_name = sender.name if sender else "a Peer"
                return f"{badge_title} Appreciation\nFrom: {sender_name}", "Earned"
            return "Recognition Reward", "Earned"
        
        # 2. Store Redemptions
        if ref_upper == ReferenceType.REDEMPTION.value:
            redemption = self.db.query(Redemption).filter(Redemption.id == ref_id).first()
            if redemption:
                reward = self.db.query(Reward).filter(Reward.id == redemption.reward_id).first()
                reward_name = reward.name if reward else "Reward"
                # Matches format like: Amazon Gift Voucher Redemption\nOrder ID: ALR-984421
                return f"{reward_name} Redemption\nOrder ID: ALR-{redemption.id}", "Redeemed"
            return "Reward Redemption", "Redeemed"
        
        # 3. Anniversary / Birthday (Celebrations)
        if ref_upper == ReferenceType.CELEBRATION.value:
            # Matches format like: Milestone Achievement - 5 Years\nService Anniversary Bonus
            return "Celebration Milestone\nAnniversary/Birthday Bonus", "Earned"
            
        # 4. Official Awards
        if ref_upper == ReferenceType.AWARD.value:
            award = self.db.query(Award).filter(Award.id == ref_id).first()
            if award:
                award_type = self.db.query(AwardType).filter(AwardType.id == award.award_type_id).first()
                award_name = award_type.name if award_type else "Official Award"
                return f"{award_name}\nExcellence Award", "Earned"
            return "Official Award", "Earned"

        if ref_upper == ReferenceType.CONVERSION.value:
            conversion = self.db.query(PointsConversion).filter(PointsConversion.id == ref_id).first()
            ctype = conversion.conversion_type if conversion else "Cash"
            return f"Points Conversion - {ctype}\nCompleted Request", "Redeemed"

        if ref_upper == ReferenceType.MANAGER_REWARD.value:
            manager = self.db.query(User).filter(User.id == ref_id).first()
            manager_name = manager.name if manager else "Manager"
            return f"Direct Recognition Reward\nFrom: {manager_name}", "Earned"

        if ref_upper == ReferenceType.EXPIRY.value:
            return "Points Expired\nValidity Period Ended", "Expired"

        return f"{ref_type.title()} Reward", "Earned"

    def notify_upcoming_expiries(self, days: Optional[int] = None) -> Dict[str, Any]:
        """
        Notify users of points batches that will expire within the next `days` days.

        Creates a `Notification` for each qualifying `PointsBatch` unless a notification
        for the same batch already exists.
        """
        from app.models.notifications import Notification
        from app.core.config import settings

        if days is None:
            days = settings.POINTS_EXPIRY_REMINDER_DAYS

        today = date.today()
        cutoff = today + timedelta(days=days)

        upcoming_batches = self.db.query(PointsBatch).filter(
            PointsBatch.expiry_date > today,
            PointsBatch.expiry_date <= cutoff,
            PointsBatch.remaining_points > 0
        ).all()

        if not upcoming_batches:
            return {
                "date": str(today),
                "days": days,
                "batches_notified": 0,
                "total_points_notified": 0
            }

        batches_notified = 0
        total_points_notified = 0

        for batch in upcoming_batches:
            # avoid duplicate reminders for the same batch
            exists = self.db.query(Notification).filter(
                Notification.source_type == ReferenceType.EXPIRY.value,
                Notification.source_id == batch.id
            ).first()
            if exists:
                continue

            days_left = (batch.expiry_date - today).days
            message = (
                f"Reminder: {batch.remaining_points} points will expire on {batch.expiry_date.isoformat()} "
                f"(in {days_left} days). Use them soon."
            )
            notification = Notification(
                user_id=batch.user_id,
                message=message,
                source_type=ReferenceType.EXPIRY.value,
                source_id=batch.id
            )
            self.db.add(notification)

            batches_notified += 1
            total_points_notified += batch.remaining_points

        self.db.commit()

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
        expired_batches = self.db.query(PointsBatch).filter(
            PointsBatch.expiry_date < today,
            PointsBatch.remaining_points > 0
        ).all()

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
            ledger = PointsLedger(
                source_wallet_id=wallet.id,
                points=points_to_expire,
                transaction_type=TransactionType.DEBIT.value,
                reference_type=ReferenceType.EXPIRY.value,
                reference_id=batch.id
            )
            self.db.add(ledger)

            # 4. Set batch.remaining_points to 0
            batch.remaining_points = 0

            # 5. Create notification
            notification = Notification(
                user_id=batch.user_id,
                message=f"Alert: {points_to_expire} points have expired from your account.",
                source_type=ReferenceType.EXPIRY.value,
                source_id=batch.id
            )
            self.db.add(notification)
            
            total_points_expired += points_to_expire
            batches_expired += 1

        self.db.commit()
        
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
