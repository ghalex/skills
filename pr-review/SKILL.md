---
name: pr-review
description: Review a GitHub pull request in rounds that converge — one deep, verified review first, then later rounds check only the fixes and the new commits, with the review's memory (findings and their status) kept in one comment on the PR. Use when the user says "review PR 42", "review this pull request", "re-review the PR", "check if my review comments were addressed", "/pr-review", or passes a PR number or URL to review.
---

# PR Review

A review that starts from scratch every round never ends: each run samples
different code, sees the last round's fixes as new code, and always finds
something. This skill reviews the way an experienced human does: **look
carefully once, then check only that comments were addressed and the fixes
didn't break anything.**

```
round 1   full diff → reviewers in parallel → verify each major → post
round 2+  read memory → status of old findings → review only new commits → verify → post
stop      no open major and the last round found no new major → ready for a human to merge
```

The memory lives on the PR: one summary comment with the state as hidden JSON,
read and written by `scripts/state.sh` (next to this file; needs `gh` and `jq`).
Each finding is also an inline comment, so the author answers it where it is.

## Arguments

`/pr-review <number|url> [--full] [--dry-run] [--yes]`

- `--full`: review the whole diff again, but keep the memory (settled findings stay settled).
- `--dry-run`: show the findings, post nothing, write no state.
- `--yes`: post without asking (CI). Without it, always show the findings and ask before posting.

No number: use the PR of the current branch (`gh pr view --json number`). No PR
at all: say the memory needs a PR, and offer a one-off review of `git diff main...HEAD`
that follows the round-1 bar and posts nothing.

## What counts

**Scope.** Report only problems this PR introduces, or old problems it newly
exposes (a weak check that now sits behind a public route). Read as far beyond
the diff as needed to judge it: callers of changed code, what it calls, shared
contracts (schemas, headers, DB columns, config, API shapes), and things that
should have changed but didn't. An old bug you notice that the PR doesn't touch
goes in the summary's "Noticed outside this PR" list (one line each), never as
a finding.

**Severity.**

- **major**: a concrete failure on a reachable path — wrong result, data loss,
  security hole, crash, broken contract, failed migration. It must come with a
  *failure scenario*: these inputs or this state → this outcome. If you cannot
  write one, it is not a major.
- **minor**: real but low impact, or a failure that needs an unlikely state.
  Missing tests for a risky path are a minor, unless the project's rules require them.
- **Not findings**: style, naming, taste, "consider". Only a breach of the
  project's written rules (CLAUDE.md, CONTRIBUTING, lint config) counts, as a minor.

Read the project's written rules before reviewing; they decide what a breach is.

## Procedure

### 0. Set up

```bash
S=<this skill dir>/scripts/state.sh
gh pr view N --json number,title,body,headRefOid,baseRefName,headRefName,additions,deletions,changedFiles,files
$S read N        # state; round 0 = first review
$S threads N     # our finding threads: resolved?, replies
```

The code under review must be the PR head. If the current checkout isn't at
`headRefOid`, don't switch the user's branch: `git fetch origin pull/N/head` and
add a worktree in the scratchpad (`git worktree add <scratch>/pr-N FETCH_HEAD`),
and remove it when done.

Round 0 → go to **Round 1**. Otherwise → **Round 2+**. `--full` → Round 1 with
the existing findings passed in as *known*.

### Round 1: one deep review

1. **Size up.** Over ~1500 changed lines, or several unrelated changes in one PR:
   say so in the summary and suggest how to split it. Then still review it.
2. **Split into areas**: 2–5 groups of changed files that belong together
   (a package, a subsystem, "DB + migrations"). For each area write 2–5 risk
   hints from what the change does (auth, untrusted input, concurrency, money,
   migrations, anything newly reachable from outside).
3. **Review in parallel.** One reviewer per area, plus one **cross-cutting**
   reviewer for contracts between areas and "should have changed but didn't".
   With the Agent tool, spawn them all in one message using the reviewer prompt
   in `references/prompts.md`. Without it, do the passes yourself, one area at a
   time, giving each the same attention.
4. **Merge** the candidates: one finding per distinct problem, keep the best
   failure scenario. Drop any already in the known list.
