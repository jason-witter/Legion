# Post-Dispatch Artifact Verify

After every agent dispatch expected to produce a named artifact, verify the artifact exists at the expected path before advancing the pipeline. When the artifact is missing but the content is recoverable from the task-notification result, backfill it inline. When the content is not recoverable, surface the failure and halt the pipeline station.

This protocol is the sole authority for artifact verification and skipped-Write recovery. Other protocols reference it by name rather than restating recovery steps; where an older restatement conflicts with this file, this file wins. Re-dispatch is never automatic (Step 6).

## Usage

Invoke this protocol whenever an agent dispatch's contract includes producing a file artifact, and a downstream station depends on that file. Canonical triggers:

- Mob pipeline stations (Babbage design, Lovelace implementation, Friedman/Oppenheimer review, Winterbotham consolidation, Curie validation plan, Asimov per-file reports)
- Ticket writing (Penkovsky, per `ticket-output.md`) and execution plans returned from a planning dispatch, when the dispatch named a path
- Pre-ship review passes (Fagan, Oppenheimer pre-ship, consolidated pre-ship)
- PR queue review fan-outs (Fagan per review request, Denniston per authored PR)
- Fan-out item agents that write per-item artifacts
- Any dispatch where the next step reads a file the dispatched agent was supposed to write

This protocol does not apply to dispatches whose contract is "return content in the task notification" (e.g., quick fetches, classification calls). The trigger is the artifact contract, not the dispatch itself.

## Parameters

- `expected_path` — absolute path the dispatch named, run-scoped per `rules/feature-directory-lifecycle.md` (`<agent>_<run>_<N>.md`, or `<agent>_<N>.md` while a feature holds one run). The orchestrator assigns this filename in the dispatch, so verification runs against the name the dispatch gave and never against whatever file the agent happened to write.
- `task_result` — the dispatched agent's task-notification payload (status + content)
- `artifact_type` — handoff, review, design, validation-plan, digest, etc. Used to look up the governing protocol per `rules/artifact-protocol-check.md`.

## Steps

### Step 1: Verify the artifact exists

Run `ls` against `expected_path`. Do not trust the agent's `status: completed` signal alone.

```
ls /abs/path/to/scratch/output/_<slug>/friedman_taxcorr_2.md
```

Expected: the file exists and is non-empty. If yes, proceed to Step 2. If missing or empty, jump to Step 4.

If the feature directory itself is gone, or an `Edit` on a file in it reports the file does not exist, the directory was most likely archived mid-session rather than never written. Read the deployment's archive protocol (`protocols/local/archive-scratch-output.md` here) for the restore and the hold that prevents a repeat, before classifying anything as a missing write.

### Step 2: Verify placement — directory, class, and run

Confirm three things about where the artifact landed, all per `rules/feature-directory-lifecycle.md`. A stale or misplaced artifact is treated as missing.

1. **Directory.** The artifact is in the current feature directory. If the directory was renamed mid-pipeline (PR number assigned), the agent may have written to the pre-rename path; move the file to the current path before advancing, and do not duplicate.
2. **Class.** A pipeline artifact sits at the directory root, and an external artifact (fetch output, transcript, instrument doc) sits in `external/`. An artifact written into `record/` is misplaced by definition: nothing there is ever dispatched to a station.
3. **Run.** The filename carries the run scope the dispatch named. A report written to an unscoped name while the feature holds several runs, or under a scope that differs from the dispatch's, opens a phantom run instead of erroring, and `scripts/current-artifact.sh <feature-dir> <agent> <run-scope>` then returns nothing for the run the next station will be dispatched against. Rename the file to the dispatched filename before advancing.

### Step 3: Advance the pipeline

If Steps 1 and 2 pass, the dispatch is complete. Advance to the next station. Do not re-read the artifact's content here — that's the next station's job.

### Step 4: Classify the failure mode

The artifact is missing. Determine which case applies by inspecting `task_result`:

