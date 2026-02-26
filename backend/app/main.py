"""
FastAPI application entry point for Rewards & Recognition System.
"""
import re
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

from app.core.config import settings
from app.api.router import api_router

app = FastAPI(
    title=settings.APP_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# ---------------------------------------------------------------------------
# Outermost CORS-safety middleware
# ---------------------------------------------------------------------------
# Starlette's ServerErrorMiddleware (wrapping everything) can generate bare
# 500 responses that bypass CORSMiddleware — e.g. when a PydanticSerializationError
# is raised *after* an endpoint returns (during response encoding). Browsers
# then see a response with no Access-Control-Allow-Origin and report a CORS
# block even though CORS is configured correctly.
#
# This middleware runs outermost (added last ⟹ executes first) and patches
# CORS headers onto any response that is missing them, as a safety net.
_CORS_ORIGIN_RE = re.compile(
    r"https?://(localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?"
)

class CorsErrorSafetyMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        origin = request.headers.get("origin", "")
        try:
            response = await call_next(request)
        except Exception:
            response = Response(
                content='{"status":"error","message":"Internal server error"}',
                status_code=500,
                media_type="application/json",
            )
        # Inject CORS headers if they are absent and the origin is allowed.
        if origin and "access-control-allow-origin" not in response.headers:
            if _CORS_ORIGIN_RE.match(origin) or settings.ALLOWED_ORIGINS not in ("*", ""):
                response.headers["Access-Control-Allow-Origin"] = origin
                response.headers["Access-Control-Allow-Credentials"] = "true"
                response.headers["Vary"] = "Origin"
        return response

app.add_middleware(CorsErrorSafetyMiddleware)

# CORS middleware
# When ALLOWED_ORIGINS is "*" (dev mode), use allow_origin_regex to echo back
# the actual request origin. This is required because browsers reject
# "Access-Control-Allow-Origin: *" when allow_credentials=True.
if settings.ALLOWED_ORIGINS == "*":
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS.split(","),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

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


# Global exception handler.
# IMPORTANT: exception handlers registered via @app.exception_handler are
# invoked by Starlette's ExceptionMiddleware, which sits INSIDE the
# CORSMiddleware. This means their responses DO pass through CORSMiddleware
# and receive the correct CORS headers — unlike bare 500s from
# ServerErrorMiddleware (which is outside CORS).
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    import logging
    from fastapi.responses import JSONResponse
    logging.error(f"Unhandled error on {request.url}: {exc}", exc_info=True)
    try:
        from app.utils.response import server_error
        return server_error(message="Internal server error occurred.")
    except Exception:
        return JSONResponse(
            status_code=500,
            content={"status": "error", "message": "Internal server error occurred."},
        )
