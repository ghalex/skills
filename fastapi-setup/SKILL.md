---
name: fastapi-setup
description: This skill should be used when the user asks to "create a new FastAPI project", "setup a fastapi api", "new fastapi project", "scaffold a fastapi app", "initialize a fastapi backend", or "start a new python api". Scaffolds a complete production-ready FastAPI project with SQLAlchemy, PostgreSQL, JWT auth, Pydantic v2 settings, and uv package management.
version: 1.0.0
---

# FastAPI Project Setup

Scaffold a complete, production-ready FastAPI project. Ask the user for the **project name** if not provided (e.g. "myapi"). Use it throughout as `{project}`.

## Project Structure

Create all files exactly as shown. Replace `{project}` with the actual project name.

```
{project}/
├── src/{project}/
│   ├── agents/
│   │   └── __init__.py
│   ├── api/
│   │   ├── routes/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py
│   │   │   └── core.py
│   │   ├── __init__.py
│   │   └── lifespan.py
│   ├── config/
│   │   ├── __init__.py
│   │   └── settings.py
│   ├── db/
│   │   ├── __init__.py
│   │   ├── database.py
│   │   └── models.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── auth.py
│   ├── services/
│   │   ├── __init__.py
│   │   └── auth.py
│   ├── utils/
│   │   ├── __init__.py
│   │   └── auth.py
│   ├── __init__.py
│   └── main.py
├── pyproject.toml
├── justfile
├── Dockerfile
├── docker-compose.yml
├── CLAUDE.md
├── .vscode/
│   └── settings.json
├── .env.example
└── .python-version
```

---

## File Templates

### `pyproject.toml`
```toml
[project]
name = "{project}"
version = "0.1.0"
description = "Add your description here"
requires-python = ">=3.13"
dependencies = [
    "bcrypt>=4.0",
    "email-validator>=2.3.0",
    "fastapi>=0.115.0",
    "psycopg2-binary>=2.9.11",
    "pydantic>=2.10.0",
    "pydantic-settings>=2.7.0",
    "python-jose[cryptography]>=3.5.0",
    "sqlalchemy>=2.0.0",
    "uvicorn>=0.30.0",
]

[project.scripts]
start = "{project}.main:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/{project}"]
only-include = ["src"]
```

### `.env.example`
```
SECRET_KEY=changeme-use-a-long-random-string
PG_DATABASE_URL=postgresql://user:password@localhost:5432/{project}
SQLITE_DATABASE_URL={project}.db
```

### `.python-version`
```
3.13
```

### `Dockerfile`
```dockerfile
# Build: docker build -t {project} .
FROM python:3.13-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

COPY pyproject.toml uv.lock ./
COPY src/ ./src/

RUN uv sync --frozen --no-dev --no-cache

EXPOSE 8000

ENV PYTHONUNBUFFERED=1

CMD [".venv/bin/start"]
```

### `docker-compose.yml`
```yaml
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    image: {project}:latest
    container_name: {project}
    ports:
      - "8000:8000"
    restart: unless-stopped
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - PG_DATABASE_URL=${PG_DATABASE_URL}
      - SQLITE_DATABASE_URL=${SQLITE_DATABASE_URL}
```

### `CLAUDE.md`
```markdown
# CLAUDE.md

Architecture and development rules for this FastAPI project.

## Project Structure

\`\`\`
src/{project}/
├── agents/          # AI agents (LLM reasoning units)
├── api/
│   ├── routes/      # Thin HTTP handlers only
│   ├── lifespan.py  # Startup/shutdown
│   └── __init__.py
├── config/          # Settings (pydantic-settings)
├── db/              # SQLAlchemy engine, session, ORM models
├── models/          # Pydantic models (shared across routes, agents, services)
├── services/        # Business logic
│   ├── __init__.py  # Dependency functions (get_*_service)
│   └── auth.py      # One file per domain
└── utils/           # Stateless helpers (hashing, JWT, etc.)
\`\`\`

## Layer Rules

### Routes (`api/routes/`)
- Thin wrappers only — no business logic, no db queries
- Only call services via `Depends()`
- Import services from `services` not from other routes

### Services (`services/`)
- All business logic lives here
- Receive `db: Session` in `__init__`, never import `get_db` directly
- Can be used by routes AND agents
- Dependency functions (`get_*_service`) go in `services/__init__.py` — not in route files

### Models (`models/`)
- All Pydantic models go here — never inside `api/`
- Shared freely across routes, services, and agents

### Agents (`agents/`)
- AI reasoning units — call LLMs, use tools
- Receive services via constructor, never import `db` or `get_db` directly
- Do not contain business logic — delegate to services

### DB (`db/`)
- `database.py` — engine, session, `get_db`
- `models.py` — SQLAlchemy ORM models using `Mapped` / `mapped_column`
- Only imported in `services/` and `utils/`

## Violations to Flag

- `from {project}.db` imported inside any `api/routes/` file
- `get_db` used directly in a route handler
- Pydantic models defined inside `api/`
- `get_*_service` functions defined inside route files
- Business logic (db queries, data conditionals) inside route handlers
- Agents importing `db` or `Session` directly

## Development Commands

\`\`\`bash
just dev          # start with hot reload
just start        # start production mode
just lint         # ruff check
just lint-fix     # ruff check --fix
just format       # ruff format
just typecheck    # pyright

just docker-build # build image
just docker-up    # start container
just docker-down  # stop container
just docker-logs  # tail logs
\`\`\`

## Adding a New Feature

1. **Model** → `models/{domain}.py`
2. **ORM model** → `db/models.py`
3. **Service** → `services/{domain}.py`
4. **Dependency function** → `services/__init__.py`
5. **Route** → `api/routes/{domain}.py` (thin wrapper)
6. **Register router** → `api/routes/__init__.py` + `main.py`
7. **Agent** (if AI needed) → `agents/{domain}.py`, inject service via constructor
```

