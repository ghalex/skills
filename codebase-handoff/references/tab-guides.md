# Tab Guides — fields, detection method, evidence

## Shared conventions

- Wrap each logical group in `<div class="card">`.
- Use the field row pattern for key/value facts:
  ```html
  <div class="field"><div class="field-label">Primary language</div>
    <div class="field-value">Python 3.12 <span class="badge detected">detected</span></div></div>
  ```
- Badge each uncertain fact: `<span class="badge detected">detected</span>`,
  `<span class="badge inferred">inferred</span>`, or
  `<span class="badge missing">not detected</span>`.
- End every `<section>` (or each major card) with an evidence line:
  ```html
  <div class="evidence"><b>Source evidence:</b> <code>pyproject.toml</code>,
    <code>app/main.py</code></div>
  ```
- Detection method below tells you which files/commands reveal each fact. Prefer
  reading manifests and config over guessing. In monorepos, repeat per app and
  label which app each fact belongs to.

---

## Tab 0 — Overview

**Purpose:** "What is this repository?" Only repo-detectable facts.

| Field | How to detect |
|---|---|
| Repository name | Top-level dir name; `name` in root manifest; git remote. |
| Primary language(s) | File-extension histogram; manifests (`pyproject.toml`, `package.json`, `*.gradle`, `*.xcodeproj`). |
| Frameworks/libraries | Dependencies in manifests (FastAPI, React, etc.). |
| Package manager | Lockfiles: `package-lock.json`/`pnpm-lock.yaml`/`yarn.lock`, `poetry.lock`/`uv.lock`, `Gemfile.lock`. |
| Number of files | `git ls-files | wc -l` (or `find` excluding `.git`/`node_modules`). |
| Number of directories/modules | Count of top-level + significant dirs. |
| Apps/services detected | Sub-projects each with their own manifest (monorepo). List each. |
| Important folders | `src/`, `app/`, `api/`, `web/`, `migrations/`, etc. — one line each. |
| Build tools | `vite`/`webpack`/`gradle`/`xcodebuild`/`docker`. |
| Test tools | `pytest`/`jest`/`vitest`/`junit`/`XCTest`. |
| Database/ORM detected | Drivers/ORMs in deps; `alembic/`, `prisma/`, `*.sql`. |
| API style detected | REST (route decorators), GraphQL (`schema.graphql`), gRPC (`*.proto`). |
| Deployment tooling detected | `Dockerfile`, `.github/workflows/`, `*.tf`, `k8s/`, `fly.toml`, `render.yaml`. |
| External services referenced | SDKs/config: Stripe, S3, Firebase, Sentry, OAuth providers. |
| Existing docs found | `README*`, `docs/`, `CONTRIBUTING*`, `*.md`. |
| Missing expected docs | Of {README, architecture, deployment, DB, API, local-dev}, which are absent. |
| Documentation completeness score | See below. |

**Completeness score:** score the 6 expected doc areas (README, architecture,
deployment, database, API, local-dev). Each present & substantive = 1. Report
`N/6` plus a one-line rationale. This is a heuristic — badge it `inferred`.

---

## Tab 1 — Architecture

**Purpose:** "How does the system work?"

| Field | How to detect |
|---|---|
| Architecture diagram | Layered Mermaid `flowchart LR` — labeled layer subgraphs, brand-logo nodes, pale layer colors, and labeled edges (REST/WS/ORM/push/…). See `mermaid-guide.md`. |
| System context | Entry points (`main.py`, `index.ts`, `Application`), what the system does. |
| Main components | Top-level modules/packages/services. |
| Component responsibilities | One line each, from module names + key files. |
| Component relationships | Imports/calls between components. |
| Data flow | How data moves request→store→response. |
| Request flow | Route → middleware → handler → service → repo. |
| Internal dependencies | Cross-module imports. |
| External system interactions | Outbound calls to third-party APIs/DBs/queues. |
| Architecture assumptions/inferences | Anything reasoned, not directly stated — badge `inferred`. |

Place the Mermaid diagram in a `<pre class="mermaid arch">…</pre>` block (the
`arch` class gives it animated edges + hover lift), then the prose cards, then the
evidence line. Author it with logos + layer colors per `mermaid-guide.md`, and
verify it actually renders (not blank) when you open the HTML in Phase 6.

---

## Tab 2 — Deployment & Infrastructure

| Field | How to detect |
|---|---|
| Deployment overview | Synthesize from the files below. |
| Deployment technologies detected | Dockerfile, compose, PaaS configs. |
| Infrastructure detected | Docker/K8s/Terraform/serverless files. |
| CI/CD pipelines | `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`. |
| Build process | Build steps from CI + Dockerfile + manifest scripts. |
| Runtime services | Services in compose/k8s (app, db, cache, worker). |
| Environment variables (names only) | `.env.example`, `os.getenv`/`process.env`, settings classes. **Names only.** |
| Required ports | `EXPOSE`, `ports:` in compose, server bind config. |
| Configuration files | `*.yml`/`*.toml`/`*.ini`/`*.json` config. |
| Deployment-related files found | Enumerate the files cited above. |