- **Case A — completed-but-skipped-write**: `status: completed` and the task-notification content contains the full artifact body (review report, design doc, etc.) but no Write tool call was made. Content is recoverable. A Write the harness refused is Case A too; see Refused Writes below.
- **Case B — timeout or stream error**: The task notification reports an idle timeout, stream interruption, or partial result. Content may be partial or absent.
- **Case C — agent error**: `status: failed` or the notification reports a tool error before the artifact stage. No content to recover.

### Step 5: Backfill (Case A only)

When the content is recoverable from the task notification:

1. Read the governing artifact protocol per `rules/artifact-protocol-check.md` (e.g., `mob-review-output.md`, `pre-ship-review.md`).
2. Verify the task-notification content satisfies the protocol's required structure. If it does not, treat as Case C — do not paper over a malformed artifact.
3. Write the content to `expected_path` exactly as the agent reported it. Do not edit, summarize, or restructure.
4. Note the backfill in the feature directory README, not the pipeline narrative: "Artifact backfilled from task notification (Case A — agent skipped Write)." Artifact provenance is process commentary, which `protocols/pipeline-narrative.md` excludes; the README is the record-class home for it.
5. Advance to the next station.

### Step 6: Halt and surface (Cases B and C)

When content is not recoverable:

1. Do not re-dispatch automatically. The user decides whether to retry, skip, or abort.
2. Report to the user with: artifact path, failure case, what was recoverable from the task notification (if anything), and the recommended next action (re-dispatch, manual consolidation, abort station).
3. Halt the pipeline at the failed station. Do not advance to dependent stations.

## Refused Writes

The subagent note against report files (`rules/artifact-on-disk.md` quotes it) is not only a prompt note. On at least one surface the harness enforces it on the Write itself: on 2026-09-30 a fork's Write of a `findings.md` report was refused with "Subagents should return findings as text, not write report files", while `.sql` files in the same directory wrote normally. No hook or settings entry produces that message; it is built into Claude Code. Named framework agents wrote their `.md` artifacts without refusal in the same session, but two variables differ between the cases: the surface (fork versus named agent) and the filename (`findings.md` versus station-named artifacts like `babbage_1.md`). Which one the enforcement keys on is not established, so treat a refusal on any surface the same way.

The rule tells the subagent to write whatever supporting files are not refused and return the full artifact text as its final message, naming the path it was meant for. The dispatching session then:

1. Writes that text verbatim to the named path, through Step 5. The recovery is mechanical, not a decision point for the user.
2. Continues the pipeline. The artifact still lands on disk before anything downstream reads it; only the hand that writes it changes.

When composing an artifact-producing dispatch, prefer a named agent over a fork where one fits, since that surface has not shown the refusal.

## Failure Modes This Protocol Prevents

- Downstream station fails on missing input file because upstream agent reported `completed` without writing.
- Pipeline narrative claims a station succeeded when only the task-notification was produced and no durable artifact exists.
- Manual scavenger hunts after the fact to reconstruct what an agent reported in a notification that has since scrolled out of view.
- A verification pass dispatched against a phantom run, because the report it must discharge was written under a scope the dispatch never named and the currency lookup comes back empty.

## Cross-References

- `rules/artifact-on-disk.md`: the agent-side half, including what a subagent does when its Write is refused
- `rules/artifact-protocol-check.md` — governs the format of any backfilled artifact
- `rules/feature-directory-lifecycle.md` — governs `expected_path` resolution, the three classes, and run scope and currency
- `scripts/current-artifact.sh` — prints the current artifact for an `(agent, run)` pair; an empty result is the mistyped-scope signal Step 2 checks for
- `rules/dispatch-shape.md` — the orchestrator names the artifact in the dispatch and must not anchor downstream stations to backfill content; each consuming agent reads the named file itself
- `rules/dispatch-and-continue.md` — verification happens before the next dispatch, not after the user prompts for status

## Out of Scope

- Agent-side fixes to make Write calls more reliable (routed to Vera)
- Watchdog status-check infrastructure changes (separate framework infra work)
- Automatic re-dispatch logic (deliberate; user decides on retry per `fan-out-dispatch.md` error handling)
