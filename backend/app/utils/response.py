"""
Standardised response builder matching company microservice pattern.

All endpoints return:
    {
        "statusCode": 200,
        "statusMessage": "Success",
        "errorMessage": null,
        "responseData": { ... }
    }
"""
from __future__ import annotations

from typing import Any, Optional

from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from starlette.status import (
    HTTP_200_OK,
    HTTP_201_CREATED,
    HTTP_204_NO_CONTENT,
    HTTP_400_BAD_REQUEST,
    HTTP_401_UNAUTHORIZED,
    HTTP_403_FORBIDDEN,
    HTTP_404_NOT_FOUND,
    HTTP_409_CONFLICT,
    HTTP_500_INTERNAL_SERVER_ERROR,
)

# Standard status messages
SUCCESS_MESSAGE = "Success"
FAILURE_MESSAGE = "Failed"


class ResponseBuilder(BaseModel):
    status_code: int
    status_message: str
    error_message: Optional[Any] = None
    response_data: Optional[Any] = None


def build_response(
    status_code: int,
    status_message: str,
    error_message: Any = None,
    response_data: Any = None,
) -> JSONResponse:
    """Primary response builder — company standard format."""
    encoded_data = jsonable_encoder(response_data)
    return JSONResponse(
        status_code=status_code,
        content={
            "statusCode": status_code,
            "statusMessage": status_message,
            "errorMessage": error_message,
            "responseData": encoded_data,
        },
    )


# ─── Convenience wrappers (keep existing call-sites working) ────────

def success(
    data: Any = None,
    message: str | None = None,
    status_code: int = HTTP_200_OK,
) -> JSONResponse:
    return build_response(status_code, SUCCESS_MESSAGE, None, data)


def paginated_success(
    *,
    items: Any,
    total: int,
    page: int,
    per_page: int,
    message: str | None = None,
) -> JSONResponse:
    """Paginated list response — pagination metadata in responseData."""
    import math

    total_pages = math.ceil(total / per_page) if per_page > 0 else 0
    payload = {
        "items": items,
        "total": total,
        "page": page,
        "per_page": per_page,
        "total_pages": total_pages,
    }
    return build_response(HTTP_200_OK, SUCCESS_MESSAGE, None, payload)


def created(data: Any = None, message: str | None = None) -> JSONResponse:
    return build_response(HTTP_201_CREATED, SUCCESS_MESSAGE, None, data)


def no_content(message: str | None = None) -> JSONResponse:
    return build_response(HTTP_204_NO_CONTENT, SUCCESS_MESSAGE, None, None)


def client_error(
    message: str | None = "Bad request",
    data: Any = None,
    status_code: int = HTTP_400_BAD_REQUEST,
) -> JSONResponse:
    return build_response(status_code, FAILURE_MESSAGE, message, data)


def unauthorized(message: str | None = "Unauthorized", data: Any = None) -> JSONResponse:
    return build_response(HTTP_401_UNAUTHORIZED, FAILURE_MESSAGE, message, data)


def forbidden(message: str | None = "Forbidden", data: Any = None) -> JSONResponse:
    return build_response(HTTP_403_FORBIDDEN, FAILURE_MESSAGE, message, data)


def not_found(message: str | None = "Not found", data: Any = None) -> JSONResponse:
    return build_response(HTTP_404_NOT_FOUND, FAILURE_MESSAGE, message, data)


def conflict(message: str | None = "Conflict", data: Any = None) -> JSONResponse:
    return build_response(HTTP_409_CONFLICT, FAILURE_MESSAGE, message, data)


def server_error(message: str | None = "Internal server error", data: Any = None) -> JSONResponse:
    return build_response(HTTP_500_INTERNAL_SERVER_ERROR, FAILURE_MESSAGE, message, data)