---

## Tab 3 — Database

| Field | How to detect |
|---|---|
| Database technology | Driver/connection string scheme (`postgresql://`, `mysql://`, `mongodb://`). |
| ORM/query library | SQLAlchemy/Prisma/TypeORM/Django ORM in deps. |
| Schema overview | Model definitions; migration files. |
| Main entities | Model/table classes. |
| Entity relationships | FKs/relationship declarations → domain-split Mermaid ER diagrams. |
| Migrations | `alembic/versions/`, `prisma/migrations/`, `db/migrate/`. |
| Seed data | `seed*`, fixtures. |
| Connection configuration | Where the DB URL/env var is read (name only). |
| ER diagram | **Domain-split** Mermaid `erDiagram`s — every detected table included, each entity with PK/FK + key columns + crow's-foot cardinality. See `mermaid-guide.md`. |
| Database-related files | Enumerate models/migrations/config. |

---

## Tab 4 — API

**Derive the endpoint list from SOURCE, not from docs.** Do NOT rely on a README,
a committed OpenAPI/Swagger JSON, or a Postman collection for the list — they are
often stale or incomplete. Build the list yourself by reading the route source:
find every router file (e.g. `grep -rn "include_router"` for the mount list, then
each router's `prefix=` and every method decorator: `@router.get/post/put/patch/delete/websocket`,
or `@app.route`, Express `router.get(...)`, NestJS `@Get()`, etc.). Reconstruct
each full path as `version_mount + router_prefix + decorator_path`.

| Field | How to detect |
|---|---|
| API type | REST/GraphQL/gRPC from route style. |
| Authentication methods | JWT/OAuth/session/API-key middleware & deps. |
| Base routes | Router prefixes/version mounts (`/v1`). |
| **Complete endpoint list** | EVERY route from source (see above), grouped by resource. Use a `<table>`. |
| Request/response models | The request body schema + response model per endpoint (Pydantic/serializer/DTO classes). Summarize key fields. |
| Error responses detected | Error handlers, status codes, exception mappers. |
| Middleware | Registered middleware/interceptors. |
| External integrations | Outbound API clients. |
| OpenAPI generation | Note IF the framework auto-exposes a spec (`/openapi.json`, `/docs`) — but still derive the list from source, not from that file. |
| API source files | Route/controller files. |

**Endpoint table — one row per endpoint.** Each resource group is a **collapsible
`<details class="api-group">`** (collapsed by default; the user clicks to expand),
with the resource name and the endpoint count in the `<summary>`:

```html
<details class="api-group"><summary>Auth <span class="count">11</span></summary>
<table>
  <tr><th>Method</th><th>Path</th><th>Auth</th><th>Request</th><th>Response</th></tr>
  <tr><td>POST</td><td><code>/v1/auth/signup</code></td><td>Public</td><td>SignupRequest { email, password, name?, postcode }</td><td>{ ok, message }</td></tr>
  <!-- one <tr> per endpoint -->
</table></details>
```

Column meanings:

| Column | Content |
|---|---|
| Method | GET/POST/PUT/PATCH/DELETE/WS |
| Path | full reconstructed path, e.g. `/v1/swaps/proposals/received` |
| Auth | required auth (e.g. Bearer JWT) or `public` |
| Request | key request-body/query fields, or `—` for none. Summarize from the model (e.g. `{ title, category_id, images[] }`). |
| Response | response shape/model name (e.g. `ListingResponse` or `{ id, status }`). |

The `<span class="count">` must equal the number of endpoint `<tr>` rows (exclude
the header row). Keep the field cards (API type, auth, etc.) and an auth legend
ABOVE the collapsible groups, not inside them.

Aim for completeness — list every endpoint you find. If a path segment or model
can't be resolved from source, show your best reconstruction and badge it
`inferred`; never silently omit an endpoint. End the tab with a "Source evidence"
line citing the router files you read.

---

## Tab 5 — Local Development

| Field | How to detect |
|---|---|
| Prerequisites | Runtime versions in manifests/`.tool-versions`/`engines`. |
| Installation steps | From README + package manager. |
| Dependency managers | Lockfiles. |
| Environment variables | `.env.example` (names only). |
| Local services required | DB/cache from compose. |
| Start commands | `scripts` in manifest, `Makefile`, README. |
| Build commands | Build scripts. |
| Test commands | Test runner invocation. |
| Lint/format commands | eslint/prettier/ruff/black config + scripts. |
| Useful scripts | `package.json` scripts, `Makefile` targets, `scripts/`. |
| Local development files | Enumerate the files cited. |
