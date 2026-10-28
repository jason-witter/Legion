# pr-queue-review

Orchestrate a full PR queue review session: fetch authored PRs and review requests, filter noise, fan out to analysis agents, and synthesize a single actionable briefing.

Read-only — produces a briefing report only. Does not post, approve, or comment on any PR.

## Prerequisites

- Fetch protocols for review requests and authored PRs must be installed, along with `protocols/pr-data-fetch.md`
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

Dispatch Grace to fetch the review request queue. Pass `all_requests` through.

Grace returns a structured list. Each item must include: PR number, repo (`OWNER/REPO`), title, author login, created date, last activity date, draft status, and approval state (approvals already received vs. required).

**Apply scoping filters before Step 3.** After Grace returns, filter OUT the following from the review request list:

- Author login is a CI/status bot — identified by the `[bot]` suffix AND the account's activity on the PR is limited to status checks, automated commits, or merge actions (no inline comments, no review-level feedback). Accounts with the `[bot]` suffix that have posted inline comments or review-level feedback are not CI bots and must not be filtered here.
- Title starts with `[DNM]`, `DO NOT MERGE`, or `[WIP]` (case-insensitive)
- Repository is archived (`archived: true` in repo metadata)
- PR was created more than 90 days ago AND last updated more than 14 days ago — stale CODEOWNERS noise
- PR already has sufficient approvals to merge AND the review state shows no pending changes requested — break-glass retroactive reviews that don't need action

**Hold automation-authored PRs.** A review request whose author is on the deployment's automation-author list is not dispatched. List it in the briefing as held, and review it only when the user asks for that PR. These are typically mass reverts or retroactive-review PRs raised during incident remediation, which are expensive to verify and rarely need a full review. This deployment's list is `scripts/local/automation-authors.txt`, which the session-start path also reads.

**Draft status is not a filter reason.** An individually-requested review on a draft PR dispatches the same as a non-draft, because the tag signals the author wants early feedback. Draft status affects presentation only: categorize drafts separately in queue output. This is orthogonal to review posture; a draft dispatches in whichever posture applies.

Record each filtered item with its reason. Include the tally in the final briefing.

### Step 2 — Fetch authored PRs

When `authored` is `true`: dispatch Grace to fetch authored PRs. The fetch must persist. A non-persisting fetch returns bodies inline under the manifest truncation cap and cannot feed Step 4.

Grace returns one manifest covering the working set and writes one fetch artifact per PR. The manifest carries, per PR, the identifiers plus `review_decision`, `counts`, `commenting_logins`, `ci`, `feature_dir`, and `artifact:`. Review bodies, inline annotations, and thread resolution live in the per-PR artifact, never in the manifest.

**Rename any `feature_dir` the manifest flags `UNRENAMED`** per `rules/feature-directory-lifecycle.md` before Step 4. The rename is the orchestrator's; Grace writes into the directory as it stands and never creates a twin.

**Verify each fetch artifact before Step 4** per `protocols/post-dispatch-artifact-verify.md`, taking `expected_path` from that PR's `artifact:` line. A PR block reporting an error and no path is a failed fetch, not a missing write.

**Apply dispatch trigger before Step 4.** Determine which authored PRs qualify for Denniston dispatch from the manifest alone. Do not read the fetch artifacts to answer this; escaping that read is why the fetch persists.

Dispatch Denniston when the PR's manifest block shows at least one of:
- `review_decision: CHANGES_REQUESTED`
- A nonzero `reviews`, `inline_comments`, or `issue_comments` count, with at least one login in `commenting_logins` that is not CI automation

Classify logins from `commenting_logins` and `ci`. A login in `commenting_logins` posted a review or a comment and is treated as a reviewer, whether or not it ends in `[bot]`. A login appearing only under `ci` is CI automation. The manifest carries no bodies, so this is the whole basis available at dispatch time; content-level noise filtering is Denniston's, per `protocols/digest-analysis.md`.

Skip Denniston when:
- Every comment count is zero
- Every login in `commenting_logins` is CI automation
- The block carries no `artifact:` path

Record each skipped PR with reason, and report a missing `artifact:` path as a fetch failure rather than a quiet PR. Include the tally in the final briefing.

### Step 3 — Fan out to Fagan

Dispatch one Fagan instance per qualifying review request (post-filter list from Step 1). Follow `fan-out-dispatch` protocol for parallel dispatch.

Each Fagan instance receives:
- PR identifier: `#NUMBER in OWNER/REPO`
- PR title and author
- Current approval state
- Posture and its parameters when the caller supplied them (`gating_teams`, `owned_paths`); absence means HOLISTIC per `protocols/pr-review.md`
- Task: analyze this PR and produce a review report per the `pr-review` protocol

