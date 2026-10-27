#!/usr/bin/env bash
# pr-review / state.sh — keeps the review's memory on the PR itself.
#
# The memory is one summary comment on the PR, owned by whoever runs the
# review (the gh user), with the state as JSON inside a hidden HTML comment:
#   <!-- pr-review-state
#   {"version":1,"round":1,"last_reviewed_sha":"...","findings":[...]}
#   -->
# Each finding is also an inline review comment ending in <!-- pr-review:F3 -->,
# so its thread (resolved, replies) can be matched back to the finding.
#
# Usage (run inside a clone of the PR's repo; needs gh and jq):
#   state.sh read    <pr>                       print the state JSON (round 0 if none yet)
#   state.sh threads <pr>                       print [{id, thread_id, comment_id, resolved, outdated, replies:[{author, body}]}]
#   state.sh review  <pr> <review.json>         post inline findings: {"body": "...", "comments": [{path, line, body}]}
#   state.sh reply   <pr> <comment_id> <body.md>  reply in a finding's thread (comment_id from `threads`)
#   state.sh resolve <pr> <thread_id>           resolve a finding's thread (thread_id from `threads`)
#   state.sh write   <pr> <summary.md> <state.json>   create or update the summary comment
set -euo pipefail

MARK='<!-- pr-review-state'

die() { echo "state.sh: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "$1 is required"; }
need gh; need jq

[ $# -ge 2 ] || { sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
CMD=$1; PR=${2##*/}   # accepts a number or a PR URL
[[ $PR =~ ^[0-9]+$ ]] || die "not a PR number: $2"

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
ME=$(gh api user -q .login)

# The id of the state comment. Only our own comments count, so nobody else
# can plant a state that marks findings as fixed.
state_comment_id() {
  gh api --paginate "repos/$REPO/issues/$PR/comments" \
    --jq ".[] | select(.user.login == \"$ME\" and (.body | contains(\"$MARK\"))) | .id" | head -n1
}

case "$CMD" in
  read)
    id=$(state_comment_id)
    if [ -z "$id" ]; then
      echo '{"version":1,"round":0,"last_reviewed_sha":null,"findings":[]}'
      exit 0
    fi
    gh api "repos/$REPO/issues/comments/$id" --jq .body |
      sed -n "/^$MARK\$/,/^-->\$/p" | sed '1d;$d' | jq .
    ;;

  threads)
    gh api graphql -F owner="${REPO%/*}" -F name="${REPO#*/}" -F pr="$PR" -f query='
      query($owner: String!, $name: String!, $pr: Int!) {
        repository(owner: $owner, name: $name) {
          pullRequest(number: $pr) {
            reviewThreads(first: 100) {
              nodes {
                id isResolved isOutdated
                comments(first: 30) { nodes { databaseId author { login } body } }
              }
            }
          }
        }
      }' --jq '
      [.data.repository.pullRequest.reviewThreads.nodes[]
       | (.comments.nodes[0].body | capture("<!-- pr-review:(?<id>F[0-9]+) -->")?) as $m
       | select($m != null)
       | {id: $m.id, thread_id: .id, comment_id: .comments.nodes[0].databaseId,
          resolved: .isResolved, outdated: .isOutdated,
          replies: [.comments.nodes[1:][] | {author: (.author.login // "ghost"), body}]}]'
    ;;

  review)
    [ $# -eq 3 ] || die "usage: state.sh review <pr> <review.json>"
    jq -e '.body and (.comments | type == "array")' "$3" >/dev/null || die "$3: need {body, comments: []}"
    sha=$(gh pr view "$PR" --json headRefOid -q .headRefOid)
    # Always COMMENT: approving or requesting changes stays with a human.
    if ! jq --arg sha "$sha" '{commit_id: $sha, event: "COMMENT", body,
           comments: [.comments[] | {path, line, side: "RIGHT", body}]}' "$3" |
         gh api "repos/$REPO/pulls/$PR/reviews" --input - >/dev/null 2>&1; then
      # GitHub rejects the whole review when one line is outside the diff.
      # Fall back to a single review whose body lists every finding.
      echo "state.sh: inline review rejected, posting findings in the review body" >&2
      jq --arg sha "$sha" '{commit_id: $sha, event: "COMMENT",
           body: (.body + "\n\n" + ([.comments[] | "**`\(.path):\(.line)`**\n\n\(.body)"] | join("\n\n---\n\n")))}' "$3" |
        gh api "repos/$REPO/pulls/$PR/reviews" --input - >/dev/null
    fi
    ;;

  reply)
    [ $# -eq 4 ] || die "usage: state.sh reply <pr> <comment_id> <body.md>"
    [[ $3 =~ ^[0-9]+$ ]] || die "not a comment id: $3 (use comment_id from \`threads\`)"
    jq -n --rawfile b "$4" '{body: $b}' |
      gh api "repos/$REPO/pulls/$PR/comments/$3/replies" --input - --jq .html_url
    ;;

  resolve)
    [ $# -eq 3 ] || die "usage: state.sh resolve <pr> <thread_id>"
    gh api graphql -f id="$3" -f query='
      mutation($id: ID!) { resolveReviewThread(input: {threadId: $id}) { thread { isResolved } } }' \
      --jq '.data.resolveReviewThread.thread.isResolved' | grep -qx true || die "could not resolve thread $3"
    ;;

  write)
    [ $# -eq 4 ] || die "usage: state.sh write <pr> <summary.md> <state.json>"
    jq -e '.version and (.round | type == "number") and .last_reviewed_sha and (.findings | type == "array")' \
      "$4" >/dev/null || die "$4: not a valid state"
    body=$(mktemp); trap 'rm -f "$body"' EXIT
    { cat "$3"; printf '\n\n%s\n' "$MARK"; jq . "$4"; printf -- '-->\n'; } > "$body"
    id=$(state_comment_id)
    if [ -n "$id" ]; then
      jq -n --rawfile b "$body" '{body: $b}' |
        gh api -X PATCH "repos/$REPO/issues/comments/$id" --input - --jq .html_url
    else
      jq -n --rawfile b "$body" '{body: $b}' |
        gh api "repos/$REPO/issues/$PR/comments" --input - --jq .html_url
    fi
    ;;

  *) die "unknown command: $CMD (read | threads | review | reply | resolve | write)" ;;
esac
