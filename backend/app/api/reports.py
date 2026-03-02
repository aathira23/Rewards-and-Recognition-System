"""
Reports API endpoints.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import date, datetime

from app.core.database import get_db
from app.core.dependencies import get_current_user_id

from app.services.analytics_service import AnalyticsService
from app.utils.response import success, client_error
from app.schemas.reports import ReportResponse
from app.utils.export import generate_csv_response
from typing import Union, Any

router = APIRouter()


@router.get("/", response_model=Union[ReportResponse, Any])
def get_reports(
    report_type: str,  # AWARDS_GIVEN, REDEMPTIONS, WALLET_UTILIZATION
    from_date: date = None,
    to_date: date = None,
    department_id: int = None,
    days: int = 30,
    export_format: str = "json", # json, csv
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """
    Generate and export reports.
    """
    service = AnalyticsService(db)

    if report_type == "AWARDS_GIVEN" or report_type == "RECOGNITIONS":
        data = service.get_recognition_report(from_date, to_date, department_id)
        msg = "Recognition report generated"
    elif report_type == "REDEMPTIONS":
        data = service.get_redemption_report(from_date, to_date)
        msg = "Redemption report generated"
    elif report_type == "WALLET_UTILIZATION":
        data = service.get_wallet_utilization_report()
        msg = "Wallet utilization report generated"
    elif report_type == "EXPIRY_FORECAST":
        data = service.get_expiry_forecast(days)
        msg = f"Points expiry forecast for next {days} days generated"
    else:
        return client_error(message=f"Invalid report type: {report_type}")

    if export_format == "csv":
        filename = f"{report_type.lower()}_report_{datetime.now().strftime('%Y%m%d')}"
        return generate_csv_response(data, filename)

    return success(
        data={
            "report_type": report_type,
            "generated_at": datetime.now(),
            "data": data
        },
        message=msg
    )


@router.get("/payroll")
def get_payroll_report(
    month: str,  # Format: YYYY-MM
    export_format: str = "json", # json, csv
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """
    Generate monthly payroll encashment report.
    """
    service = AnalyticsService(db)
    try:
        data = service.get_payroll_report(month)
        if export_format == "csv":
            filename = f"payroll_report_{month}_{datetime.now().strftime('%Y%m%d')}"
            return generate_csv_response(data, filename)

        return success(
            data={
                "report_type": "PAYROLL",
                "month": month,
                "generated_at": datetime.now(),
                "data": data
            },
            message=f"Payroll report for {month} generated"
        )
    except Exception as e:
        return client_error(message=str(e))
