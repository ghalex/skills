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
| [`fastapi-architect`](#fastapi-architect) | Audit any FastAPI project against architecture rules |
| [`react-setup`](#react-setup) | Scaffold a production-ready React 19 + Vite SPA |
| [`commit`](#commit) | Create well-structured git commits with conventional format |

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

Audits any FastAPI project against a clean layered architecture — routes, services, models, agents, db access patterns.

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
