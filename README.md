# Claude Code Skills

A curated collection of Claude Code skills for software engineers — covering backend scaffolding, frontend development, code review, architecture enforcement, and more.

## Installation

Install all skills:
```bash
npx skills add ghalex/skills
```

Install a specific skill:
```bash
npx skills add ghalex/skills --skill fastapi-setup
```

Install globally (available in all projects):
```bash
npx skills add ghalex/skills -g
```

---

## Skills

| Skill | Description |
|---|---|
| [`fastapi-setup`](#fastapi-setup) | Scaffold a production-ready FastAPI project |
| [`fastapi-monorepo-setup`](#fastapi-monorepo-setup) | Scaffold a production-ready FastAPI monorepo with uv workspaces |
| [`fastapi-architect`](#fastapi-architect) | Audit any FastAPI project against architecture rules |
| [`fastapi-rules`](#fastapi-rules) | Definitive FastAPI architecture rules for auditing and development |
| [`react-setup`](#react-setup) | Scaffold a production-ready React 19 + Vite SPA |
| [`react-architect`](#react-architect) | Audit any React SPA project against architecture rules |
| [`react-rules`](#react-rules) | Definitive React architecture rules for auditing and development |
| [`commit`](#commit) | Create well-structured git commits with conventional format |
| [`grill-me`](#grill-me) | Stress-test a plan or design by being interviewed relentlessly |
| [`handoff`](#handoff) | Compact the current conversation into a handoff document |
| [`create-a-prd`](#create-a-prd) | Turn a feature idea into a self-contained, durable PRD |

---

## `fastapi-setup`

Scaffolds a complete FastAPI project with clean layered architecture, auth, Docker, and architecture rules baked in via `CLAUDE.md`.

**Includes:** SQLAlchemy 2.x · JWT auth · Pydantic v2 · services layer · agents dir · justfile · Dockerfile · CLAUDE.md

**Install:**
```bash
npx skills add ghalex/skills --skill fastapi-setup
```

**Usage:**
```bash
claude "create a new FastAPI project in dir myapi"
claude "scaffold a fastapi app called myapi"
```

---

## `fastapi-architect`

Audits any FastAPI project against a clean layered architecture — routes, services, models, agents, db access patterns. The rules themselves live in [`fastapi-rules`](#fastapi-rules); this skill loads them and adds the review process and report format.

**Install:**
```bash
npx skills add ghalex/skills --skill fastapi-architect
```

**Usage:**
```bash
claude "review my routes"
claude "audit this project"
claude "does this follow the fastapi rules"
```

---

## `fastapi-rules`

The definitive source for FastAPI architecture rules — used by both the architect (auditing) and during development (adding routes, services, models, features). Covers layout detection (standalone vs uv monorepo), the path map, and route/service/model/utils/agent conventions.

**Install:**
```bash
npx skills add ghalex/skills --skill fastapi-rules
```

**Usage:**
```bash
claude "add a new route"
claude "add a new service"
claude "implement this endpoint"
claude "review my code structure"
```

---

## `react-setup`

Scaffolds a complete React SPA with auth, routing, and state management ready to go.

**Includes:** React 19 · Vite 7 · TypeScript · Tailwind CSS v4 · shadcn/ui (new-york) · Redux Toolkit + RTK Query · React Router v7 · PrivateRoute/PublicRoute · JWT auth with localStorage · Dockerfile + nginx · CLAUDE.md

**Install:**
```bash
npx skills add ghalex/skills --skill react-setup
```

**Usage:**
```bash
claude "create a new React project called myapp"
claude "scaffold a react spa called dashboard"
claude "new react frontend"
```

---

## `fastapi-monorepo-setup`

Scaffolds a complete FastAPI monorepo using `uv` workspaces with 5 shared packages, JWT auth, SQLAlchemy, and Docker support.

**Includes:** uv workspaces · shared packages (config, db, models, utils, services) · JWT auth · SQLAlchemy 2.x · Pydantic v2 · Docker + docker-compose · CLAUDE.md

**Install:**
```bash
npx skills add ghalex/skills --skill fastapi-monorepo-setup
```

**Usage:**
```bash
claude "create a new fastapi monorepo called myapp"
claude "scaffold a fastapi monorepo project"
claude "add a new app to a fastapi monorepo"
```

---

## `react-architect`

Audits any React SPA project against a clean component architecture — pages, store, components, lib, and routing patterns. The rules themselves live in [`react-rules`](#react-rules); this skill loads them and adds the review process and report format.

**Install:**
```bash
npx skills add ghalex/skills --skill react-architect
```

**Usage:**
```bash
claude "review my components"
claude "audit this react project"
claude "does this follow react rules"
```

---

## `react-rules`

The definitive source for React architecture rules — used by both the architect (auditing) and during development (adding pages, components, store domains, features). Covers the expected stack, component structure, store organization, and design conventions.

**Install:**
```bash
npx skills add ghalex/skills --skill react-rules
```

**Usage:**
```bash
claude "add a new page"
claude "add a new store domain"
claude "implement this feature"
claude "review my frontend structure"
```

---

## `commit`

Groups changed files into logical commits, asks for confirmation, then creates them sequentially using conventional commit format.

**Install:**
```bash
npx skills add ghalex/skills --skill commit
```

**Usage:**
```
/commit
```

---

## `grill-me`

Interviews you relentlessly about a plan or design — one question at a time, walking down each branch of the design tree and resolving dependencies between decisions before you build. Each question comes with a recommended answer.

**Install:**
```bash
npx skills add ghalex/skills --skill grill-me
```

**Usage:**
```bash
claude "grill me on this plan"
claude "stress-test this design before I build it"
```

---

## `handoff`

Compacts the current conversation into a handoff document so a fresh agent can pick up the work. Saves to the OS temp directory, references existing artifacts instead of duplicating them, suggests skills for the next session, and redacts sensitive information.

**Install:**
```bash
npx skills add ghalex/skills --skill handoff
```

**Usage:**
```
/handoff
```

---

## `create-a-prd`

Turns a feature idea into a self-contained, durable Product Requirements Document. Interviews you about the problem and solution, verifies your assertions against the codebase, sketches the deep modules to build, then files the PRD as local Markdown at `prds/prd-<feature-name>.md`. The PRD avoids file paths and code snippets so it doesn't go stale as the code moves.

**Install:**
```bash
npx skills add ghalex/skills --skill create-a-prd
```

**Usage:**
```bash
claude "write a PRD for adding a new payment method"
claude "formalize this feature idea into a PRD"
claude "I need product requirements for the export feature"
```

---

## Skill Format

Each skill is a directory with a `SKILL.md` file following the Claude Code skill format:

```
skills/
└── my-skill/
    ├── SKILL.md     # skill instructions (required)
    └── README.md    # documentation (optional)
```

## Contributing

PRs welcome. Each skill should:
- Have a clear, focused trigger phrase
- Include a `README.md` with usage examples
- Be self-contained in its own directory
