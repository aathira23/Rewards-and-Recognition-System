"""
Centralised exception handlers matching company microservice pattern.

Registered in main.py via:
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
"""
from fastapi import Request
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.utils.response import build_response, FAILURE_MESSAGE


async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """Handle HTTPException — returns standardised error response."""
    return build_response(exc.status_code, FAILURE_MESSAGE, exc.detail, None)


async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle Pydantic RequestValidationError — extracts missing fields."""
    errors = exc.errors()
    missing_fields = [
        err.get("loc", ["unknown"])[-1]
        for err in errors
        if err.get("type") == "missing"
    ]
    if missing_fields:
        message = f"Missing required fields: {', '.join(str(f) for f in missing_fields)}"
    else:
        message = str(errors)
    return build_response(400, FAILURE_MESSAGE, message, None)
