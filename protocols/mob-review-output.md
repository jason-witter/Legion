# Mob Review Output

Governs the output location and file naming convention for review artifacts produced during the mob pipeline and pre-ship review. This protocol is the authoritative source for where review reports are written to disk.

Report format is owned by each agent's definition and its format protocol (e.g., `pr-review.md` for Friedman and Fagan); finding tiers and report sectioning are owned by `protocols/finding-disposition.md`. This protocol owns only the output path and naming.

## Parameters

- `feature-slug` — kebab-case identifier for the feature (e.g., `user-settings-backfill`). Once a PR number is known, prefix it: `pr-1234-user-settings-backfill`. Caller-supplied or derived from the task description.

## Steps

1. **Determine the feature directory** — `scratch/output/_<feature-slug>/`. Path resolution and directory creation per `rules/scratch-path-resolution.md`.

2. **Determine the artifact number** — List the feature directory contents. Find the next available number N for the agent (starting at 1). Do not infer N from memory or prior conversation context per `rules/feature-directory-lifecycle.md`.

3. **Write the report** to the determined path (see naming conventions below).

4. **Report the path** to the caller. The report is always written to disk; downstream agents and the orchestrator read from the file, not from chat history.

## Naming Conventions

### Mob Pipeline

| Agent | Single instance | Parallel instances |
|-------|----------------|-------------------|
| Oppenheimer | `oppenheimer_<N>.md` | `oppenheimer_<N>a.md`, `oppenheimer_<N>b.md` |
| Friedman | `friedman_<N>.md` | `friedman_<N>a.md`, `friedman_<N>b.md` |

Single instance is the default for all passes; `rules/scope-proportional-pipeline.md` governs when a dual pass runs. Parallel suffixed instances apply only in dual mode, where the dispatch provides the suffix and Winterbotham consolidates the suffixed reports into the canonical `<agent>_<N>.md`.

### Pre-Ship Review

| Agent | Single instance | Parallel instances |
|-------|----------------|-------------------|
| Fagan | `fagan_preship_<N>.md` | `fagan_preship_<N>a.md`, `fagan_preship_<N>b.md` |
| Oppenheimer | `oppenheimer_preship_<N>.md` | `oppenheimer_preship_<N>a.md`, `oppenheimer_preship_<N>b.md` |

Consolidated pre-ship review: `pre-ship-review.md` (always this name, no numbering).

### Parallel Instance Suffix

When dispatched as a parallel instance, the dispatch provides a filename suffix (e.g., `oppenheimer_1a.md`). Use the suffix as given. Do not infer or change it.

## Orchestrator-Side Output Verification

After any dispatch governed by this protocol returns, the orchestrator applies `protocols/post-dispatch-artifact-verify.md` before advancing the pipeline. That protocol is the sole authority for missing-artifact classification, backfill, and recovery; re-dispatch is never automatic.

## Edge Cases

- A revision pass after a Blocking finding uses the next available N (e.g., if `oppenheimer_1.md` exists, the re-review writes `oppenheimer_2.md`).
