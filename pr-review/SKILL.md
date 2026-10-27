---
name: pr-review
description: Review a GitHub pull request in rounds that converge — one deep, verified review first, then later rounds check only the fixes and the new commits, with the review's memory (findings and their status) kept in one comment on the PR. Use when the user says "review PR 42", "do a PR review on 42", "do a pr on X", "review this pull request", "re-review the PR", "check if my review comments were addressed", "review and fix PR 42", "/pr-review", or passes a PR number or URL to review. It posts without asking: the finished product is the inline comments and the round summary on the PR.
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
--fix     after posting: fix each open finding → tests → one commit each → push → next round
stop      no open major and the last round found no new major → ready for a human to merge
```

The memory lives on the PR: one summary comment with the state as hidden JSON,
read and written by `scripts/state.sh` (next to this file; needs `gh` and `jq`).
Each finding is also an inline comment, so the author answers it where it is.

## Arguments

`/pr-review <number|url> [--full] [--dry-run] [--fix [F1,F3]]`

- `--full`: review the whole diff again, but keep the memory (settled findings stay settled).
- `--dry-run`: print the findings in the terminal and post nothing. The
  prepared files stay in the scratchpad; when the user then says "post" (or
  "post all but F3"), post those files as they are, without reviewing again.
- `--fix`: after posting, fix the open findings on the PR branch, one commit
  each, push, and run the next round to confirm (see **--fix**). With ids,
  fix only those. Not with `--dry-run`.

Run it start to finish without asking anything. The finished product is the
inline comments and the round summary on the PR, then a short recap in the
terminal. The only question allowed is which PR, and only if it can't be found.

No number: use the PR of the current branch (`gh pr view --json number`). No PR
at all: review `git diff main...HEAD` once with the round-1 bar and print the
findings in the terminal; there is nowhere to post.

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
7. **Post** (below).

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
4. **Post.**

### Post

Post without asking. With `--dry-run`: write the same files, print the table
below plus each finding's full comment body, and stop. If the user then says
"post", run the same steps on those files; drop any finding they struck, and
renumber nothing.

- **New findings** → one review with inline comments, one comment per finding
  on the file and line it is about. Write `review.json` in the scratchpad and
  run `$S review N review.json`. Its `body` is one line:
  `PR review, round 1 (3e4dc62): 4 majors, 14 minors, inline below. Summary and state in the pr-review comment.`
  Each comment body:
  ```
  **major** · F3 — <one-line claim>

  **Failure:** <inputs/state → outcome; say so when you reproduced it, and how>
  **Fix:** <short suggestion, if obvious>

  <!-- pr-review:F3 -->
  ```
  Inline comments must sit on lines in the PR's diff. A finding on an unchanged
  line goes on the nearest changed line it relates to, or only in the summary.
- **Summary + state** → write `summary.md` and `state.json`, then
  `$S write N summary.md state.json`. It edits the same comment every round.
- **Recap** in the terminal: the summary table (id, severity, `file:line`,
  claim, status) and the links to the review and the summary comment. Nothing else.

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

Checked and consistent: <what you verified and found fine: contracts, versions, tests run; one paragraph, or omit>

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

### --fix: fix, commit, push, confirm

Only after the round is posted, so every finding has its id and its thread.

1. **Where.** The fixes go on the PR's head branch. The checkout (or the
   scratchpad worktree) must be at `headRefOid` with a clean tree; with
   uncommitted changes, stop and say so, never stash or reset. If the head
   branch is in a fork the current user cannot push to, fix and commit in the
   worktree anyway, don't push, and say where the commits are.
2. **Which.** Every finding with status `open`, majors first, then minors, in
   id order; or only the ids given. Never `wontfix`, `disputed` or `fixed`.
   Skip a finding whose fix needs a decision the author must make (a changed
   contract, a product choice) and say why in the recap.
3. **How.** One finding at a time, never in parallel: fixes share files.
   Read the finding's thread first; a reply may constrain the fix. Make the
   smallest change that removes the failure scenario, in the project's style
   and under its written rules. When the finding asked for a test, or the
   path had none, add one that fails before the fix and passes after.
4. **Tests.** Run the project's test command (from its rules, `package.json`,
   `justfile`, `Makefile`, CI config) after each fix. A failure you caused:
   fix it or drop the change. A suite that already failed before you touched
   anything: say so once, and judge each fix by the tests it touches.
5. **Commit.** One commit per finding, on a green suite, conventional format:
   `fix(<scope>): <claim in a few words> (F3)`, body: the failure scenario in
   one line and what changed. Two findings fixed by one change share a commit
   that names both ids. Never amend, never force-push.
6. **Push** to the head branch, then run **Round 2+** as usual: it marks the
   fixed findings `fixed`, reviews the delta, and posts. For each finding it
   confirmed fixed, reply `fixed in <short sha>` in its thread
   (`$S reply N <comment_id> body.md`) and resolve the thread
   (`$S resolve N <thread_id>`); ids come from `$S threads N`.
7. **Loop.** If the confirming round found new majors, fix those the same way.
   The round cap applies: the fix loop ends with the rounds, and whatever is
   still open is reported, not fixed.

The recap lists each commit with its finding, the findings skipped and why,
and the push result.

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
- Don't post, edit or resolve anything on GitHub other than through `state.sh`.
- Don't ask the user anything during a run; decide and go. `--dry-run` is how
  they look first.
- With `--fix`: never commit on a dirty tree, never commit with the tests red,
  never amend or force-push, and never touch a finding that isn't `open`.
- Only the summary comment written by the current `gh` user is read as state.
