"""
Analytics API endpoints.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import date

from app.core.database import get_db

from app.services.analytics_service import AnalyticsService
from app.utils.response import success, client_error
from app.core.dependencies import get_current_user
from app.utils.enums import UserRole
from app.utils.constants import SUCCESS_METRICS_RETRIEVED

router = APIRouter()


@router.get("/")
def get_analytics(
    from_date: date = None,
    to_date: date = None,
    scope: str = None, # ORG, DEPARTMENT, TEAM
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get analytics dashboard data based on user role and permitted scope.
    """
    from app.core.scope_policy import resolve_effective_scope
    
    # 1. Enforce Role-Based Scope
    scope = resolve_effective_scope(scope, current_user.role)

    service = AnalyticsService(db)
    metrics = service.get_dashboard_metrics(
        current_user=current_user,
        scope=scope,
        from_date=from_date,
        to_date=to_date
    )

    return success(data=metrics, message=SUCCESS_METRICS_RETRIEVED)
