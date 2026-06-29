# codebase-handoff

Generate a self-contained, interactive **architecture & handoff HTML document** for
any repository — built from repo-detectable facts, every claim grounded in a real
source file. Designed for client handoffs and onboarding new developers.

![tabs: Overview · Architecture · Deployment · Database · API · Local Dev](#)

## What it produces

A single `docs/architecture/handoff.html` with six tabs:

| Tab | Contents |
|---|---|
| **Overview** | Languages, frameworks, package managers, apps/services (monorepo-aware), build/test tools, DB/ORM, API style, deploy tooling, external services, existing/missing docs, a documentation-completeness score. |
| **Architecture** | Components, responsibilities, relationships, data/request flow, internal + external deps, and a Mermaid flowchart with **brand logos + pale layer colors + animated edges**. |
| **Deployment** | Docker/K8s/Terraform, CI/CD, build process, runtime services, env-var **names** (never values), ports, config files. |
| **Database** | Technology, ORM, **domain-split ER diagrams** (every table, PK/FK + key columns + crow's-foot cardinality), migrations, connection config. |
| **API** | Type, auth model, and **every endpoint enumerated from route source** (not from a possibly-stale OpenAPI/README) with method, path, auth, request/response payloads. |
| **Local Dev** | Prerequisites, install/start/build/test/lint commands, required local services, useful scripts. |

### Core principles

- **Evidence-first.** Every section cites the source files it was built from.
- **No invention.** Facts not found in source are badged `inferred` or `not detected`.
- **Secrets-safe.** Environment variables are listed by name only.
- **Diagrams as text.** Claude writes Mermaid; the browser renders it — no image files.

## Install

This is a Claude Code skill. Make it available by putting the `codebase-handoff/`
directory under a skills folder Claude Code reads:

**User-level (available in every project):**
```bash
# symlink so `git pull` in this repo keeps it up to date
ln -s "$(pwd)/codebase-handoff" ~/.claude/skills/codebase-handoff
# …or copy it
cp -R codebase-handoff ~/.claude/skills/codebase-handoff
```

**Project-level (one repo only):**
```bash
cp -R codebase-handoff /path/to/your/project/.claude/skills/codebase-handoff
```

## Use

Open the target project in Claude Code and ask, e.g.:

> "Generate the architecture/handoff doc for this repo"
> "Use the codebase-handoff skill"

The skill runs a phased, detect → cite → fill process and writes
`docs/architecture/handoff.html`. It never overwrites an existing `index.html`.

## Requirements & notes

- **Internet to view.** The output loads Mermaid (jsDelivr CDN) and brand logos
  (`api.iconify.design`). The HTML is otherwise self-contained.
- **Run on a capable model.** Endpoint/ER/architecture detection is a real analysis
  pass; Opus-class models give the most accurate results. On a large monorepo a full
  run can take ~15–20 minutes.
- **Monorepo-aware.** Each app/service is detected and labeled.

## Files

```
codebase-handoff/
├── SKILL.md                  # orchestrator: when-to-use, phased process, core rules
└── references/
    ├── template.html         # the pale, minimalist 6-tab HTML shell (fill slots)
    ├── tab-guides.md         # per-tab fields + how to detect each + evidence rules
    └── mermaid-guide.md      # architecture (logos+color) & domain-split ER authoring
```

## Implementation notes (Mermaid gotchas baked in)

- Architecture nodes use **`<img>`-in-label** nodes, *not* Mermaid icon-shape nodes
  (`@{ icon: ... }`) — icon-shape nodes clip any label longer than the icon.
- `themeVariables.fontFamily` is set **explicitly** (not `inherit`); `inherit` makes
  Mermaid mis-measure label widths and clip node text.
- ER diagrams are **domain-split** (one diagram per domain) for readability at scale.
