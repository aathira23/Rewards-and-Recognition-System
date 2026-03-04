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

def import_models():
    """Explicitly import all models to register with Base.metadata."""
    import importlib
    import pkgutil
    import app.models
    
    # Dynamically import all modules in the app.models package
    for loader, module_name, is_pkg in pkgutil.walk_packages(app.models.__path__, app.models.__name__ + "."):
        importlib.import_module(module_name)

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
