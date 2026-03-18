"""
FastAPI application entry point for Rewards & Recognition System.
"""
import logging

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.config import settings
from app.exceptions.handler import http_exception_handler, validation_exception_handler
from app.routers.router import api_router
from app.utils.response import build_response, FAILURE_MESSAGE

app = FastAPI(
    title=settings.APP_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# ─── CORS Middleware ──────────────────────────────
_origins = (
    [o.strip() for o in settings.ALLOWED_ORIGINS.split(",") if o.strip()]
    if settings.ALLOWED_ORIGINS and settings.ALLOWED_ORIGINS != "*"
    else ["*"]
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Exception Handlers───────────────────────────
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(StarletteHTTPException, http_exception_handler)

# Include API router
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/")
def root():
    """Root endpoint."""
    return {"message": "Rewards & Recognition System"}


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Catch-all for unhandled exceptions."""
    logging.error(f"Unhandled error on {request.url}: {exc}", exc_info=True)
    return build_response(500, FAILURE_MESSAGE, "Internal server error occurred.", None)
