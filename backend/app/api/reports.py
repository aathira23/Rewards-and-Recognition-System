"""
Reports API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date

from app.core.database import get_db
from app.core.dependencies import get_current_user_id

router = APIRouter()


@router.get("/")
def get_reports(
    report_type: str,  # AWARDS_GIVEN, REDEMPTIONS, WALLET_UTILIZATION
    from_date: date = None,
    to_date: date = None,
    department_id: int = None,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """
    Generate and export reports.

    Report types:
    - AWARDS_GIVEN: Awards given by type, giver, date range
    - REDEMPTIONS: Redemption details by type, user, date range
    - WALLET_UTILIZATION: Manager wallet usage and balance
    """
    # TODO: Implement report generation logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/payroll")
def get_payroll_report(
    month: str,  # Format: YYYY-MM
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """
    Generate monthly payroll encashment report.

    Returns details of all approved point-to-cash conversions
    for the specified month for payroll integration.
    """
    # TODO: Implement payroll report logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )
