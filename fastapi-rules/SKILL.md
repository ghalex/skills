---
name: fastapi-rules
description: FastAPI architecture rules for both auditing and development. Use when asked to "review routes", "check architecture", "audit this project", "does this follow fastapi rules", "review my code structure", "add a new feature", "add a new route", "add a new service", "implement this endpoint", or when starting any FastAPI development task.
version: 1.2.0
---

# FastAPI Architecture Rules

> This skill is the **definitive source** for FastAPI architecture rules. Any agent (architect, dev, or otherwise) should load this skill for authoritative rules on routes, services, models, utils, and monorepo layout.

---

## Step 0: Detect Layout

Before auditing or implementing, determine which layout the project uses:

**Monorepo** — if any of these are true:
- Root `pyproject.toml` contains `[tool.uv.workspace]`
- An `apps/` directory and a `packages/` directory both exist at the root

**Standalone** — otherwise (single `src/{project}/` layout)

State the detected layout at the top of your report.

---

## Architecture Rules

The rules are the same for both layouts. Only the **paths differ**.

### Path Map

| Concept | Standalone | Monorepo |
|---|---|---|
| Routes | `src/{project}/api/routes/` | `apps/*/src/api/routes/` |
| Services | `src/{project}/services/` | `packages/services/src/{project_slug}_services/` |
| Models (Pydantic) | `src/{project}/models/` | `packages/models/src/{project_slug}_models/` |
| DB (ORM + session) | `src/{project}/db/` | `packages/db/src/{project_slug}_db/` |
| Utils | `src/{project}/utils/` | `packages/utils/src/{project_slug}_utils/` |
| Config | `src/{project}/config/` | `packages/config/src/{project_slug}_config/` |
| Main | `src/{project}/main.py` | `apps/*/src/api/main.py` |
| Service deps | `services/__init__.py` | `{project_slug}_services/__init__.py` |

In a monorepo, also check:
- [ ] Each `packages/*/pyproject.toml` only declares dependencies it actually needs (no over-importing)
- [ ] Internal workspace deps use `{ workspace = true }` in `[tool.uv.sources]`, not pinned versions
- [ ] Route files do NOT import directly from `{project_slug}_db` — they go through services
- [ ] The `packages/services/` package does not import from `apps/`

**Dependency chain (enforced):**
```
{project_slug}-config   (no deps)
{project_slug}-db       → {project_slug}-config
{project_slug}-models   → (pydantic only)
{project_slug}-utils    → {project_slug}-config, {project_slug}-db
{project_slug}-services → {project_slug}-db, {project_slug}-models, {project_slug}-utils
apps/api                → all packages above
```

**Adding a new package:**
1. Create `packages/{name}/pyproject.toml` with `name = "{project_slug}-{name}"`
2. Create `packages/{name}/src/{project_slug}_{name}/__init__.py`
3. Add to workspace root `pyproject.toml`: `[tool.uv.sources]` entry
4. Run `uv sync`

---

### Route Rules

- [ ] No db queries inside route handlers
- [ ] No business logic inside route handlers
- [ ] Routes only call services via `Depends()`
- [ ] `get_*_service` functions are NOT defined in route files
- [ ] No direct db imports in route files (`from {project}.db` / `from {project_slug}_db`)
- [ ] No `Session` or `get_db` used directly in route handlers
- [ ] No underscore prefix on functions — use `def my_func`, not `def _my_func`

**Auth patterns:**
- JWT (user sessions): `get_current_user()` from `{project_slug}_utils.auth` → returns `UserRecord`
- API key (programmatic): `get_current_org()` from `{project_slug}_services.api_key_auth` → returns `(Organization, ApiKeyRecord)`
  - Scope-based access: `require_scope("resource:action")` for fine-grained control

**Membership guards:**
- `MembershipService.require_membership()` — verify user belongs to org (403 if not)
- `MembershipService.require_role()` — verify specific role(s) (403 if not)
- Roles: `owner`, `admin`, `member`

