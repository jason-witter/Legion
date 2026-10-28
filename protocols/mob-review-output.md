# Mob Review Output

Governs the output location and file naming convention for review artifacts produced during the mob pipeline and pre-ship review. This protocol is the authoritative source for where review reports are written to disk.

Report format is owned by each agent's definition and its format protocol (e.g., `pr-review.md` for Friedman and Fagan); finding tiers and report sectioning are owned by `protocols/finding-disposition.md`. This protocol owns the output path and naming, including the run scope the path carries, and the citation floor a finding's code claims meet.

## Parameters

- `feature-slug` — kebab-case identifier for the feature (e.g., `user-settings-backfill`). Once a PR number is known, prefix it: `pr-1234-user-settings-backfill`. Caller-supplied or derived from the task description.
- `run-scope` — optional lowercase token naming the surface this pass reviews (e.g. `refund`, `taxcorr`). Supplied by the dispatch when the feature holds more than one run; never invented by the station. `rules/feature-directory-lifecycle.md` defines a run and its boundary test.

## Steps

1. **Determine the feature directory** — `scratch/output/_<feature-slug>/`. Reports land at its root, which is the pipeline-artifact class. Path resolution and directory creation per `rules/scratch-path-resolution.md`.

2. **Determine the artifact name** — Run `scripts/next-artifact.sh <feature-dir> <agent> [run-scope]` and use what it prints. N is counted inside the (agent, run) pair, so a second run's numbering does not continue the first. Do not infer N from memory or prior conversation context per `rules/feature-directory-lifecycle.md`.

3. **Write the report** to the determined path (see naming conventions below).

4. **Report the full filename** to the caller, not the directory. The report is always written to disk, and what reaches a later station is the file a dispatch names (`rules/dispatch-shape.md`), never chat history and never the directory it sits in.

## Naming Conventions

### Mob Pipeline

| Agent | Single instance | Parallel instances |
|-------|----------------|-------------------|
| Oppenheimer | `oppenheimer_<N>.md` | `oppenheimer_<N>a.md`, `oppenheimer_<N>b.md` |
| Friedman | `friedman_<N>.md` | `friedman_<N>a.md`, `friedman_<N>b.md` |

Single instance is the default for all passes; `protocols/scope-proportional-pipeline.md` governs when a dual pass runs. Parallel suffixed instances apply only in dual mode, where the dispatch provides the suffix and Winterbotham consolidates the suffixed reports into the canonical `<agent>_<N>.md`.

### Pre-Ship Review

| Agent | Single instance | Parallel instances |
|-------|----------------|-------------------|
| Fagan | `fagan_preship_<N>.md` | `fagan_preship_<N>a.md`, `fagan_preship_<N>b.md` |
| Oppenheimer | `oppenheimer_preship_<N>.md` | `oppenheimer_preship_<N>a.md`, `oppenheimer_preship_<N>b.md` |

Consolidated pre-ship review: `pre-ship-review.md` (always this name, no numbering).

### Run Scope

A run scope rides the same infix slot the pre-ship stage uses, which is why pre-ship needs no separate mechanism: a review stage is one kind of run.

| Situation | Name |
|---|---|
| Feature with one run | `friedman_1.md` |
| Feature with several runs | `friedman_refund_1.md`, `friedman_taxcorr_1.md` |
| Several runs, parallel pass | `friedman_taxcorr_1a.md` |

The slot holds one token, so a pre-ship pass is scoped `preship` and takes no surface token on top of it. A pre-ship review is a run.

Use the scope the dispatch gives, verbatim and unabbreviated, the same discipline as the parallel suffix below. A mistyped scope silently opens a new run rather than erroring, which loses the report to a run nothing will look in.

### Parallel Instance Suffix

When dispatched as a parallel instance, the dispatch provides a filename suffix (e.g., `oppenheimer_1a.md`). Use the suffix as given. Do not infer or change it.

## Directives and Reasoning

A review artifact's actionable content is already separable, by construction: the finding's tier is the directive and its ask is the instruction, per `protocols/finding-disposition.md`, and the evidence under it is the reasoning that justifies the tier. That is what its sectioning is for.

Two consequences worth stating, because both are how the separation gets lost in practice:

- **An ask stated only in the evidence is not an ask.** The tier gate requires the finding itself to carry the change the reviewer wants. A finding whose instruction is buried in a paragraph of analysis fails the gate and drops a tier.
- **A verification pass discharges findings; it does not inherit their conclusions.** The prior report in a discharge dispatch is an additional obligation on top of a full pass, never a scope for it (`rules/dispatch-shape.md`, `protocols/mob-pipeline.md`). Its findings bind as items to close; its statements about the tree are re-derived, not carried forward (`protocols/finding-disposition.md`, Clearing or downgrading a finding).

### Code claims carry `path:line`

Every finding's claim about the tree carries its location. This is the floor, not the ceiling:

- **Friedman and Fagan** are held to the stronger contract in `protocols/pr-review.md`, which requires a ref-pinned read plus the exact line content beside the citation. That protocol governs them.
- **A design critique** meets the floor: a claim about the tree with no location is unverified. `protocols/finding-disposition.md`'s tier gate already discards an uncited finding rather than filing it, and `rules/code-facts-from-the-tree.md` is why.

## Orchestrator-Side Output Verification

After any dispatch governed by this protocol returns, the orchestrator applies `protocols/post-dispatch-artifact-verify.md` before advancing the pipeline, against the run-scoped filename this protocol produced. That protocol is the sole authority for missing-artifact classification, backfill, and recovery; re-dispatch is never automatic.

`scripts/current-artifact.sh <feature-dir> <agent> [run-scope]` prints the current artifact for an (agent, run) pair, so the orchestrator names a discharge report without working out currency by hand.

## Edge Cases

- A revision pass after a Blocking finding stays in the same run and takes the next N inside it (e.g., if `oppenheimer_1.md` exists, the re-review writes `oppenheimer_2.md`; in a scoped run, `oppenheimer_refund_1.md` is followed by `oppenheimer_refund_2.md`). Fix rounds are not a new run.
