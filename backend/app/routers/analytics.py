"""
Analytics API endpoints.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import date

from app.core.database import get_db

from app.services.analytics_service import AnalyticsService
from app.utils.response import success
from app.core.dependencies import get_current_user, oauth2_scheme
from app.utils.enums import Scope
from app.utils.constants import SUCCESS_METRICS_RETRIEVED

router = APIRouter()


@router.get("/")
def get_analytics(
    from_date: date = None,
    to_date: date = None,
    scope: str = None, # ORG, DEPARTMENT, TEAM
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    token: str = Depends(oauth2_scheme)
):
    """
    Get analytics dashboard data.
    Scope is provided by the frontend (derived from the locally stored role)
    since the User Service does not expose a role field.
    """
    # Resolve scope from query param; default to ORG
    resolved_scope = Scope.ORG
    if scope:
        try:
            resolved_scope = Scope(scope.upper())
        except ValueError:
            resolved_scope = Scope.ORG

    service = AnalyticsService(db, token=token)
    metrics = service.get_dashboard_metrics(
        current_user=current_user,
        scope=resolved_scope,
        from_date=from_date,
        to_date=to_date
    )

    return success(data=metrics, message=SUCCESS_METRICS_RETRIEVED)
