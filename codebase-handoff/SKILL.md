---
name: codebase-handoff
description: Use when generating or updating a system architecture & handoff HTML document for a repository — produces an interactive tabbed page (Overview, Architecture, Deployment, Database, API, Local Dev) from repo-detectable facts, with Mermaid diagrams. Triggers — "handoff doc", "architecture doc", "document this repo", "generate codebase documentation".
---

# Codebase Handoff Document Generator

Generate a self-contained, interactive HTML handoff document for a repository,
built from **repo-detectable facts only**. Every claim is grounded in a real
source file. Diagrams are authored as **Mermaid text** and rendered in-browser —
never generate image files.

## When to use

When the user wants an architecture / handoff / onboarding document for a
codebase, or to regenerate one.

## Output

A single file at `docs/architecture/handoff.html` in the target repo (or a
user-specified path). Never overwrite an existing `index.html` — if the default
path's `index.html` exists, leave it alone and write `handoff.html`.

## Core rules (non-negotiable)

1. **Evidence first.** Every section ends with a "Source evidence" line listing
   the real files it was built from. If a fact is not found in source, label it
   `inferred` (reasoned from indirect signals) or `not detected` (absent).
   Never invent values, versions, endpoints, or entities.
2. **Names only for secrets.** Environment variables: list names, never values.
3. **Diagrams as Mermaid text.** You write Mermaid; the browser renders it. Never
   produce raster/image files. See `references/mermaid-guide.md`.
4. **Pale, minimalist design.** Copy `references/template.html` verbatim as the
   shell and fill the marked slots. Do not redesign.

## Process — phased, detect → cite → fill

Create one todo per phase. Work them in order. In every phase: detect facts from
source, note the files as evidence, then fill that tab's slot in the template.
Read `references/tab-guides.md` for the exact fields and how to detect each.

- **Phase 0 — Recon → Overview tab.** Scan the repo. Detect languages,
  frameworks, package managers, apps/services (detect monorepos and enumerate
  each app), build & test tools, DB/ORM, API style, deployment tooling, external
  services, existing docs, missing expected docs. Compute the documentation
  completeness score (see tab-guides). This pass also primes every later phase.
- **Phase 1 — Architecture tab.** Components, responsibilities, relationships,
  data flow, request flow, internal + external dependencies. Author the Mermaid
  architecture flowchart with brand logos + pale layer colors (see mermaid-guide).
- **Phase 2 — Deployment & Infrastructure tab.**
- **Phase 3 — Database tab.** Plus **domain-split** Mermaid ER diagrams (every
  table, each entity with PK/FK + key columns + crow's-foot cardinality).
- **Phase 4 — API tab.** Enumerate EVERY endpoint from route source — do NOT rely
  on a README/committed OpenAPI/Postman file for the list (they go stale). Include
  method, full path, auth, and a request/response payload summary per endpoint.
- **Phase 5 — Local Development tab.**
- **Phase 6 — Assemble & verify.** Fill the template, set the repo name / title /
  generated date, write the output file, open it in a browser. Self-review: does
  every section have a "Source evidence" line? Is every uncertain fact labeled
  `inferred`/`not detected`? **Do all Mermaid blocks actually render (no blank
  diagram, no parse error)?** If the architecture diagram is blank, apply the
  mermaid-guide fallback (drop unresolved icons → plain colored nodes).

## How to build the file

1. Read `references/template.html`. Copy it to the output path.
2. Replace the `{{...}}` slots (repo name, generated date, and each tab's body).
3. Keep the `<style>`, the tab-nav JS, and the Mermaid module script unchanged.
4. For each tab, follow `references/tab-guides.md` field-by-field.
5. For diagrams, follow `references/mermaid-guide.md`.

## Reference files

- `references/template.html` — the HTML shell to copy and fill.
- `references/tab-guides.md` — per-tab fields + detection method + evidence rules.
- `references/mermaid-guide.md` — which diagram per tab, syntax, pale theming.
