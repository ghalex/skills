# create-a-prd

Claude Code skill for turning a feature idea into a self-contained, durable Product Requirements Document (PRD) — through a user interview, codebase exploration, and module sketching.

## Install

```bash
npx skills add ghalex/skills --skill create-a-prd
```

## Usage

```bash
claude "write a PRD for adding a new payment method"
claude "let's formalize this feature idea into a PRD"
claude "I need product requirements for the export feature"
```

## What it does

1. **Gets a long description** — asks you to ramble about the problem and any solutions you've considered; structures it later
2. **Verifies in the codebase** — explores the repo to confirm your assertions and understand the current state instead of taking claims at face value
3. **Grills you** — interviews relentlessly about every aspect of the plan, one decision at a time, always leading with a recommended answer. Walks down each branch of the design tree, resolving dependencies before siblings
4. **Sketches modules** — identifies the major modules to build or modify, favoring **deep modules** (small interface, lots of implementation) and flagging shallow ones
5. **Confirms the outline** — presents the title, problem, user stories, and module sketch, and **waits for your approval** before filing anything
6. **Writes the PRD** — files a Markdown document at `prds/prd-<feature-name>.md` (checking first so it never clobbers an existing PRD)

## The PRD

Every PRD is written to be:

- **Self-contained** — understandable without reading the codebase
- **Durable** — no file paths, line numbers, or code snippets that go stale when the code moves

### Sections

| Section | Contents |
|---|---|
| Problem Statement | The problem from the user's perspective |
| Solution | What changes for the user when this ships |
| Success Metrics | Observable, measurable signals that the problem is solved |
| User Stories | A long, numbered list (`As an <actor>, I want <feature>, so that <benefit>`), each non-trivial one with acceptance criteria, covering edge cases, errors, and admin paths |
| Implementation Decisions | Modules, interfaces, schema/data-model changes, API contracts, architectural decisions |
| Testing Decisions | What makes a good test, which modules to test, prior art in the codebase |
| Out of Scope | What is explicitly **not** being built |
| Open Questions | Decisions raised but deferred that implementation depends on |
| Further Notes | Anything else worth recording |

## Output

```
prds/prd-add-a-new-payment-method.md
```

The feature name comes from the PRD title, lowercased and hyphenated.

## Related skills

- [`grill-me`](../grill-me) — for a tighter interview loop when grilling gets long
- `prd-to-issues` — suggested as the next step after filing the PRD
