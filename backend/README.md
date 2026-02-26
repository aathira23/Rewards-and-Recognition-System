# Rewards & Recognition System - Backend

## Tech Stack
- **Python 3.11+**
- **FastAPI** - Modern web framework
- **SQLAlchemy** - ORM
- **Alembic** - Database migrations
- **Pydantic** - Data validation
- **PostgreSQL** - Database

## Setup

1. Create and activate virtual environment:
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

3. Configure environment variables in `.env`

4. Run database migrations:
```bash
alembic revision --autogenerate -m "Initial schema"
alembic upgrade head
```

5. Start the development server:
```bash
uvicorn app.main:app --reload
```

**Note:** Always activate the virtual environment before running any commands:
```bash
source venv/bin/activate  # Linux/Mac
```

## Project Structure

```
backend/
├── app/
│   ├── main.py              # Application entry point
│   ├── core/                # Core configuration
│   ├── models/              # SQLAlchemy models
│   ├── schemas/             # Pydantic schemas
│   ├── api/                 # API routes
│   ├── services/            # Business logic
│   ├── utils/               # Utilities
│   └── jobs/                # Background jobs
├── alembic/                 # Database migrations
└── requirements.txt
```

## API Documentation

Once running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
