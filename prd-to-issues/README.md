# prd-to-issues

Claude Code skill for breaking a PRD or plan into independently-grabbable, vertically-sliced Markdown issues — work orders an agent can pick up and implement one-by-one in a **ralph loop**.

## Install

```bash
npx skills add ghalex/skills --skill prd-to-issues
```

## Usage

```bash
claude "turn this PRD into issues"
claude "slice prds/prd-export.md into issues for a loop"
claude "break this plan into tickets I can hand to an agent"
```

## What it does

1. **Locates the PRD/plan** — reads a local Markdown file (the `create-a-prd` default is `prds/`) or uses what's already in context
2. **Explores the codebase** — identifies every integration layer a slice must cut through, plus concrete module names and patterns to cite
3. **Drafts vertical slices** — tracer bullets, each a thin slice through *all* layers end-to-end, sized to **one iteration / one PR**, typed `afk` or `human`, numbered topologically
4. **Quizzes you** — presents the breakdown (title, type, blocked-by, stories) and iterates on granularity and dependencies until you approve
5. **Files the issues** — one `issues/NNN-slug.md` per slice in dependency order, with acceptance criteria mapped from the PRD's user stories, plus an `issues/README.md` index

## Issues are work orders, not archival docs

Unlike a PRD (durable, abstract), an issue is **concrete and disposable** — consumed once by the loop, then retired to `issues/done/`. So each issue names the modules, files, and patterns to touch, and references the PRD for the *why*. A fresh-context agent should be able to execute it without re-reading the conversation.

## The ralph-loop contract

Completion is tracked by **file location, not a status field** — zero parsing, atomic with the commit:

- **Todo** = `issues/*.md` · **Done** = `issues/done/*.md`
- Each iteration takes the **lowest-numbered `afk` issue** whose `blocked_by` are all in `issues/done/`, implements it, and `git mv`s it to `issues/done/` in the same commit
- The loop **skips** `human` and blocked issues and **stops** when no eligible `afk` issue remains, surfacing the leftovers for review
- "What's left" is just `ls issues/*.md` — no state to desync

## Output

```
issues/
├── README.md          # index + loop contract (derived view)
├── 001-<slug>.md
├── 002-<slug>.md
└── done/              # issues land here as the loop completes them
```

## Related skills

- [`create-a-prd`](../create-a-prd) — produces the PRD this skill consumes
- [`grill-me`](../grill-me) — for a tighter loop when the breakdown quiz drags on