### `.vscode/settings.json`
```json
{
  "files.exclude": {
    "**/__pycache__": true,
    "**/*.ruff_cache": true,
    "**/*.pyc": true
  }
}
```

### `justfile`
```just
# Application Commands

start:
    uv run start

dev:
    API_RELOAD=true uv run start

# Development Commands

install:
    uv sync

add package:
    uv add {{package}}

add-dev package:
    uv add --dev {{package}}

update:
    uv lock --upgrade
    uv sync

# Docker

docker-build:
    docker build -t {project}:latest .

docker-up:
    docker compose up -d

docker-down:
    docker compose down

docker-logs:
    docker compose logs -f

# Code Quality

format:
    uv run ruff format .

lint path=".":
    uv run ruff check {{path}}

lint-fix path=".":
    uv run ruff check --fix {{path}}

typecheck path=".":
    uv run pyright {{path}}
```

### `src/{project}/__init__.py`
```python
```

### `src/{project}/main.py`
```python
import os

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from {project}.api.lifespan import lifespan
from {project}.api.routes import auth_router, core_router

app = FastAPI(lifespan=lifespan)

origins = [
    "http://localhost:5173",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
    expose_headers=["Content-Disposition"],
)

app.include_router(core_router)
app.include_router(auth_router)


def main():
    reload = os.getenv("API_RELOAD", "false").lower() == "true"
    if reload:
        uvicorn.run("{project}.main:app", host="0.0.0.0", port=8000, reload=True)
    else:
        uvicorn.run(app, host="0.0.0.0", port=8000)


if __name__ == "__main__":
    main()
```

### `src/{project}/config/__init__.py`
```python
```

### `src/{project}/config/settings.py`
```python
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Secret key for signing JWT tokens
    secret_key: str

    # SQLite database file path (fallback)
    sqlite_database_url: str = "{project}.db"

    # Full PostgreSQL connection string
    pg_database_url: str | None = None

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Return a cached Settings instance."""
    return Settings()


settings = get_settings()
```

### `src/{project}/db/__init__.py`
```python
```

### `src/{project}/db/database.py`
```python
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from {project}.config.settings import settings


def create_sql_light_engine(path: str | None = None):
    if path is None:
        path = settings.sqlite_database_url
    if not path:
        raise ValueError("SQLITE_DATABASE_URL environment variable is not set.")
    return create_engine(f"sqlite:///{path}")


def create_postgres_engine(connection_string: str | None = None):
    if connection_string is None:
        connection_string = settings.pg_database_url
    if not connection_string:
        raise ValueError("PG_DATABASE_URL environment variable is not set.")
    return create_engine(connection_string)


Base = declarative_base()

engine = create_sql_light_engine()
Session = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = Session()
    try:
        yield db
    finally:
        db.close()
```

### `src/{project}/db/models.py`
```python
from datetime import datetime

from sqlalchemy import func
from sqlalchemy.orm import Mapped, mapped_column

from {project}.db.database import Base


class UserRecord(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    email: Mapped[str] = mapped_column(unique=True, nullable=False)
    name: Mapped[str | None] = mapped_column(nullable=True)
    phone: Mapped[str | None] = mapped_column(nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(nullable=True)
    password_hash: Mapped[str | None] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(default=func.now())
```

### `src/{project}/utils/__init__.py`
```python
```

### `src/{project}/utils/auth.py`
```python
from datetime import datetime, timedelta, timezone

import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from {project}.config.settings import settings
from {project}.db.database import get_db
from {project}.db.models import UserRecord

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours

security = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


def create_token(user_id: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode({"sub": str(user_id), "exp": expire}, settings.secret_key, algorithm=ALGORITHM)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
) -> UserRecord:
    if not credentials or credentials.scheme != "Bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization",
        )

    try:
        payload = jwt.decode(credentials.credentials, settings.secret_key, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
        user_id = int(user_id)
    except (JWTError, ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    user = db.query(UserRecord).filter(UserRecord.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user
```

