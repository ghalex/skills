# fastapi-setup

Claude Code skill that scaffolds a complete, production-ready FastAPI project.

## Install

```bash
npx skills add ghalex/skills --skill fastapi-setup
```

## Usage

Just tell Claude:

> "create a new FastAPI project in dir myapi"
> "scaffold a fastapi app called myapi"
> "new fastapi project"

## What gets generated

```
myapi/
├── src/myapi/
│   ├── agents/          # AI agents
│   ├── api/
│   │   ├── routes/      # Thin HTTP handlers
│   │   └── lifespan.py
│   ├── config/          # pydantic-settings
│   ├── db/              # SQLAlchemy models + session
│   ├── models/          # Pydantic models (shared)
│   ├── services/        # Business logic + Depends functions
│   └── utils/           # JWT, password hashing
├── Dockerfile
├── docker-compose.yml
├── justfile
├── CLAUDE.md
├── .vscode/settings.json
├── .env.example
└── pyproject.toml
```

## Commands after scaffolding

```bash
uv sync
cp .env.example .env
just dev        # start with hot reload
just start      # production mode
just lint       # ruff check
just format     # ruff format
just docker-build && just docker-up
```

## Architecture

- **Routes** → thin wrappers, call services via `Depends()`
- **Services** → business logic, injected via `services/__init__.py`
- **Models** → Pydantic models at top level, shared everywhere
- **Agents** → receive services via constructor, never touch db directly
- **CLAUDE.md** → architecture rules loaded automatically on every session
