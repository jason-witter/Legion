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
| `scoped_model` | `sonnet` | Model override applied to SCOPED Fagan dispatches (Step 3). Set to `opus` to revert to Fagan's own pin. |

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

**Draft status is not a filter reason.** An individually-requested review on a draft PR dispatches the same as a non-draft, because the tag signals the author wants early feedback. Draft status affects presentation only: categorize drafts separately in queue output. This is orthogonal to review posture; a draft dispatches in whichever posture applies.

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
- Posture and its parameters when the caller supplied them (`gating_teams`, `owned_paths`); absence means HOLISTIC per `protocols/pr-review.md`
- Task: analyze this PR and produce a review report per the `pr-review` protocol

**Model per posture.** Dispatch SCOPED instances with the `scoped_model` override (`sonnet` by default). Dispatch HOLISTIC instances with no override, so Fagan's own `opus` pin applies. A scoped review inspects an ownership-filtered slice; a holistic review carries the whole diff and keeps the stronger model. The override is per dispatch only: Fagan's definition is not modified and its effort setting still applies.

The override is the only cost lever this step pulls. One instance per qualifying PR, all concurrent, is the shape of the fan-out; do not batch, gate, or trim it to save spend.

Fagan produces a review report per PR. Collect all reports.

### Step 4 — Fan out to Denniston

Dispatch one Denniston instance per qualifying authored PR (post-filter list from Step 2). Follow `fan-out-dispatch` protocol for parallel dispatch.

Each Denniston instance receives:
- PR identifier and URL
- The full per-PR data payload from Grace's authored-prs-fetch output for this PR
- Task: analyze the review feedback and produce an action digest

Denniston produces an action digest per PR. Collect all digests.

### Step 5 — Verify artifacts and synthesize

Before synthesizing, apply `protocols/post-dispatch-artifact-verify.md` to each Fagan and Denniston dispatch; it is the sole authority for missing-artifact recovery. Do not advance to synthesis with missing artifacts.

After all artifacts are on disk, produce the PR Queue Briefing (see Output Format).

## Scoped Model Experiment

The `scoped_model` default is an open experiment, not a settled setting. This fan-out is the most expensive routine event in the framework (one max-effort agent per qualifying PR, all concurrent), Sonnet 5 currently rates near Opus on coding and agentic work, and its intro pricing is reported to run through 2026-08-31. The scoped half of the fan-out is the cheapest place to test that: the inspection surface is already narrowed to owned paths.

Keep it observable. While the experiment is open, compare each run's scoped reports against the opus-era scoped baselines in the dated reviews directories (`scratch/output/YYYY-MM-DD/reviews/*-scoped-*.md`) and report to the user:

- Owned-path findings the scoped review missed or under-rated
- Citation discipline: ref-pinned line numbers and exact line content per `protocols/pr-review.md`
- Sign-off phrased from the gating teams' standpoint, with the Coverage section present
- False positives the confidence filter should have cut

Resolve after several runs rather than leaving it open. If quality holds, delete this section and keep the default. If it slips, set `scoped_model` to `opus` and delete this section.

## Output Format

```markdown
# PR Queue Briefing — <YYYY-MM-DD>

## Review Requests (<N> of <total> after filtering)

### <PR title> — #<number> (<OWNER/REPO>)

**Author:** @<login>
**Recommendation:** <Request Changes | Approve with Comments | Approve | Cannot Review>
**Top finding:** <one-line summary of the highest-tier finding, or "No Blocking findings">

<Additional comment candidates if any — 1-3 lines max. Recorded findings stay in the report and do not appear in the briefing.>

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

Ordering: within Review Requests, sort by Fagan's recommendation — Request Changes first, then Approve with Comments, then Approve, then Cannot Review. The recommendation follows from the finding tiers and is not an independent judgment: `protocols/finding-disposition.md` derives it (any Blocking means Request Changes; no Blocking plus at least one Comment means Approve with Comments; neither means Approve). Within Your Open PRs, sort by urgency — CHANGES_REQUESTED first, then REVIEW_REQUIRED, then APPROVED.

If a section has no items after filtering, omit it.

## Standalone Denniston Dispatch

When Denniston is dispatched outside this pipeline (e.g., "digest feedback on PR #X"), always dispatch Grace first to fetch current PR data. Do not reuse data from a prior pipeline run.

Queue review fetches are point-in-time snapshots tied to that pipeline execution. A standalone request may come hours or days later when the PR has new reviews, comments, and CI state. Reusing stale data produces an outdated digest.

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
