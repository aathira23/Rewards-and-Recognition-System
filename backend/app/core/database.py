"""
Database connection and session management.
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

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
def import_models():
    """Explicitly import all models to register with Base.metadata."""
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

import_models()


# Ensure certain optional/dev columns exist to avoid runtime errors when the
# DB was created without newer columns (helps local/dev setups where migrations
# were stamped but not applied). Uses a safe "IF NOT EXISTS" ALTER.
from sqlalchemy import text
from app.core.config import settings

# Only run this best-effort ALTER in development/debug mode. Production
# environments should use Alembic migrations to manage schema changes.
if getattr(settings, "DEBUG", False):
    try:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE rewards ADD COLUMN IF NOT EXISTS image_url VARCHAR;"))
    except Exception:
        # Best-effort only; don't raise so app can continue to start.
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
