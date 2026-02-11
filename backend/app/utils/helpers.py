"""
Helper utility functions.
"""
from datetime import datetime, date
from typing import Optional


def calculate_points_expiry(source_date: date, expiry_days: int = 365) -> date:
    """
    Calculate expiry date for points batch.

    Args:
        source_date: Date when points were awarded
        expiry_days: Number of days until expiry

    Returns:
        Expiry date
    """
    from datetime import timedelta
    return source_date + timedelta(days=expiry_days)


def format_currency(amount: float) -> str:
    """
    Format amount as currency string.

    Args:
        amount: Amount to format

    Returns:
        Formatted currency string
    """
    return f"₹{amount:,.2f}"


def get_financial_year(dt: Optional[datetime] = None) -> str:
    """
    Get financial year for a given date.

    Args:
        dt: Date to get financial year for (defaults to now)

    Returns:
        Financial year string (e.g., "2024-25")
    """
    if dt is None:
        dt = datetime.now()

    year = dt.year
    if dt.month >= 4:  # April onwards
        return f"{year}-{str(year + 1)[-2:]}"
    else:
        return f"{year - 1}-{str(year)[-2:]}"
