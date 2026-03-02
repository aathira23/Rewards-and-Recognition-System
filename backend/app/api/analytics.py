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
    # 1. Enforce Role-Based Scope
    if not scope:
        # Default scope based on role
        if current_user.role in [UserRole.HR.value, UserRole.ADMIN.value]:
            scope = "ORG"
        elif current_user.role == UserRole.DEPT_HEAD.value:
            scope = "DEPARTMENT"
        elif current_user.role == UserRole.MANAGER.value:
            scope = "TEAM"
        else:
            scope = "TEAM" # Employees can see team analytics if they are managers, otherwise it will be empty

    # Check permission for requested scope
    if scope == "ORG" and current_user.role not in [UserRole.HR.value, UserRole.ADMIN.value]:
        return client_error(message="Access denied to Organization scope", status_code=403)

    if scope == "DEPARTMENT" and current_user.role not in [UserRole.HR.value, UserRole.ADMIN.value, UserRole.DEPT_HEAD.value]:
        return client_error(message="Access denied to Department scope", status_code=403)

    if scope == "TEAM" and current_user.role not in [UserRole.HR.value, UserRole.DEPT_HEAD.value, UserRole.MANAGER.value]:
        # For a standard employee who isn't a manager, we could either error or return empty
        # Let's allow them to call it but it will likely return zeros if they have no direct reports
        pass

    service = AnalyticsService(db)
    metrics = service.get_dashboard_metrics(
        current_user=current_user,
        scope=scope,
        from_date=from_date,
        to_date=to_date
    )

    return success(data=metrics, message="Analytics metrics retrieved successfully")