**Registering a new router:**
1. Create `apps/api/src/api/routes/{domain}.py`
2. Add to `apps/api/src/api/routes/__init__.py`
3. Mount in `main.py`

**Violations to flag:**
- `{project_slug}_db` imported inside any `apps/api/routes/` file
- `get_db` used directly in a route handler
- Pydantic models defined inside `apps/api/`
- Business logic (DB queries, conditionals) inside route handlers

---

### Service Rules

- [ ] All business logic lives in services
- [ ] Services receive `db: AsyncSession` in `__init__`, never import `get_db` directly
- [ ] Dependency functions (`get_*_service`) live in `{project_slug}_services/__init__.py`
- [ ] No underscore prefix on functions

**`__init__.py` pattern — every service must be wired here:**
```python
from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from {project_slug}_db.database import get_db
from {project_slug}_services.auth import AuthService
from {project_slug}_services.membership import MembershipService

# Example services
def get_auth_service(db: AsyncSession = Depends(get_db)) -> AuthService:
    return AuthService(db)

def get_membership_service(db: AsyncSession = Depends(get_db)) -> MembershipService:
    return MembershipService(db)
```

**Chaining rules:**
- One `get_*` function per service — no exceptions
- Services that depend on other services must chain via `Depends(get_*)`, never instantiate them inline
- Services bound to `app.state` (singletons like registries, WS managers) are fetched via `request: Request`
- Routes always use `Depends(get_*_service)` — never call `SomeService(db)` directly in a handler

---

### Model Rules

#### Pydantic models (`packages/models/`)

- [ ] All Pydantic models are in the models layer, not inside `api/` or route files
- Location: `packages/models/src/{project_slug}_models/{domain}.py`
- Shared freely across routes, services, and utils
- Never defined inside `apps/api/`

#### ORM models (`packages/db/`)

- [ ] ORM models use `Mapped` / `mapped_column` (SQLAlchemy 2.x style)
- [ ] No `Column(Integer, ...)` legacy style
- Location: `packages/db/src/{project_slug}_db/models.py`
- Only imported by services and utils

**Standard new-feature flow:**
1. Pydantic model → `packages/models/src/{project_slug}_models/{domain}.py`
2. ORM model → `packages/db/src/{project_slug}_db/models.py`
3. Service → `packages/services/src/{project_slug}_services/{domain}.py`
4. Dependency function → `{project_slug}_services/__init__.py`
5. Route → `apps/api/src/api/routes/{domain}.py` (thin wrapper)
6. Register router → `apps/api/src/api/routes/__init__.py` + `main.py`

---

### Utils Rules

**Location:** `packages/utils/src/{project_slug}_utils/`

- [ ] Pure, stateless helpers only — no business logic, no DB queries
- [ ] Organized by concern (e.g. `auth.py`, `hashing.py`, `testing.py`)
- [ ] Never add utility functions directly in services or routes — put them here and import
- [ ] No side effects: utils must not call DB, send requests, or mutate state
- [ ] Test helpers go in `testing.py`, not in `conftest.py` or individual test files

**What belongs here:**
- `auth.py` — `get_current_user()` FastAPI dependency, JWT encode/decode
- `hashing.py` — `hash_password()`, `verify_password()`
- `testing.py` — test fixtures, factory helpers, shared test utilities

**Violations to flag:**
- `hash_password` / `verify_password` defined inside a service
- JWT logic duplicated in a route handler
- Test factory functions defined in `conftest.py` instead of `{project_slug}_utils.testing`

---

### Agent Rules (if agents exist)

- [ ] Agents do not import `db`, `Session`, or `get_db` directly
- [ ] Agents receive services via constructor injection
- [ ] Agents do not contain business logic — they delegate to services

---

### General

- [ ] `lifespan` function has `app: FastAPI` type annotation
- [ ] CORS configured in `main.py`

---

## Auditing a project

These rules are the source of truth for auditing as well. When reviewing an existing project against them, use the **`fastapi-architect`** skill — it defines the review process and report format and audits against the rules above (including Step 0 layout detection and the Path Map).