5. **Verify** every candidate major with a separate verifier that did not
   produce it (verifier prompt in `references/prompts.md`; spawn in parallel).
   It gets the claim and the location, not the reviewer's reasoning. `confirmed`
   stays major, `downgrade` becomes minor, `rejected` is dropped. Minors are not
   verified, but read each one yourself and drop what you can't stand behind.
6. **Number** findings `F1, F2, …` continuing from the highest id in the state.
7. **Show and post** (below).

### Round 2+: only what changed

1. **Old findings first.** For each finding that is `open` in the state:
   - its thread got a reply starting `wontfix` or `disagree` → read the reason.
     If it holds, or it is a judgement call, set `wontfix` / `disputed` and keep
     the reason in `note`. If you still think it's a real major, say why once in
     the summary as `disputed`, for a human to decide. Never raise it again.
   - otherwise check the current code: fixed → `fixed` (a resolved thread alone
     is not proof; look); not fixed → stays `open`.
2. **Scope** = the commits since the last review:
   ```bash
   git merge-base --is-ancestor <last_reviewed_sha> <head> && git diff <last_reviewed_sha>..<head>
   ```
   If the last sha is not an ancestor (rebase, force-push), use
   `git range-diff` against the old range if it still exists locally;
   otherwise review the full diff, with every existing finding passed as known.
3. **Review the delta** with the round-1 bar: one reviewer for a small delta,
   per-area reviewers for a large one, each told the known findings so nothing
   is re-reported. Look at what the fixes changed *and* what they call.
   Verify new majors the same way.
4. **Show and post.**

### Show and post

Show the user a table: id, severity, `file:line`, one-line claim, and for round
2+ the status changes. Then, unless `--dry-run`:

- **Ask before posting** (posting to a PR is public), unless `--yes`.
- **New findings** → one review with inline comments. Write `review.json` in
  the scratchpad and run `$S review N review.json`. Each comment body:
  ```
  **major** · F3 — <one-line claim>

  **Failure:** <inputs/state → outcome>
  **Fix:** <short suggestion, if obvious>

  <!-- pr-review:F3 -->
  ```
  Inline comments must sit on lines in the PR's diff. A finding on an unchanged
  line goes on the nearest changed line it relates to, or only in the summary.
- **Summary + state** → write `summary.md` and `state.json`, then
  `$S write N summary.md state.json`. It edits the same comment every round.

Summary layout:

```markdown
## PR review — round 2 · <short sha>
**Verdict:** not ready — 1 open major  |  ready for a human to merge

| id | sev | where | status | claim |
|----|-----|-------|--------|-------|
| F1 | major | `api/auth.ts:42` | ✅ fixed | ... |
| F4 | major | `db/sync.ts:18` | ⏳ open (new) | ... |
| F2 | minor | `ui/list.tsx:9` | 🚫 wontfix | ... |

**Noticed outside this PR:** <one line each, or omit>

<sub>Resolve a thread when it's fixed. Reply `wontfix: <reason>` or
`disagree: <reason>` to close it without a change. Next round reviews only new commits.</sub>
```

State (`state.json`, full list every time, never drop a finding):

```json
{
  "version": 1,
  "round": 2,
  "last_reviewed_sha": "<head sha just reviewed>",
  "findings": [
    {"id": "F1", "sev": "major", "file": "api/auth.ts", "line": 42,
     "claim": "token accepted after logout", "failure": "logout, then reuse the old token → 200",
     "status": "fixed", "round": 1, "note": ""}
  ]
}
```

`status` is one of `open`, `fixed`, `wontfix`, `disputed`. Match old findings
to code by `file` + `claim`, not by line; lines move.

## Stop rule

- **Ready**: no `open` major, and this round found no new major. Say "ready for
  a human to merge". Never approve or request changes on GitHub; reviews are
  always posted as comments.
- **Round cap: 3.** If a fourth round still finds new majors, stop reviewing
  rounds and say so: the PR is too big or the design is unsettled, and a human
  should look. Report what's open.

## Rules

- Every major has a failure scenario and a verifier's `confirmed`. No exceptions.
- Never re-report a finding that is in the state, whatever its status.
- After round 1, never review code outside the delta, except to read context.
- Don't post, edit or resolve anything on GitHub other than through `state.sh`,
  and only after the user agreed (or `--yes`).
- Only the summary comment written by the current `gh` user is read as state.
