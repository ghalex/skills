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

---

## `fastapi-setup`

Scaffolds a complete FastAPI project with clean layered architecture, auth, Docker, and architecture rules baked in via `CLAUDE.md`.

**Includes:** SQLAlchemy 2.x · JWT auth · Pydantic v2 · services layer · agents dir · justfile · Dockerfile · CLAUDE.md

**Trigger phrases:**
- "create a new FastAPI project"
- "scaffold a fastapi app"
- "new fastapi project"
- "setup a fastapi api"

**Install:**
```bash
npx skills add ghalex/skills --skill fastapi-setup
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
