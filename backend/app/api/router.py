"""
API router initialization and aggregation.
"""
from fastapi import APIRouter

from app.api import (
    auth,
    users,
    wallets,
    points,
    recognitions,
    awards,
    celebrations,
    store,
    notifications,
    analytics,
    reports
)

api_router = APIRouter()

# Include all sub-routers
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(wallets.router, prefix="/wallets", tags=["Wallets"])
api_router.include_router(points.router, prefix="/points", tags=["Points"])
api_router.include_router(recognitions.router, prefix="/recognitions", tags=["Recognitions"])
api_router.include_router(awards.router, prefix="/awards", tags=["Awards"])
api_router.include_router(celebrations.router, prefix="/celebrations", tags=["Celebrations"])
api_router.include_router(store.router, prefix="/store", tags=["Store"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
api_router.include_router(reports.router, prefix="/reports", tags=["Reports"])
