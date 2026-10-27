# pr-review

Claude Code skill to review a GitHub pull request in rounds that converge,
instead of finding new "majors" every time it runs.

## Install

```bash
npx skills add ghalex/skills --skill pr-review
```

Needs `gh` (logged in) and `jq`.

## Usage

```
/pr-review 42             first run: deep review; later runs: only the new commits
/pr-review 42 --dry-run   print the findings, post nothing; say "post" afterwards to post them as shown
/pr-review 42 --full      review everything again, keeping settled findings settled
/pr-review 42 --fix       review, post, then fix each open finding (one commit each), push, and re-review
/pr-review 42 --fix F1,F3 same, for those findings only
```

It runs start to finish without asking anything. The finished product is one
inline comment per finding, on the file and line it is about, plus the round
summary comment on the PR.

## How it works

1. **Round 1 reviews deeply, once.** The diff is split into areas, one reviewer
   per area plus one for the contracts between areas, all in parallel.
2. **Every major is verified.** A separate verifier tries to disprove it. A
   major needs a concrete failure scenario, or it isn't one.
3. **The memory lives on the PR.** One summary comment holds the findings and
   their status as hidden JSON, and it's edited in place every round. Each
   finding is also an inline comment.
4. **Round 2+ reviews only what changed.** It checks the old findings (fixed?
   `wontfix`? `disagree`?), then reviews only the commits since the last review.
   Settled findings are never raised again.
5. **It has a stop rule.** "Ready" means no open major and no new major this
   round. After 3 rounds it hands over to a human. It never approves on GitHub.
6. **`--fix` closes the loop.** After posting, it fixes each open finding on
   the PR branch, one commit per finding on a green test suite, pushes, and
   runs the next round to confirm. Confirmed fixes get a `fixed in <sha>`
   reply and their thread resolved. It never force-pushes or commits on a
   dirty tree.

Authors resolve a thread when it's fixed, or reply `wontfix: <reason>` /
`disagree: <reason>`.

## Script

`scripts/state.sh` is the memory. It can be used on its own:

```bash
scripts/state.sh read 42                        # the state JSON
scripts/state.sh threads 42                     # finding threads: resolved, replies
scripts/state.sh review 42 review.json          # post inline findings
scripts/state.sh reply 42 <comment_id> body.md  # reply in a finding's thread
scripts/state.sh resolve 42 <thread_id>         # resolve a finding's thread
scripts/state.sh write 42 summary.md state.json # create or update the summary comment
```
