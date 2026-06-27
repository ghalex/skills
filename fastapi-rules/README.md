# fastapi-rules

Claude Code skill that defines FastAPI architecture rules for both development and auditing. Loaded by dev agents when implementing features and by review agents when auditing code.

## Install

```bash
npx skills add zenve-ai/zenve-registry/skills --skill fastapi-rules
```

## Usage

**When developing:**

> "add a new route"
> "add a new service"
> "implement this endpoint"
> "add a new feature"

**When auditing:**

> "review my routes"
> "check architecture"
> "audit this project"
> "does this follow the fastapi rules"
> "review my code structure"

## What it covers

**Layout detection** — monorepo (`apps/` + `packages/`) vs standalone (`src/{project}/`), with a full path map for each

**Routes** — thin wrappers only, no business logic, no db queries, auth patterns, membership guards, violations to flag

**Services** — all business logic here, `__init__.py` wiring pattern, chaining rules

**Models** — Pydantic models in `packages/models/`, ORM models in `packages/db/` using SQLAlchemy 2.x `Mapped` style, standard new-feature flow

**Utils** — stateless helpers only, what belongs (`auth.py`, `hashing.py`, `testing.py`), violations to flag

**Agents** — no direct db access, services injected via constructor

**General** — CORS, lifespan typing

## Architecture Review output (architect agents only)

```
## Architecture Review

### ✅ Passing
- Models correctly placed in packages/models/
- ...

### ❌ Violations
#### apps/api/src/api/routes/users.py
- **Rule:** No db queries inside route handlers
- **Found:** db.query(UserRecord)... called directly in route
- **Fix:** Move to UserService.get_user() and inject via Depends(get_user_service)

### Summary
2 violations found in 1 file.
```
