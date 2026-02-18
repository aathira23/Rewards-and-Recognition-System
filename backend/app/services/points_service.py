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

        # 2. Proceed with awarding
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
        
        return {
            "balance": balance,
            "total_earned": int(earned),
            "total_redeemed": int(redeemed),
            "pending_count": int(pending_count),
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
                PointsConversion.user_id == user_id, 
                PointsConversion.status == "PENDING"
            )
            for p in pending_q.all():
                req_date = p.requested_at.strftime("%d/%m/%Y") if p.requested_at else "Pending"
                items.insert(0, {
                    "id": f"conv-{p.id}",
                    "date": req_date,
                    "description": f"Conversion Request: {p.conversion_type}",
                    "type": "Pending",
                    "points": f"-{int(p.points_converted)}"
                })
                total_ledger += 1

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

        return f"{ref_type} #{ref_id}", "Other"


# --- BACKWARD COMPATIBILITY ---
def get_aggregates(db: Session, user_id: int):
    return PointsService(db).get_aggregates(user_id)

def fetch_ledger_history(db: Session, user_id: int, category=None, start_date=None, end_date=None, page=1, per_page=20):
    return PointsService(db).fetch_ledger_history(user_id, category, start_date, end_date, page, per_page)
