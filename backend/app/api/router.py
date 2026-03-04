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
    reports,
    config,
    departments,
    email,
)

api_router = APIRouter()

# Include all sub-routers
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/profile", tags=["User Profiles"])
api_router.include_router(wallets.router, prefix="/budgets", tags=["Budgets & Wallets"])
api_router.include_router(points.router, prefix="/points", tags=["Points Management"])
api_router.include_router(recognitions.router, prefix="/recognitions", tags=["Peer Recognition"])
api_router.include_router(awards.router, prefix="/awards", tags=["awards"])
api_router.include_router(celebrations.router, prefix="/celebrations", tags=["Celebrations"])
api_router.include_router(store.router, prefix="/catalog", tags=["Rewards Catalog"])
api_router.include_router(notifications.router, prefix="/inbox", tags=["Notifications"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
api_router.include_router(reports.router, prefix="/reports", tags=["Reports"])
api_router.include_router(config.router, prefix="/config", tags=["System Configuration"])
api_router.include_router(departments.router, prefix="/departments", tags=["Department Management"])
api_router.include_router(email.router, prefix="/email", tags=["Email Notifications"])
