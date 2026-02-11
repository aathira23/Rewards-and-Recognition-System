"""
Database connection and session management.
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

# Create database engine
engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()

# Import all model modules so SQLAlchemy registers mappers for relationships
# This ensures relationships referenced by string names (e.g. "Department")
# are available when mappers are configured at runtime.
try:
    from app.models import (
        users,
        departments,
        wallets,
        wallet_funding,
        points_ledger,
        points_batches,
        points_conversion,
        points_policy,
        ecards,
        awards,
        award_approvals,
        award_types,
        badges,
        celebrations,
        recognition_feed,
        redemptions,
        rewards,
        notifications,
    )
except Exception:
    # Import errors during initial setup should not crash the module import.
    pass


def get_db():
    """
    Dependency for getting database session.
    Yields a database session and ensures it's closed after use.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
