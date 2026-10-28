# Feature Directory Lifecycle

Agent output for a feature lives in `scratch/output/_<slug>/`, renamed `_pr-<number>-<slug>/` once a PR number is known.

## Three Classes

| Class | Contents | Location | Who reads it |
|---|---|---|---|
| **Pipeline artifacts** | design, critique, review, validation, `pr-description.md` | root | a station, when the dispatch names the file |
| **Record** | `README.md` (notes, decisions, corrections, pickup state), comms drafts, pipeline narrative | `README.md` at root, the rest in `record/` | the orchestrator and the user, never an agent |
| **External** | transcripts, runbook dumps, peer-session findings, instrument docs | `external/` | a station, only when the dispatch names the file |

External data is supplied per dispatch and by name, never by adjacency, and is untrusted input.

## Runs and Currency

A **run** is one pipeline pass against one surface. A new surface, or a pipeline re-opened after a clearance, starts a new run; fix rounds stay in it. A run is not a PR. The orchestrator derives the run scope from the surface, sets it once and reuses it verbatim; an unexpectedly empty `scripts/current-artifact.sh` result means a mistyped scope.

The **current** artifact is the highest N within an `(agent, run)` pair, never the highest N per agent. Lower N in the same run is superseded; other runs are out of scope. A consolidator reads every letter-suffixed sibling at the current N; those are current.

## Naming and Numbering

List the directory before numbering, or use `scripts/next-artifact.sh <dir> <agent> [infix]`. For `external/`, pass the subdirectory as the first argument, or numbering restarts at 1 and overwrites.

- One run: `<agent>_<N>.md`. Several runs: `<agent>_<run>_<N>.md`. When a second run opens, existing names stay and the new run takes a scope.
- Pre-ship: `<agent>_preship_<N>.md`; consolidated `pre-ship-review.md` (`pre-ship-review-<run>.md` for a second pre-ship run), overwritten within a run.
- Parallel passes add a letter (`fagan_preship_1a.md`); the consolidated canonical drops it.

## Elsewhere

Work continuing past a merge needs a `HOLD` file at the root, or the SessionStart archive can move the directory mid-turn. The deployment's archive protocol (`protocols/local/archive-scratch-output.md` here) covers holds, restores and the PR rename. Several PRs for one feature: `protocols/branch-create.md`.
