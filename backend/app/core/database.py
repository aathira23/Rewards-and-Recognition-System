"""
Database connection and session management.
"""
from sqlalchemy import create_engine, URL
from sqlalchemy.orm import sessionmaker, declarative_base

from app.core.config import settings


def get_db_url(cfg) -> URL | str:
    """Build a SQLAlchemy connection URL based on DB_TYPE setting."""
    if cfg.DB_TYPE == "mysql":
        mysql_connection_string = (
            f"DRIVER=MySQL ODBC 9.0 ANSI Driver;"
            f"SERVER={cfg.MYSQL_DB_SERVER};"
            f"DATABASE={cfg.MYSQL_DB_NAME};"
            f"USER={cfg.MYSQL_DB_USER};"
            f"PASSWORD={cfg.MYSQL_DB_PASSWORD};"
        )
        return URL.create("mysql+pyodbc", query={"odbc_connect": mysql_connection_string})
    elif cfg.DB_TYPE == "mssql":
        conn_str = (
            f"DRIVER=ODBC Driver 17 for SQL Server;"
            f"SERVER={cfg.MSSQL_DB_SERVER};"
            f"DATABASE={cfg.MSSQL_DB_NAME};"
            f"UID={cfg.MSSQL_DB_USER};"
            f"PWD={cfg.MSSQL_DB_PASSWORD};"
        )
        return URL.create("mssql+pyodbc", query={"odbc_connect": conn_str})
    elif cfg.DB_TYPE == "postgresql":
        # Allow a full DATABASE_URL override (legacy / CI environments).
        if cfg.DATABASE_URL:
            return cfg.DATABASE_URL
        return URL.create(
            "postgresql+psycopg2",
            username=cfg.POSTGRES_DB_USER,
            password=cfg.POSTGRES_DB_PASSWORD,
            host=cfg.POSTGRES_DB_SERVER,
            port=cfg.POSTGRES_DB_PORT,
            database=cfg.POSTGRES_DB_NAME,
            query=({"options": f"-csearch_path={cfg.POSTGRES_DB_SCHEMA}"}
                   if cfg.POSTGRES_DB_SCHEMA else {}),
        )
    else:
        raise ValueError(
            f"Unknown DB_TYPE '{cfg.DB_TYPE}'. Must be one of: mysql, postgresql, mssql"
        )


DATABASE_URL = get_db_url(settings)

# Create database engine
engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_size=10, max_overflow=20)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


def import_models():
    """Explicitly import all models to register with Base.metadata."""
    import importlib
    import pkgutil
    import app.models

    for loader, module_name, is_pkg in pkgutil.walk_packages(
        app.models.__path__, app.models.__name__ + "."
    ):
        importlib.import_module(module_name)


import_models()


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

