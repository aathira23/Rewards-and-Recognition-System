from datetime import date, datetime
from typing import Optional, Dict, Any, List
from sqlalchemy import func, extract
from sqlalchemy.orm import Session

from app.models.users import User
from app.models.recognition_feed import RecognitionFeed
from app.models.redemptions import Redemption
from app.models.rewards import Reward
from app.models.wallets import Wallet
from app.models.wallet_funding import WalletFunding
from app.models.points_conversion import PointsConversion
from app.models.points_ledger import PointsLedger
from app.utils.enums import WalletType, ConversionStatus


class AnalyticsService:
    """Service for generating analytics and metrics."""

    def __init__(self, db: Session):
        self.db = db

    def get_recognition_report(
        self,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        department_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """Get detailed recognition report."""
        query = self.db.query(RecognitionFeed).join(
            User, RecognitionFeed.receiver_id == User.id, isouter=True
        )

        if from_date:
            query = query.filter(RecognitionFeed.created_at >= from_date)
        if to_date:
            query = query.filter(RecognitionFeed.created_at <= to_date)
        if department_id:
            query = query.filter(User.department_id == department_id)

        results = query.order_by(RecognitionFeed.created_at.desc()).all()
        
        report_data = []
        for r in results:
            # Try to find points from ledger by matching receiver's wallet
            points_row = self.db.query(PointsLedger.points).join(
                Wallet, PointsLedger.target_wallet_id == Wallet.id
            ).filter(
                PointsLedger.reference_type == r.source_type,
                PointsLedger.reference_id == r.source_id,
                PointsLedger.transaction_type == "CREDIT",
                Wallet.user_id == r.receiver_id
            ).first()
            
            points = points_row[0] if points_row else 0

            report_data.append({
                "id": r.id,
                "actor_name": r.actor.name if r.actor else "System",
                "receiver_name": r.receiver.name if r.receiver else "Unknown",
                "source_type": r.source_type,
                "points": points,
                "message": r.message,
                "created_at": r.created_at
            })
        return report_data

    def get_redemption_report(
        self,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> List[Dict[str, Any]]:
        """Get reward redemption report."""
        query = self.db.query(Redemption).join(Reward).join(User)

        if from_date:
            query = query.filter(Redemption.created_at >= from_date)
        if to_date:
            query = query.filter(Redemption.created_at <= to_date)

        results = query.order_by(Redemption.created_at.desc()).all()
        
        report_data = []
        for r in results:
            report_data.append({
                "id": r.id,
                "user_name": r.user.name,
                "reward_name": r.reward.name,
                "points_used": r.points_used,
                "status": r.status,
                "created_at": r.created_at
            })
        return report_data

    def get_wallet_utilization_report(self) -> List[Dict[str, Any]]:
        """Get manager wallet utilization report."""
        managers = self.db.query(User).filter(User.role.in_(["MANAGER", "DEPT_HEAD"])).all()
        
        report_data = []
        for m in managers:
            wallet = self.db.query(Wallet).filter(
                Wallet.user_id == m.id,
                Wallet.wallet_type == WalletType.MANAGER.value
            ).first()
            
            if not wallet: continue

            # Total allocated (from funding records)
            total_allocated = self.db.query(func.sum(WalletFunding.points)).filter(
                WalletFunding.manager_wallet_id == wallet.id
            ).scalar() or 0

            report_data.append({
                "manager_name": m.name,
                "total_allocated": total_allocated,
                "total_spent": total_allocated - wallet.balance,
                "remaining_balance": wallet.balance
            })
        return report_data

    def get_payroll_report(self, month_str: str) -> List[Dict[str, Any]]:
        """Get monthly payroll report for approved conversions."""
        # month_str format: YYYY-MM
        year, month = map(int, month_str.split("-"))
        
        query = self.db.query(PointsConversion).join(
            User, PointsConversion.user_id == User.id
        ).filter(
            PointsConversion.status == ConversionStatus.APPROVED.value,
            extract('year', PointsConversion.approved_at) == year,
            extract('month', PointsConversion.approved_at) == month
        )

        results = query.all()
        
        report_data = []
        for r in results:
            report_data.append({
                "user_name": r.user.name,
                "employee_id": None, # Could add if available in User model
                "points_converted": r.points_converted,
                "cash_amount": float(r.cash_amount),
                "status": r.status,
                "approved_at": r.approved_at
            })
        return report_data

    def get_dashboard_metrics(
        self,
        current_user: Any,
        scope: str = "ORG",
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """
        Get analytics dashboard metrics based on user role and scope.
        """
        # 1. Determine the set of users to analyze based on scope and role
        user_ids = self._get_scope_user_ids(current_user, scope)
        
        # 2. Key Statistics
        total_recognitions = self.db.query(func.count(RecognitionFeed.id)).filter(
            RecognitionFeed.receiver_id.in_(user_ids) if user_ids is not None else True,
            RecognitionFeed.created_at >= from_date if from_date else True,
            RecognitionFeed.created_at <= to_date if to_date else True
        ).scalar() or 0

        total_points = self.db.query(func.sum(PointsLedger.points)).join(
            Wallet, PointsLedger.target_wallet_id == Wallet.id
        ).filter(
            Wallet.user_id.in_(user_ids) if user_ids is not None else True,
            PointsLedger.transaction_type == "CREDIT",
            PointsLedger.created_at >= from_date if from_date else True,
            PointsLedger.created_at <= to_date if to_date else True
        ).scalar() or 0

        # 3. Trends (Last 30 days or specified range)
        trends = self.get_recognition_trends(user_ids, from_date, to_date)

        # 4. Top Lists
        top_recognizers = self.get_top_recognizers(user_ids, limit=5)
        top_recognized = self.get_top_recognized(user_ids, limit=5)

        # 5. Engagement
        engagement = self.get_engagement_rate(user_ids)

        return {
            "summary": {
                "total_recognitions": total_recognitions,
                "total_points_distributed": int(total_points),
                "engagement_rate": engagement
            },
            "trends": trends,
            "top_recognizers": top_recognizers,
            "top_recognized": top_recognized,
            "scope": scope,
            "user_count": len(user_ids) if user_ids else self.db.query(User).count()
        }

    def _get_scope_user_ids(self, user: Any, scope: str) -> Optional[List[int]]:
        """Identify which users belong to the requested scope."""
        if scope == "TEAM":
            # Direct reports
            subordinates = self.db.query(User.id).filter(User.manager_id == user.id).all()
            return [s.id for s in subordinates]
        
        elif scope == "DEPARTMENT":
            # Everyone in the dept
            dept_id = user.department_id
            if not dept_id: return []
            members = self.db.query(User.id).filter(User.department_id == dept_id).all()
            return [m.id for m in members]
        
        # ORG scope or HR/Admin role - returns None to signify "no filter" (all users)
        return None

    def get_recognition_trends(self, user_ids: Optional[List[int]], from_date: Optional[date], to_date: Optional[date]):
        """Calculate counts of recognitions per day."""
        query = self.db.query(
            func.date(RecognitionFeed.created_at).label('date'),
            func.count(RecognitionFeed.id).label('count')
        )
        
        if user_ids is not None:
            query = query.filter(RecognitionFeed.receiver_id.in_(user_ids))
        
        if from_date:
            query = query.filter(RecognitionFeed.created_at >= from_date)
        if to_date:
            query = query.filter(RecognitionFeed.created_at <= to_date)
            
        results = query.group_by(func.date(RecognitionFeed.created_at)).order_by('date').all()
        return [{"date": str(r.date), "count": r.count} for r in results]

    def get_top_recognizers(self, user_ids: Optional[List[int]], limit: int = 5):
        """Find users who gave most recognitions."""
        query = self.db.query(
            User.name,
            func.count(RecognitionFeed.id).label('count')
        ).join(RecognitionFeed, User.id == RecognitionFeed.actor_id)
        
        if user_ids is not None:
            query = query.filter(User.id.in_(user_ids))
            
        results = query.group_by(User.id).order_by(func.count(RecognitionFeed.id).desc()).limit(limit).all()
        return [{"name": r.name, "count": r.count} for r in results]

    def get_top_recognized(self, user_ids: Optional[List[int]], limit: int = 5):
        """Find users who received most recognitions."""
        query = self.db.query(
            User.name,
            func.count(RecognitionFeed.id).label('count')
        ).join(RecognitionFeed, User.id == RecognitionFeed.receiver_id)
        
        if user_ids is not None:
            query = query.filter(User.id.in_(user_ids))
            
        results = query.group_by(User.id).order_by(func.count(RecognitionFeed.id).desc()).limit(limit).all()
        return [{"name": r.name, "count": r.count} for r in results]

    def get_engagement_rate(self, user_ids: Optional[List[int]]) -> float:
        """Percentage of users that have participated in recognition."""
        total_users = len(user_ids) if user_ids is not None else self.db.query(User).count()
        if total_users == 0: return 0.0
        
        # Active users (gave or received)
        query_received = self.db.query(RecognitionFeed.receiver_id.label('uid'))
        query_sent = self.db.query(RecognitionFeed.actor_id.label('uid'))
        
        if user_ids is not None:
            query_received = query_received.filter(RecognitionFeed.receiver_id.in_(user_ids))
            query_sent = query_sent.filter(RecognitionFeed.actor_id.in_(user_ids))
            
        active_users_count = query_received.union(query_sent).distinct().count()
        return round((active_users_count / total_users) * 100, 2)
    def get_expiry_forecast(self, days: int = 30) -> List[Dict[str, Any]]:
        """Forecast points expiring in the next N days."""
        from app.models.points_batches import PointsBatch
        from datetime import date, timedelta

        target_date = date.today() + timedelta(days=days)

        query = self.db.query(
            PointsBatch.expiry_date,
            func.sum(PointsBatch.remaining_points).label('total_points'),
            func.count(PointsBatch.user_id.distinct()).label('user_count')
        ).filter(
            PointsBatch.remaining_points > 0,
            PointsBatch.expiry_date <= target_date,
            PointsBatch.expiry_date >= date.today()
        ).group_by(PointsBatch.expiry_date).order_by(PointsBatch.expiry_date)

        results = query.all()
        
        forecast_data = []
        for r in results:
            forecast_data.append({
                "expiry_date": r.expiry_date,
                "total_points": int(r.total_points),
                "user_count": r.user_count
            })
        return forecast_data
