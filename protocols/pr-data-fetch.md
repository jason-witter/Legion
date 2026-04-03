# pr-data-fetch

Fetch all review-relevant data for a single PR: metadata, review decisions, inline annotations, issue comments, CI status, commit history, and thread resolution. Produces raw structured data — no analysis, no scoring.

Read-only. Does not post, comment, or modify anything.

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
gh api repos/OWNER/REPO/pulls/NUMBER/reviews --paginate --jq '[.[] | {id,user:.user.login,state,body,submitted_at}]'
```

Step 4: Fetch inline comments — code annotations tied to specific file lines.

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments --paginate --jq '[.[] | {id,user:.user.login,path,line,original_line,body,created_at,updated_at,in_reply_to_id}]'
```

Step 5: Fetch issue-level comments — general PR thread discussion not tied to code lines.

```bash
gh api repos/OWNER/REPO/issues/NUMBER/comments --paginate --jq '[.[] | {id,user:.user.login,body,created_at,updated_at}]'
```

Step 6: Fetch commit history — used for staleness assessment and re-review scoping.

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/commits --paginate --jq '[.[] | {sha:.sha,message:.commit.message,date:.commit.committer.date,author:.commit.author.name}]'
```

Step 7: Fetch thread resolution status via GraphQL — maps each review thread to resolved/unresolved and links back to inline comment IDs from Step 4 via `first_comment_id`.

```bash
gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100){nodes{id isResolved resolvedBy{login} comments(first:1){nodes{databaseId}}}}}}}' -f owner=OWNER -f repo=REPO -F number=NUMBER --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | {thread_id:.id,is_resolved:.isResolved,resolved_by:.resolvedBy.login,first_comment_id:.comments.nodes[0].databaseId}]'
```

Steps 1–7 are independent of each other — issue all seven in a single response as parallel tool calls.

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

## Edge Cases

- **PR not found or no access**: Surface the `gh` error verbatim. Do not guess.
- **CI checks unavailable**: Emit `CI_CHECKS: null` with a note `data unavailable: <error>`.
- **Thread resolution exceeds 100**: The GraphQL query caps at 100 threads. Note truncation if the PR has more than 100 review threads.
- **Step failure**: Record the error for the failed step and continue with the remaining steps. Do not abort the full fetch.
