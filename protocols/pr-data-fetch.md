# pr-data-fetch

Fetch all review-relevant data for a single PR: metadata, review decisions, inline annotations, issue comments, CI status, commit history, and thread resolution. Produces raw structured data — no analysis, no scoring.

Read-only. Does not post, comment, or modify anything.

## Output Shape Contract

Every paginated step emits **one** JSON array — a single document parseable by a single `json.load` / `jq .` — never concatenated per-page arrays. This is why the paginated steps below pipe `--paginate --slurp` into a standalone `jq` that flattens across pages, not `--paginate --jq` alone. See the Edge Cases entry on concatenated-per-page output for the failure this prevents.

Two constraints make the pipe form mandatory, not stylistic:

- `--slurp` and `--jq` are mutually exclusive on `gh api` — `gh` errors with `the "--slurp" option is not supported with "--jq" or "--template"`. So the field projection cannot live in a `gh --jq` flag; it must run in a `jq` after the slurp.
- The pipe (`gh ... --slurp | jq '...'`) is a single pipeline, not a banned command chain. `rules/discrete-operations.md` prohibits `&&`, `||`, `;`, and command substitution because they bypass permission matching; a pipe does not — the matched command is still `gh api ...`, and it runs prompt-free. Do not "fix" these steps into two separate Bash calls; the slurp and the projection are one logical fetch.

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status` must succeed)
- Caller has read access to the repo

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `OWNER` | string | Repository owner (org or user) |
| `REPO` | string | Repository name |
| `NUMBER` | integer | PR number |

## Execution Steps

Step 1: Fetch PR metadata — size, state, approval state, head SHA, reviewer list.

```bash
gh pr view NUMBER --repo OWNER/REPO --json number,title,state,isDraft,url,headRefName,headRefOid,baseRefName,reviewRequests,reviewDecision,latestReviews,assignees,labels,milestone,createdAt,updatedAt,mergedAt,closedAt,additions,deletions,changedFiles
```

Step 2: Fetch CI check status.

```bash
gh pr checks NUMBER --repo OWNER/REPO --json name,state,startedAt,completedAt,link
```

Step 3: Fetch review-level comments — top-level approval decisions and general reviewer commentary.

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/reviews --paginate --slurp | jq '[.[][] | {id,user:.user.login,state,body,submitted_at}]'
```

Step 4: Fetch inline comments — code annotations tied to specific file lines.

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments --paginate --slurp | jq '[.[][] | {id,user:.user.login,path,line,original_line,body,created_at,updated_at,in_reply_to_id}]'
```

Step 5: Fetch issue-level comments — general PR thread discussion not tied to code lines.

```bash
gh api repos/OWNER/REPO/issues/NUMBER/comments --paginate --slurp | jq '[.[][] | {id,user:.user.login,body,created_at,updated_at}]'
```

Step 6: Fetch commit history — used for staleness assessment and re-review scoping.

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/commits --paginate --slurp | jq '[.[][] | {sha:.sha,message:.commit.message,date:.commit.committer.date,author:.commit.author.name}]'
```

Step 7: Fetch thread resolution status via GraphQL — maps each review thread to resolved/unresolved and links back to inline comment IDs from Step 4 via `first_comment_id`. This query is not paginated, so it already emits a single document; no `--slurp` needed.

```bash
gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100){nodes{id isResolved resolvedBy{login} comments(first:1){nodes{databaseId}}}}}}}' -f owner=OWNER -f repo=REPO -F number=NUMBER --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | {thread_id:.id,is_resolved:.isResolved,resolved_by:.resolvedBy.login,first_comment_id:.comments.nodes[0].databaseId}]'
```

Steps 1–7 are independent of each other — issue all seven in a single response as parallel tool calls.

## File Content Fetch (at a specific ref)

Use this when a review or digest finding cites `path:line` and needs to confirm the exact line content at the PR's `headRefOid`. Do not `Read` local files for line citations — the working tree may be on a different branch or have uncommitted changes, causing line numbers to drift from what the reviewer sees on GitHub.

```bash
gh api repos/OWNER/REPO/contents/PATH \
  -H "Accept: application/vnd.github.raw" \
  -f ref=SHA
```

`SHA` is the PR's `headRefOid` from Step 1. The `Accept: application/vnd.github.raw` header returns the raw file content directly (without the base64-encoded JSON wrapper). Count line numbers from the start of the returned content.

## Output

Return results keyed by step. Consuming protocols specify their own output format — this protocol defines only the fetch sequence, not how results are assembled.

```
PR_METADATA: <raw JSON from Step 1>
CI_CHECKS: <raw JSON from Step 2>
REVIEWS: <raw JSON from Step 3>
INLINE_COMMENTS: <raw JSON from Step 4>
ISSUE_COMMENTS: <raw JSON from Step 5>
COMMITS: <raw JSON from Step 6>
THREAD_RESOLUTION: <raw JSON from Step 7>
```

### Consuming the output

Each step's value is already a single well-formed JSON array (or object, for Step 1). Read it directly with one `json.load` / `jq .`; do not re-improvise the page merge.

## Edge Cases

- **PR not found or no access**: Surface the `gh` error verbatim. Do not guess.
- **CI checks unavailable**: Emit `CI_CHECKS: null` with a note `data unavailable: <error>`.
- **Concatenated per-page arrays (`json.load` "Extra data")**: dropping `--slurp` or the piped `jq` from any paginated step reintroduces per-page concatenated arrays; the Output Shape Contract above explains the mechanism.
- **Thread resolution exceeds 100**: The GraphQL query caps at 100 threads. Note truncation if the PR has more than 100 review threads.
- **Step failure**: Record the error for the failed step and continue with the remaining steps. Do not abort the full fetch.
