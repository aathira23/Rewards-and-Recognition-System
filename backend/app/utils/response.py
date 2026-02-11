from __future__ import annotations

from datetime import datetime
from typing import Any, Optional

from fastapi import status as http_status
from fastapi.responses import JSONResponse
from pydantic import BaseModel


from fastapi.encoders import jsonable_encoder

def _now_iso() -> str:
    return datetime.utcnow().isoformat() + "Z"


class CommonResponse(BaseModel):
    status: str
    status_code: int
    message: Optional[str] = ""
    data: Optional[Any] = None
    timestamp: str

    class Config:
        from_attributes = True


def _build_body(status_text: str, status_code: int, message: str | None, data: Any) -> Any:
    response = CommonResponse(
        status=status_text,
        status_code=status_code,
        message=message or "",
        data=data,
        timestamp=_now_iso(),
    )
    return jsonable_encoder(response)


def success(data: Any = None, message: str | None = "OK", status_code: int = http_status.HTTP_200_OK) -> JSONResponse:
    body = _build_body("success", status_code, message, data)
    return JSONResponse(status_code=status_code, content=body)


def created(data: Any = None, message: str | None = "Created") -> JSONResponse:
    return success(data=data, message=message, status_code=http_status.HTTP_201_CREATED)


def no_content(message: str | None = "No content") -> JSONResponse:
    body = _build_body("success", http_status.HTTP_204_NO_CONTENT, message, None)
    return JSONResponse(status_code=http_status.HTTP_204_NO_CONTENT, content=body)


def client_error(message: str | None = "Bad request", data: Any = None, status_code: int = http_status.HTTP_400_BAD_REQUEST) -> JSONResponse:
    body = _build_body("error", status_code, message, data)
    return JSONResponse(status_code=status_code, content=body)


def unauthorized(message: str | None = "Unauthorized", data: Any = None) -> JSONResponse:
    return client_error(message=message, data=data, status_code=http_status.HTTP_401_UNAUTHORIZED)


def forbidden(message: str | None = "Forbidden", data: Any = None) -> JSONResponse:
    return client_error(message=message, data=data, status_code=http_status.HTTP_403_FORBIDDEN)


def not_found(message: str | None = "Not found", data: Any = None) -> JSONResponse:
    return client_error(message=message, data=data, status_code=http_status.HTTP_404_NOT_FOUND)


def conflict(message: str | None = "Conflict", data: Any = None) -> JSONResponse:
    return client_error(message=message, data=data, status_code=http_status.HTTP_409_CONFLICT)


def server_error(message: str | None = "Internal server error", data: Any = None) -> JSONResponse:
    body = _build_body("error", http_status.HTTP_500_INTERNAL_SERVER_ERROR, message, data)
    return JSONResponse(status_code=http_status.HTTP_500_INTERNAL_SERVER_ERROR, content=body)
