# Subagent prompts

Fill in the `<…>` parts. Each subagent knows only what is in its prompt, so
give it the paths and the commands, not a summary of the code.

## Reviewer (one per area, plus one cross-cutting)

```
You are reviewing part of pull request #<N> in <repo> (checked out at <path>, head <sha>).

Your area: <area name>
Files in your area: <list>
Get the diff with: git -C <path> diff <base>...<head> -- <files>
(round 2+: git -C <path> diff <last_reviewed_sha>..<head> -- <files>)
What the PR does: <one or two sentences from the PR description>
Look hard at: <risk hints>
Project rules to respect: <CLAUDE.md / CONTRIBUTING paths, or "none written">

Already known (do not report these again, in any wording):
<id · file · claim, one per line, or "none">

Report problems this PR introduces, or old problems it newly exposes. Read as
far beyond the diff as you need: callers of changed functions, what the changed
code calls, shared contracts (schemas, headers, DB columns, API shapes), and
code that should have changed with this PR but didn't. Do not report old bugs
the PR doesn't touch; list them separately under "outside" in one line each.

Severity:
- major: a concrete failure on a reachable path (wrong result, data loss,
  security hole, crash, broken contract). Requires a failure scenario:
  these inputs or this state -> this outcome. No scenario, not a major.
- minor: real but low impact or needs an unlikely state; missing tests on a risky path.
Do not report style, naming or taste.

Return a list, one entry per problem:
- sev: major | minor
- file:line (a line in the PR's head)
- claim: one sentence
- failure: the scenario (required for major)
- evidence: the lines and the call path that show it
- fix: a short suggestion, if obvious
Then "outside:" lines, if any. Return an empty list if you find nothing; do
not pad it.
```

The **cross-cutting** reviewer gets every changed file, and "Look hard at:
contracts between <areas>: what one side sends or stores and the other reads;
anything that should have changed alongside this PR but didn't".

## Verifier (one per candidate major)

Give it the claim and the location only, not the reviewer's reasoning, so it
judges the code and not the argument.

```
A reviewer claims there is a bug in pull request #<N> in <repo>
(checked out at <path>, head <sha>; diff: git -C <path> diff <base>...<head>).

Claim: <claim>
Where: <file:line>
Failure scenario given: <failure>

Your job is to try to disprove it. Read the code at that location and whatever
it depends on: callers, guards, validation, config, tests. Check whether the
scenario can actually happen: is the path reachable, does something upstream
already prevent it, does the code really behave as claimed? Also check that the
problem comes from this PR (the line is in the diff, or the PR made it reachable).

Answer with one verdict:
- confirmed: the failure happens; give the exact path that leads to it.
- downgrade: real, but needs an unlikely state or the impact is small; say why.
- rejected: it cannot happen, or it predates the PR and the PR doesn't expose it; say why.
```
