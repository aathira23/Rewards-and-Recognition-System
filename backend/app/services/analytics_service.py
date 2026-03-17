from datetime import date
from typing import Optional, Dict, Any, List
from sqlalchemy.orm import Session

from app.utils.enums import Scope
from app.repository.analytics_repository import AnalyticsRepository


class AnalyticsService:
    """Service for generating analytics and metrics."""

    def __init__(self, db: Session, token: Optional[str] = None):
        self.db = db
        self._token = token
        self.repository = AnalyticsRepository(db)

    def _get_user_names_batch(self, user_ids: set) -> dict:
        """Batch-resolve user names via User Service, fallback to local DB."""
        if not user_ids:
            return {}
        if self._token:
            from app.services.user_profiles_client import get_users_batch
            profiles = get_users_batch(list(user_ids), self._token)
            return {uid: p.name for uid, p in profiles.items()}
        from app.models.users import User as UserModel
        rows = self.db.query(UserModel).filter(UserModel.id.in_(user_ids)).all()
        return {u.id: u.name for u in rows}

    def get_recognition_report(
        self,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        department_id: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """Get detailed recognition report."""
        results = self.repository.get_recognitions(from_date, to_date, department_id)

        # Batch-load user names from User Service
        uid_set = {r.actor_id for r in results} | {r.receiver_id for r in results if r.receiver_id}
        users_map = self._get_user_names_batch(uid_set)

        report_data = []
        for r in results:
            points = self.repository.get_points_for_recognition(
                r.source_type, r.source_id, r.receiver_id
            ) or 0

            report_data.append({
                "id": r.id,
                "actor_name": users_map.get(r.actor_id) or f"User {r.actor_id}",
                "receiver_name": users_map.get(r.receiver_id) or f"User {r.receiver_id}",
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
        results = self.repository.get_redemptions(from_date, to_date)

        uid_set = {r.user_id for r in results}
        users_map = self._get_user_names_batch(uid_set)

        report_data = []
        for r in results:
            report_data.append({
                "id": r.id,
                "user_name": users_map.get(r.user_id) or f"User {r.user_id}",
                "reward_name": r.reward.name,
                "points_used": r.points_used,
                "status": r.status,
                "created_at": r.created_at
            })
        return report_data

    def get_wallet_utilization_report(self) -> List[Dict[str, Any]]:
        """Get manager wallet utilization report."""
        managers = self.repository.get_managers()

        report_data = []
        for m in managers:
            wallet = self.repository.get_manager_wallet(m.id)
            if not wallet:
                continue

            total_allocated = self.repository.get_total_funding(wallet.id)

            report_data.append({
                "manager_id": m.id,
                "manager_name": m.name,
                "total_allocated": total_allocated,
                "total_spent": total_allocated - wallet.balance,
                "remaining_balance": wallet.balance
            })
        return report_data

    def get_payroll_report(self, month_str: str) -> List[Dict[str, Any]]:
        """Get monthly payroll report for approved conversions."""
        year, month = map(int, month_str.split("-"))
        results = self.repository.get_approved_conversions(year, month)

        uid_set = {r.user_id for r in results}
        users_map = self._get_user_names_batch(uid_set)

        report_data = []
        for r in results:
            report_data.append({
                "user_name": users_map.get(r.user_id) or f"User {r.user_id}",
                "employee_id": None,
                "points_converted": r.points_converted,
                "cash_amount": float(r.cash_amount),
                "status": r.status,
                "approved_at": r.approved_at
            })
        return report_data

    def get_dashboard_metrics(
        self,
        current_user: Any,
        scope: Scope = Scope.ORG,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """
        Get analytics dashboard metrics based on user role and scope.
        """
        # 1. Determine the set of users to analyze based on scope and role
        user_ids = self._get_scope_user_ids(current_user, scope)

        # 2. Key Statistics
        total_recognitions = self.repository.count_recognitions(user_ids, from_date, to_date)
        total_points = self.repository.sum_points_distributed(user_ids, from_date, to_date)

        # 3. Trends (Last 30 days or specified range)
        trends = self.get_recognition_trends(user_ids, from_date, to_date)

        # 4. Top Lists
        top_recognizers = self.get_top_recognizers(user_ids, limit=5)
        top_recognized = self.get_top_recognized(user_ids, limit=5)

        # 5. Engagement
        engagement = self.get_engagement_rate(user_ids)

        # 6. Scope name (human-readable label shown in header)
        scope_name = self._get_scope_name(current_user, scope)

        # 7. Breakdown (per-dept for ORG, per-team/manager for DEPARTMENT)
        breakdown = self._get_breakdown(current_user, scope, from_date, to_date)

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
            "scope_name": scope_name,
            "user_count": len(user_ids) if user_ids else self.repository.get_total_user_count(),
            "breakdown": breakdown,
        }

    def _get_scope_user_ids(self, user: Any, scope: Scope) -> Optional[List[int]]:
        """Identify which users belong to the requested scope."""
        if scope == Scope.TEAM:
            return self.repository.get_subordinate_ids(user.id)
        elif scope == Scope.DEPARTMENT:
            dept_id = user.department_id
            if not dept_id:
                return []
            return self.repository.get_department_member_ids(dept_id)
        return None

    def _get_scope_name(self, user: Any, scope: Scope) -> str:
        """Return a human-readable label for the current scope."""
        if scope == Scope.DEPARTMENT:
            dept = self.repository.get_department(user.department_id)
            return dept.name if dept else "Department"
        if scope == Scope.TEAM:
            return f"{user.name}'s Team"
        return "Organization"

    def _get_breakdown(
        self,
        user: Any,
        scope: Scope,
        from_date: Optional[date],
        to_date: Optional[date],
    ) -> List[Dict[str, Any]]:
        """
        Return a per-department breakdown for ORG scope, or a per-team
        (manager) breakdown for DEPARTMENT scope. Returns [] for TEAM scope.
        """
        if scope == Scope.ORG:
            departments = self.repository.get_all_departments()
            result = []
            for dept in departments:
                member_ids = self.repository.get_department_member_ids(dept.id)
                if not member_ids:
                    continue
                rec_count = self.repository.count_recognitions_for_users(
                    member_ids, from_date, to_date
                )
                pts = self.repository.sum_points_for_users(
                    member_ids, from_date, to_date
                )
                engagement = self.get_engagement_rate(member_ids)
                result.append({
                    "name": dept.name,
                    "recognition_count": rec_count,
                    "points": int(pts),
                    "user_count": len(member_ids),
                    "engagement": engagement,
                })
            result.sort(key=lambda x: x["recognition_count"], reverse=True)
            return result

        if scope == Scope.DEPARTMENT:
            dept_id = user.department_id
            if not dept_id:
                return []
            managers = self.repository.get_department_managers(dept_id)
            manager_ids = list({
                u.manager_id for u in managers
                if u.manager_id and u.manager_id != user.id
            })
            result = []
            for mgr_id in manager_ids:
                mgr = self.repository.get_user_by_id(mgr_id)
                if not mgr:
                    continue
                team_ids = self.repository.get_subordinate_ids(mgr_id)
                if not team_ids:
                    continue
                rec_count = self.repository.count_recognitions_for_users(team_ids)
                pts = self.repository.sum_points_for_users(team_ids)
                engagement = self.get_engagement_rate(team_ids)
                result.append({
                    "name": f"{mgr.name}'s Team",
                    "recognition_count": rec_count,
                    "points": int(pts),
                    "user_count": len(team_ids),
                    "engagement": engagement,
                })
            result.sort(key=lambda x: x["recognition_count"], reverse=True)
            return result

        return []

    def get_recognition_trends(self, user_ids: Optional[List[int]], from_date: Optional[date], to_date: Optional[date]):
        """Calculate counts of recognitions per day."""
        results = self.repository.get_recognition_trends(user_ids, from_date, to_date)
        return [{"date": str(r.date), "count": r.count} for r in results]

    def get_top_recognizers(self, user_ids: Optional[List[int]], limit: int = 5):
        """Find users who gave most recognitions."""
        results = self.repository.get_top_recognizers(user_ids, limit)
        return [{"name": r.name, "count": r.count} for r in results]

    def get_top_recognized(self, user_ids: Optional[List[int]], limit: int = 5):
        """Find users who received most recognitions."""
        results = self.repository.get_top_recognized(user_ids, limit)
        return [{"name": r.name, "count": r.count} for r in results]

    def get_engagement_rate(self, user_ids: Optional[List[int]]) -> float:
        """Percentage of users that have participated in recognition."""
        total_users = len(user_ids) if user_ids is not None else self.repository.get_total_user_count()
        if total_users == 0:
            return 0.0
        active_users_count = self.repository.get_active_user_count(user_ids)
        return round((active_users_count / total_users) * 100, 2)
    def get_expiry_forecast(self, days: int = 30) -> List[Dict[str, Any]]:
        """Forecast points expiring in the next N days."""
        from datetime import timedelta

        target_date = date.today() + timedelta(days=days)
        results = self.repository.get_expiry_forecast(target_date)

        forecast_data = []
        for r in results:
            forecast_data.append({
                "expiry_date": r.expiry_date,
                "total_points": int(r.total_points),
                "user_count": r.user_count
            })
        return forecast_data