### `src/{project}/api/__init__.py`
```python
```

### `src/{project}/api/lifespan.py`
```python
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import text

from {project}.db.database import Base, engine


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler for startup and shutdown events."""
    print("\n" + "=" * 60)
    print(f"Starting {project} API")
    print("=" * 60)

    Base.metadata.create_all(bind=engine)
    print("Database tables created/verified")

    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
            print("Database connection successful")
    except Exception as e:
        print(f"Database connection failed: {e}")
        print("Application may not function correctly!")

    yield

    engine.dispose()
    print("{project} API shutdown complete")
```

### `src/{project}/agents/__init__.py`
```python
```

### `src/{project}/models/__init__.py`
```python
from .auth import LoginRequest, SignupRequest, TokenResponse, UserResponse

__all__ = ["LoginRequest", "SignupRequest", "TokenResponse", "UserResponse"]
```

### `src/{project}/models/auth.py`
```python
from datetime import datetime

from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class SignupRequest(BaseModel):
    email: EmailStr
    password: str
    name: str | None = None


class UserResponse(BaseModel):
    id: int
    email: str
    name: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
```

### `src/{project}/api/routes/__init__.py`
```python
from .auth import router as auth_router
from .core import router as core_router

__all__ = ["auth_router", "core_router"]
```

### `src/{project}/api/routes/core.py`
```python
from fastapi import APIRouter

router = APIRouter(tags=["core"])


@router.get("/")
def root():
    return {"ok": True, "message": "{project} API is running", "version": "0.1.0"}


@router.get("/healthz")
def healthz():
    return {"ok": True, "service": "{project}-api", "version": "0.1.0"}
```

### `src/{project}/api/routes/auth.py`
```python
from fastapi import APIRouter, Depends, status

from {project}.models import LoginRequest, SignupRequest, TokenResponse
from {project}.services import get_auth_service
from {project}.services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def signup(body: SignupRequest, service: AuthService = Depends(get_auth_service)):
    return service.signup(body)


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, service: AuthService = Depends(get_auth_service)):
    return service.login(body)
```

### `src/{project}/services/__init__.py`
```python
from fastapi import Depends
from sqlalchemy.orm import Session

from {project}.db.database import get_db
from {project}.services.auth import AuthService


def get_auth_service(db: Session = Depends(get_db)) -> AuthService:
    return AuthService(db)
```

### `src/{project}/services/auth.py`
```python
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from {project}.db.models import UserRecord
from {project}.models import LoginRequest, SignupRequest, TokenResponse, UserResponse
from {project}.utils.auth import create_token, hash_password, verify_password


class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def signup(self, body: SignupRequest) -> TokenResponse:
        if self.db.query(UserRecord).filter(UserRecord.email == body.email).first():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT, detail="Email already registered"
            )

        user = UserRecord(
            email=body.email,
            name=body.name,
            password_hash=hash_password(body.password),
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)

        return TokenResponse(
            access_token=create_token(user.id),
            user=UserResponse.model_validate(user),
        )

    def login(self, body: LoginRequest) -> TokenResponse:
        user = self.db.query(UserRecord).filter(UserRecord.email == body.email).first()

        if (
            not user
            or not user.password_hash
            or not verify_password(body.password, user.password_hash)
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )

        return TokenResponse(
            access_token=create_token(user.id),
            user=UserResponse.model_validate(user),
        )
```

---

## Empty `__init__.py` files

Create empty `__init__.py` for all packages that don't have content listed above.

---

## After Scaffolding — Tell the User

Once all files are created, tell the user:

```bash
# Install dependencies with uv
uv sync

# Copy env file and fill in your values
cp .env.example .env

# Start the dev server
uv run start
```

The API will be at `http://localhost:8000`. Endpoints:
- `GET /healthz` — health check (no auth)
- `POST /auth/signup` — create account, returns JWT
- `POST /auth/login` — login, returns JWT
- `GET /` — protected root (requires `Authorization: Bearer <token>`)

To protect any route, add `user: UserRecord = Depends(get_current_user)` as a parameter.

---

## Important Notes

- **PostgreSQL is required** by default. The `PG_DATABASE_URL` in `.env` must be set before running.
- Tables are auto-created on startup via `Base.metadata.create_all()` — no migrations needed to start.
- To add new models: extend `src/{project}/db/models.py`, then add routes/services as needed.
- To add new routes: create `src/{project}/api/routes/mything.py`, export the router in `routes/__init__.py`, and include it in `main.py`.
