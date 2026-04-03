# pr-queue-review

Orchestrate a full PR queue review session: fetch authored PRs and review requests, filter noise, fan out to analysis agents, and synthesize a single actionable briefing.

Read-only — produces a briefing report only. Does not post, approve, or comment on any PR.

## Prerequisites

- Grace integration protocols for review requests and authored PRs must be installed
- `gh` CLI installed and authenticated in the execution environment
- Fagan and Denniston agents must be available for dispatch

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `authored` | `true` | Include authored PRs (dispatches Denniston per PR with actionable feedback) |
| `review_requests` | `true` | Include review requests (dispatches Fagan per qualifying PR) |
| `all_requests` | `false` | Skip individual-assignment filtering on review requests — return all requests including team-based |

## Execution Steps

Steps 1 and 2 run sequentially (fetch before dispatch). Steps 3 and 4 run concurrently — dispatch both fan-outs simultaneously, do not wait for Fagan to finish before dispatching Denniston.

### Step 1 — Fetch review requests

Dispatch Grace to fetch the review request queue using the review-requests-fetch integration protocol. Pass `all_requests` parameter through.

Grace returns a structured list. Each item must include: PR number, repo (`OWNER/REPO`), title, author login, created date, last activity date, draft status, and approval state (approvals already received vs. required).

**Apply scoping filters before Step 3.** After Grace returns, filter OUT the following from the review request list:

- Author login is a CI/status bot — identified by the `[bot]` suffix AND the account's activity on the PR is limited to status checks, automated commits, or merge actions (no inline comments, no review-level feedback). Accounts with the `[bot]` suffix that have posted inline comments or review-level feedback are not CI bots and must not be filtered here.
- Title starts with `[DNM]`, `DO NOT MERGE`, or `[WIP]` (case-insensitive)
- Repository is archived (`archived: true` in repo metadata)
- PR was created more than 90 days ago AND last updated more than 14 days ago — stale CODEOWNERS noise
- PR already has sufficient approvals to merge AND the review state shows no pending changes requested — break-glass retroactive reviews that don't need action

Record each filtered item with its reason. Include the tally in the final briefing.

### Step 2 — Fetch authored PRs

When `authored` is `true`: dispatch Grace to fetch authored PRs using the authored-prs-fetch integration protocol.

Grace returns a structured payload per PR including review comments, inline annotations, CI status, and approval state.

**Apply dispatch trigger before Step 4.** After Grace returns, determine which authored PRs qualify for Denniston dispatch:

Dispatch Denniston when the PR has at least one of:
- A review-level comment with state `CHANGES_REQUESTED`
- A review-level comment with body text from a reviewer (human or code review bot) — non-empty body, non-CI-bot author
- One or more inline comments from a reviewer (human or code review bot)

Treat an account as a code review bot (not a CI bot) when its activity includes inline comments or review-level feedback on the code, regardless of whether its login ends in `[bot]`. Treat an account as a CI bot when its only activity is status checks, automated commits, or merge actions.

Skip Denniston when:
- The PR has no reviews and no comments at all
- Every review and comment is from a CI bot
- The PR is a draft with zero review activity

Record each skipped PR with reason. Include the tally in the final briefing.

### Step 3 — Fan out to Fagan

Dispatch one Fagan instance per qualifying review request (post-filter list from Step 1). Follow `fan-out-dispatch` protocol for parallel dispatch.

Each Fagan instance receives:
- PR identifier: `#NUMBER in OWNER/REPO`
- PR title and author
- Current approval state
- Task: analyze this PR and produce a review report per the `pr-review` protocol

Fagan produces a review report per PR. Collect all reports.

### Step 4 — Fan out to Denniston

Dispatch one Denniston instance per qualifying authored PR (post-filter list from Step 2). Follow `fan-out-dispatch` protocol for parallel dispatch.

Each Denniston instance receives:
- PR identifier and URL
- The full per-PR data payload from Grace's authored-prs-fetch output for this PR
- Task: analyze the review feedback and produce an action digest

Denniston produces an action digest per PR. Collect all digests.

### Step 5 — Synthesize

After all agent instances complete, produce the PR Queue Briefing (see Output Format).

## Output Format

```markdown
# PR Queue Briefing — <YYYY-MM-DD>

## Review Requests (<N> of <total> after filtering)

### <PR title> — #<number> (<OWNER/REPO>)

**Author:** @<login>
**Recommendation:** <Approve | Request Changes | Cannot Review>
**Top finding:** <one-line summary of highest-severity finding, or "No blocking issues">

<Additional findings summary if any — 1-3 lines max>

---

[Repeat per reviewed PR]

## Your Open PRs (<N> of <total> with feedback)

### <PR title> — #<number>

**Status:** <CHANGES_REQUESTED | APPROVED | REVIEW_REQUIRED>
**Action required:** <Yes | No>
**Summary:** <1-2 sentence summary of what reviewers are asking for>

---

[Repeat per PR with actionable feedback]

## Filtered / Skipped

**Review requests filtered:** <N> — <reason breakdown, e.g., "3 bot PRs, 1 DNM, 2 stale">
**Authored PRs skipped:** <N> — <reason breakdown, e.g., "2 no human feedback, 1 draft">

[Omit this section entirely if nothing was filtered or skipped]
```

Ordering: within Review Requests, sort by Fagan's recommendation — Request Changes first, then Approve, then Cannot Review. Within Your Open PRs, sort by urgency — CHANGES_REQUESTED first, then REVIEW_REQUIRED, then APPROVED.

If a section has no items after filtering, omit it.

## Error Handling

- **Grace fetch fails**: Surface the error and stop. Do not proceed to dispatch agents against incomplete data.
- **Individual Fagan/Denniston failure**: Note the failure against the PR identifier. Continue collecting results from remaining instances. Include the failed item in synthesis with a failure note.
- **All agents fail for one category**: Report total failure for that category. Synthesize what is available from the other category.
- **Empty queue**: Emit a one-line summary — "No review requests" or "No authored PRs with pending feedback" — and stop. Do not dispatch agents against an empty list.

## Edge Cases

- **`authored: false`**: Skip Steps 2 and 4 entirely.
- **`review_requests: false`**: Skip Steps 1 and 3 entirely.
- **Both `false`**: Nothing to do — report that both categories are disabled.
- **PR appears in both categories** (user is both author and assigned reviewer): Treat them independently. Include in both sections with appropriate framing.
- **Stale threshold**: The 90-day creation / 14-day activity filters are defaults. If the deployment has a different staleness convention, adjust the filter thresholds accordingly.
- **Bot classification**: The default heuristic classifies bots by activity type, not account suffix. An account with `[bot]` in its login that posts inline comments or review-level feedback is a code review bot and is treated like a human reviewer for dispatch and filtering purposes. An account whose only activity is status checks, automated commits, or merge actions is a CI bot and is filtered/skipped. Deployments can extend this with a configured exclusion list of known CI automation accounts in the local integration protocol.
