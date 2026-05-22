# Post-Dispatch Artifact Verify

After every agent dispatch expected to produce a named artifact, verify the artifact exists at the expected path before advancing the pipeline. When the artifact is missing but the content is recoverable from the task-notification result, backfill it inline. When the content is not recoverable, surface the failure and halt the pipeline station.

## Usage

Invoke this protocol whenever an agent dispatch's contract includes producing a file artifact, and a downstream station depends on that file. Canonical triggers:

- Mob pipeline stations (Babbage design, Lovelace implementation, Friedman/Oppenheimer review, Winterbotham consolidation)
- Pre-ship review passes (Fagan, Oppenheimer pre-ship, consolidated pre-ship)
- Fan-out item agents that write per-item artifacts
- Any dispatch where the next step reads a file the dispatched agent was supposed to write

This protocol does not apply to dispatches whose contract is "return content in the task notification" (e.g., quick fetches, classification calls). The trigger is the artifact contract, not the dispatch itself.

## Parameters

- `expected_path` — absolute path the agent was instructed to write
- `task_result` — the dispatched agent's task-notification payload (status + content)
- `artifact_type` — handoff, review, design, validation-plan, digest, etc. Used to look up the governing protocol per `rules/artifact-protocol-check.md`.

## Steps

### Step 1: Verify the artifact exists

Run `ls` against `expected_path`. Do not trust the agent's `status: completed` signal alone.

```
ls /abs/path/to/scratch/output/_<slug>/<artifact>.md
```

Expected: the file exists and is non-empty. If yes, proceed to Step 2. If missing or empty, jump to Step 4.

### Step 2: Verify directory placement

Confirm the artifact landed in the current feature directory per `rules/feature-directory-lifecycle.md`. Stale or misplaced artifacts are treated as missing.

If the feature directory was renamed mid-pipeline (PR number assigned), the agent may have written to the pre-rename path. Move the file to the current path before advancing; do not duplicate.

### Step 3: Advance the pipeline

If Steps 1 and 2 pass, the dispatch is complete. Advance to the next station. Do not re-read the artifact's content here — that's the next station's job.

### Step 4: Classify the failure mode

The artifact is missing. Determine which case applies by inspecting `task_result`:

- **Case A — completed-but-skipped-write**: `status: completed` and the task-notification content contains the full artifact body (review report, design doc, etc.) but no Write tool call was made. Content is recoverable.
- **Case B — timeout or stream error**: The task notification reports an idle timeout, stream interruption, or partial result. Content may be partial or absent.
- **Case C — agent error**: `status: failed` or the notification reports a tool error before the artifact stage. No content to recover.

### Step 5: Backfill (Case A only)

When the content is recoverable from the task notification:

1. Read the governing artifact protocol per `rules/artifact-protocol-check.md` (e.g., `mob-review-output.md`, `pre-ship-review.md`).
2. Verify the task-notification content satisfies the protocol's required structure. If it does not, treat as Case C — do not paper over a malformed artifact.
3. Write the content to `expected_path` exactly as the agent reported it. Do not edit, summarize, or restructure.
4. Note the backfill in the pipeline narrative: "Artifact backfilled from task notification (Case A — agent skipped Write)."
5. Advance to the next station.

### Step 6: Halt and surface (Cases B and C)

When content is not recoverable:

1. Do not re-dispatch automatically. The user decides whether to retry, skip, or abort.
2. Report to the user with: artifact path, failure case, what was recoverable from the task notification (if anything), and the recommended next action (re-dispatch, manual consolidation, abort station).
3. Halt the pipeline at the failed station. Do not advance to dependent stations.

## Failure Modes This Protocol Prevents

- Downstream station fails on missing input file because upstream agent reported `completed` without writing.
- Pipeline narrative claims a station succeeded when only the task-notification was produced and no durable artifact exists.
- Manual scavenger hunts after the fact to reconstruct what an agent reported in a notification that has since scrolled out of view.

## Cross-References

- `rules/artifact-protocol-check.md` — governs the format of any backfilled artifact
- `rules/feature-directory-lifecycle.md` — governs `expected_path` resolution and rename handling
- `rules/dispatch-shape.md` — orchestrator must not anchor downstream stations to backfill content; artifacts are read by the consuming agent independently
- `rules/dispatch-and-continue.md` — verification happens before the next dispatch, not after the user prompts for status

## Out of Scope

- Agent-side fixes to make Write calls more reliable (routed to Vera)
- Watchdog status-check infrastructure changes (separate framework infra work)
- Automatic re-dispatch logic (deliberate; user decides on retry per `fan-out-dispatch.md` error handling)