**Model and effort.** Dispatch both postures with no model override, so Fagan's own model pin applies. SCOPED narrows the file set and not the depth of the inspection, so it runs on the same model as HOLISTIC.

Effort is Fagan's definition default, raised per dispatch for a PR that touches a sensitive surface (permissions, review gating, CI config, policy, auth, agent steering files). Where the deployment configures an effort classifier, run it per qualifying PR before dispatch and pass a non-empty result as the Agent tool's per-dispatch effort override; an empty result means no override. This deployment's classifier is `scripts/local/classify-review-effort.sh`, contract in `protocols/local/review-posture-signals.md`; the session-start path calls the same script, so both paths share one rule. Do not raise or lower effort on any other basis.

One instance per qualifying PR, all concurrent, is the shape of the fan-out; do not batch, gate, or trim it.

Fagan produces a review report per PR. Collect all reports.

### Step 4 — Fan out to Denniston

Dispatch one Denniston instance per qualifying authored PR (post-filter list from Step 2). Follow `fan-out-dispatch` protocol for parallel dispatch.

Each Denniston instance receives:
- PR identifier and URL
- The fetch artifact path from that PR's manifest block (`artifact:`)
- Task: analyze the review feedback and produce an action digest

One artifact path per dispatch, named and not characterized (`rules/dispatch-shape.md`). The dispatch never carries the data; Denniston reads the artifact from disk.

Denniston produces an action digest per PR. Collect all digests.

### Step 5 — Verify artifacts and synthesize

Before synthesizing, apply `protocols/post-dispatch-artifact-verify.md` to each Fagan and Denniston dispatch; it is the sole authority for missing-artifact recovery. Do not advance to synthesis with missing artifacts.

These two fan-outs assign no filename at dispatch: each station derives its own report path from its output protocol. Verify against the path the station reports on completion, and treat a completion with no reported path as a missing artifact.

After all artifacts are on disk, produce the PR Queue Briefing (see Output Format).

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
**Authored PRs skipped:** <N> — <reason breakdown, e.g., "2 no feedback, 1 CI automation only, 1 fetch failed">

[Omit this section entirely if nothing was filtered or skipped]
```

Ordering: within Review Requests, sort by Fagan's recommendation — Request Changes first, then Approve with Comments, then Approve, then Cannot Review. The recommendation follows from the finding tiers and is not an independent judgment: `protocols/finding-disposition.md` derives it (any Blocking means Request Changes; no Blocking plus at least one Comment means Approve with Comments; neither means Approve). Within Your Open PRs, sort by urgency — CHANGES_REQUESTED first, then REVIEW_REQUIRED, then APPROVED.

If a section has no items after filtering, omit it.

## Standalone Denniston Dispatch

When Denniston is dispatched outside this pipeline (e.g., "digest feedback on PR #X"), dispatch Grace first for a fresh persisting fetch of that PR, then dispatch Denniston with the new artifact path.

Never point Denniston at a fetch artifact from a prior run. Each artifact is a snapshot as of its `fetched_at`, and a standalone request arrives after the PR's reviews, comments, and CI state have moved.

## Error Handling

- **Grace fetch fails wholesale** (auth failure, no manifest returned): Surface the error and stop. Do not proceed to dispatch agents against incomplete data.
- **One PR's fetch fails**: The manifest reports that block with an error and no `artifact:` path. Record it, skip that PR's Denniston dispatch, and continue with the rest of the working set.
- **Individual Fagan/Denniston failure**: Note the failure against the PR identifier. Continue collecting results from remaining instances. Include the failed item in synthesis with a failure note.
- **All agents fail for one category**: Report total failure for that category. Synthesize what is available from the other category.
- **Empty queue**: Emit a one-line summary — "No review requests" or "No authored PRs with pending feedback" — and stop. Do not dispatch agents against an empty list.

## Edge Cases

- **`authored: false`**: Skip Steps 2 and 4 entirely.
- **`review_requests: false`**: Skip Steps 1 and 3 entirely.
- **Both `false`**: Nothing to do — report that both categories are disabled.
- **PR appears in both categories** (user is both author and assigned reviewer): Treat them independently. Include in both sections with appropriate framing.
- **Stale threshold**: The 90-day creation / 14-day activity filters are defaults. If the deployment has a different staleness convention, adjust the filter thresholds accordingly.
- **Bot classification**: Account suffix is never the discriminator on either side. On authored PRs (Step 2), a login is a reviewer if it appears in `commenting_logins` and CI automation if it appears only under `ci`; the manifest supplies no other basis. On review requests (Step 1), the PR author is a CI bot when its activity on the PR is limited to status checks, automated commits, or merge actions. Deployments can extend either side with a configured list of known CI automation accounts in the local fetch protocol.
