# Mob Review Output

Governs the output location and file naming convention for review artifacts produced during the mob pipeline and pre-ship review. This protocol is the authoritative source for where review reports are written to disk.

Report format is owned by each agent's definition and its format protocol (e.g., `pr-review.md` for Friedman and Fagan). This protocol owns only the output path and naming.

## Parameters

- `feature-slug` — kebab-case identifier for the feature (e.g., `store-country-backfill`). Once a PR number is known, prefix it: `pr-274330-store-country-backfill`. Caller-supplied or derived from the task description.

## Steps

1. **Determine the feature directory** — `scratch/output/_<feature-slug>/`. `scratch/` resolves to the HopLegion repo per `rules/scratch-path-resolution.md`. If the directory does not exist, create it before writing.

2. **Determine the artifact number** — List the feature directory contents. Find the next available number N for the agent (starting at 1). Do not infer N from memory or prior conversation context per `rules/feature-directory-lifecycle.md`.

3. **Write the report** to the determined path (see naming conventions below).

4. **Report the path** to the caller. The report is always written to disk; downstream agents and the orchestrator read from the file, not from chat history.

## Naming Conventions

### Mob Pipeline

| Agent | Single instance | Parallel instances |
|-------|----------------|-------------------|
| Oppenheimer | `oppenheimer_<N>.md` | `oppenheimer_<N>a.md`, `oppenheimer_<N>b.md` |
| Friedman | `friedman_<N>.md` | `friedman_<N>a.md`, `friedman_<N>b.md` |

Single instance is used for revision re-reviews. Parallel instances are used for initial review passes; Winterbotham consolidates the suffixed reports into the canonical `<agent>_<N>.md`.

### Pre-Ship Review

| Agent | Single instance | Parallel instances |
|-------|----------------|-------------------|
| Fagan | `fagan_preship_<N>.md` | `fagan_preship_<N>a.md`, `fagan_preship_<N>b.md` |
| Oppenheimer | `oppenheimer_preship_<N>.md` | `oppenheimer_preship_<N>a.md`, `oppenheimer_preship_<N>b.md` |

Consolidated pre-ship review: `pre-ship-review.md` (always this name, no numbering).

### Parallel Instance Suffix

When dispatched as a parallel instance, the dispatch provides a filename suffix (e.g., `oppenheimer_1a.md`). Use the suffix as given. Do not infer or change it.

## Orchestrator-Side Output Verification

The base Claude Code harness pushes subagents toward inline responses over file creation. This protocol governs review reports, which are inherently analysis documents and therefore hit that bias directly. Subagents sometimes skip the Write tool and return the report content as their final assistant message, with or without a rationalization.

After any dispatch governed by this protocol returns, the orchestrator verifies the expected file exists at the expected path before advancing the pipeline:

1. Compute the expected path from the feature slug, agent name, and artifact number.
2. Check the path exists and is non-empty.
3. If the file is missing, the review did not complete. Two recovery options:
   - **Reconstruct from the task notification.** If the agent's return value contains the full report content (as inline markdown that matches the expected format), the orchestrator writes that content to the expected path directly. This is the fast path and avoids re-running the review.
   - **Redispatch.** If the return value does not contain the report content, or the content appears truncated, redispatch the agent with an added instruction: "Write the report to disk with the Write tool. This is not optional; the file must exist on disk at the end of the dispatch. The orchestrator reads from the file, not from your assistant message."

The verification step is unconditional. A "clean" return that reports success but leaves no file on disk is a failed dispatch, not a success.

## Edge Cases

- If the output directory does not exist, create it before writing.
- Resolve the HopLegion repo path from the additionalDirectory registration or context before writing. Use absolute paths for all file operations.
- A revision pass after a blocker uses the next available N (e.g., if `oppenheimer_1.md` exists, the re-review writes `oppenheimer_2.md`).
