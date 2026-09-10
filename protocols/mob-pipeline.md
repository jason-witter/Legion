# Mob Pipeline Protocol

Coordinate Babbage, Oppenheimer, Lovelace, Friedman, Curie, and Asimov to produce code changes against a software repo. Friday orchestrates — the agents do not communicate directly.

## Usage

Invoke when a coding task needs the full mob: design a technical approach, implement it, review the implementation, validate it works, and pass it through a tone scrub before the work leaves the local environment. Each station completes before the next begins. Friday manages every handoff.

## Station Sequence

Pipelines follow this fixed order:

1. **Babbage** (design) — produces a technical approach: scope, interface contracts, affected files, test strategy
2. **Oppenheimer** (design critique) — stress-tests the design for structural flaws before implementation begins
3. **Lovelace** (implementation) — produces code matching Babbage's design
4. **Friedman** (review) — evaluates Lovelace's implementation for correctness, security, and style
5. **Curie** (validation) — verifies the implementation works as intended
6. **Asimov** (tone scrub). Removes AI-identifiable patterns from the diff and the PR description before the work leaves the mob.

The full six-station sequence is the default. Station count is governed by `rules/scope-proportional-pipeline.md`, which is the single authority on when a station may be skipped (design already contained in the dispatch, single review pass for small localized changes, one-shot for trivial mechanical edits). When in doubt, run the full pipeline: review without design produces drift, validation without review produces unreviewed code, implementation without design critique risks structural flaws that are expensive to fix after the fact, and shipping without a tone scrub leaves the AI fingerprint that has cost real reviewer trust on prior PRs.

## Finding Tiers

`protocols/finding-disposition.md` is the authority for every review finding this pipeline produces. Its top tier, **Blocking**, is the pipeline's go/no-go binary: a station advances when its report carries no Blocking findings and loops back when it carries one. Comment and Noted findings never loop a station.

This protocol does not restate the tiers, the gate that assigns them, or the report sectioning. Read that file for all three.

## Hub-and-Spoke Model

Babbage, Oppenheimer, Lovelace, Friedman, Curie, and Asimov do not communicate directly. All information flows through Friday:

```
Friday → Babbage (task description, feature slug)
Babbage → Friday
Friday → Oppenheimer (feature slug, worktree path)
  [Full-surface change: ×2 with split lenses, suffixed output _Na.md/_Nb.md;
   Winterbotham consolidates → oppenheimer_N.md. See rules/scope-proportional-pipeline.md]
  [If Blocking: Friday → Babbage with the Blocking findings; Babbage revises once]
  [Friday → Oppenheimer (full re-review of revised design)]
  [If still Blocking: escalate to user; do not loop further]
  [If Comment or Noted only: Babbage addresses; no re-review needed]
Oppenheimer → Friday
Friday → Lovelace (feature slug, worktree path)
Lovelace → Friday
Friday → Friedman (feature slug, worktree path)
  [Full-surface change: ×2 with split lenses, suffixed output _Na.md/_Nb.md;
   Winterbotham consolidates → friedman_N.md. See rules/scope-proportional-pipeline.md]
Friday → Lovelace (terse Blocking findings: what and where) — if Blocking
Lovelace → Friday
Friday → Friedman (full re-review) — repeat until clean
Friedman → Friday
Friday → Curie (feature slug, worktree path)
Curie → Friday
Friday → Asimov (feature slug, worktree path)
Asimov → Friday
```

Babbage is the first station. He receives the task description and feature slug because there are no prior artifacts to orient from.

All other stations receive the feature slug and work location (worktree path or repo root). Each agent's definition tells it how to orient: what artifacts to look for in the feature directory (`scratch/output/_<feature-slug>/`), what to read in the codebase, and what lenses to apply. Friday does not summarize prior artifacts, pass design documents, or add attention directives. The feature directory is the communication medium between stations; Friday is the sequencer.

Dispatch shape rules (`rules/dispatch-shape.md`) govern what the orchestrator may and may not include in dispatches.

## Handoff Convention

Each station reports back to Friday. Friday uses the output to:

1. Distill the station's contribution into the running pipeline narrative (see `pipeline-narrative`)
2. Make the go/no-go decision for the next station

Friday does not construct context briefs or summaries for downstream stations. Each station orients from the feature directory and the codebase. The pipeline narrative is for the user's audit trail, not for inter-station communication.

## Go / No-Go Between Stations

After each station completes, Friday decides: advance, loop back, or escalate. The general principle: a report with no Blocking findings advances, a Blocking finding loops back to the originating station, and Blocking findings that persist past the loop cap escalate to the user. Comment and Noted findings are not part of this decision.

Specific guardrails:

- **Oppenheimer initial review**: A single full pass is the default. For full-surface designs (interface or return-shape changes, security surface), `rules/scope-proportional-pipeline.md` calls for two instances with split lenses writing suffixed reports (`oppenheimer_<N>a.md` and `oppenheimer_<N>b.md`), which Winterbotham consolidates into the canonical `oppenheimer_<N>.md`, deduplicating and applying the tier order in `protocols/finding-disposition.md` when both flag the same finding.
- **Oppenheimer revision re-review**: Babbage gets one revision attempt. Oppenheimer performs a full re-review of the revised design (not scoped to the prior Blocking findings). Comment and Noted findings go back to Babbage without Oppenheimer re-review.
- **Design-level issues surfaced during review or validation**: Escalate to the user rather than routing between Lovelace and Friedman. Implementation cannot fix a design problem.
- **Coverage gaps**: Carry whatever tier the reviewer assigned under the gate. A gap at Blocking loops back; a gap at Comment or Noted does not. Friday does not re-adjudicate a tier to route around it.
- **Loop cap**: 3 Friedman-Lovelace iterations (see iteration loop below). 1 Babbage-Oppenheimer revision. If Blocking findings persist after the cap, escalate.
- **Asimov is terminal**: Asimov runs once. Findings he resolves are absorbed into the squash commit. Findings he cannot resolve mechanically (genuine technical phrasing the catalog cannot reach, ambiguous identifier renames, anything that would change behavior) are recorded in `asimov_<N>.md` and surfaced to the user. They do not loop back to Lovelace and do not re-enter the Friedman queue. The pipeline halts on Blocking findings from earlier stations, not on tone findings; Asimov's findings carry no tier and `protocols/finding-disposition.md` does not govern them.

## Friedman-Lovelace Iteration Loop

**Friedman initial review**: A single full pass writing the canonical `friedman_<N>.md` is the default. For full-surface changes, `rules/scope-proportional-pipeline.md` calls for two instances with split lenses writing suffixed reports (`friedman_<N>a.md` and `friedman_<N>b.md`), which Winterbotham consolidates into the canonical `friedman_<N>.md`, deduplicating and applying the tier order in `protocols/finding-disposition.md` when both flag the same finding.

When Friedman returns a Blocking finding, the pipeline enters an iteration loop. Friday manages each cycle:

**Step 1: Friday compresses Friedman's Blocking findings for Lovelace.**

Friday reads Friedman's full report and extracts the Blocking findings as terse items: what is broken and where. No reasoning chain, no suggested fixes, no Friedman's analysis of why. Just: this location, this problem. Comment and Noted findings are not compressed into the loop dispatch; Lovelace picks them up from the report in the feature directory.

This is compression without interpretation. Friday removes context (Friedman's reasoning) but does not add context (orchestrator opinions on how to fix). Subtraction is safe; addition is anchoring.

Lovelace reads the code at the cited locations, sees the problem herself, and derives the fix. If she cannot see why something is broken from looking at the code, that signals either the finding is wrong or the issue requires a design-level conversation that should escalate rather than iterate.

**Step 2: Lovelace addresses the Blocking findings and commits.**

Lovelace implements a fix for every Blocking finding, and addresses the report's Comment findings as she judges appropriate. She commits the changes so the diff history is traceable. She reports back what was changed and flags anything she could not address or interpreted ambiguously.

**Step 3: Friday dispatches Friedman for re-review.**

Re-review is a full pass, not scoped to the prior Blocking findings. Friedman receives the feature slug and worktree path (same as initial review). His report from the prior iteration is in the feature directory for reference. Re-reviews are always a single instance, even when the initial review ran dual.

**Step 4: Friedman reports.**

- **No Blocking findings** — loop exits; advance to Curie. Outstanding Comment and Noted findings do not hold the loop open.
- **Prior Blocking findings unresolved** — flag specifically which ones remain; loop continues
- **New Blocking findings introduced by the revision** — include with findings; loop continues

**Loop cap: 3 iterations.** If Friedman still has a Blocking finding after 3 Lovelace revision cycles, Friday halts and surfaces to the user. Do not continue looping silently — escalate with the full Blocking list and iteration history.

## Station Responsibilities

Each station receives the feature slug and work location from Friday, orients from the feature directory and codebase per its own definition, does its work, and writes its artifact to the feature directory. Friday sequences stations and makes go/no-go decisions; agents own their own orientation and execution.

## Worktree Lifecycle

When code-producing agents use worktree isolation, the deployment's worktree rule (`rules/local/no-worktree-isolation.md`) owns pre-dispatch setup, base verification, and post-dispatch transport. Friday follows that rule across the full pipeline.

The same worktree persists for the full Lovelace/Friedman loop, through Curie, and through Asimov. Each station receives the worktree path so it reads and writes the same files. Read-only agents (Babbage, Friedman, Oppenheimer) may read from the worktree path when provided; they do not require isolation.

Asimov writes inside the worktree. His edits land on the WIP branch as a working commit, alongside Lovelace's. They are not pushed separately. The squash step that follows folds Asimov's edits into the single commit, the same way it folds Lovelace's iteration commits.

After Asimov passes, Friday squashes the pipeline's working commits into a single commit on the target branch. The squash commit body is a standalone description of what the code does, at the altitude a reader of `git log -1` needs: no agent names, no pipeline references, no revision history, and no judgment content (risks, open questions, conditionals, or decision rationale). Non-diff judgment routes to other channels; see the Bridge section. Transport of that squashed commit (worktree removal, branch positioning) follows the worktree rule.

## Single Commit Output

The mob pipeline produces a single commit on the target branch. Lovelace, iterations, and Asimov may create multiple working commits during the pipeline, but Friday squashes them during worktree teardown (see above) before pushing. The iteration history (Friedman findings, revision cycles, tone-scrub edits) is internal to the pipeline and does not appear in git.

The commit reads as the user's own work.

## Bridge to the Next Environment

The mob does not author a handoff document. The work leaves the mob through three channels, each carrying a distinct kind of content, and whoever runs the next step (a different agent, a different environment, or the user directly) reads the branch, not a prose summary:

- **The diff** — what changed.
- **The squash commit body** — a standalone description of what the branch does.
- **The PR description** — the paste-ready artifact (see PR Description below), and the home for actionable follow-ups.

**The commit body describes; it does not judge.** Its whole job is to tell a reader of `git log -1` what the branch does, at that altitude. It carries no risks, no open questions, no conditionals ("if X lands first, renumber"), and no decision rationale ("the owner should confirm this precision"). If there is nothing to describe beyond the subject line, the body is the subject line alone; do not manufacture content.

Good — describes what the branch does:

```
Add order_valuations table to the billing database

Adds a migration creating order_valuations in the billing database, one row per order
keyed on the order id. Columns: order_id (bigint primary key), unit_value
(numeric(30, 15)), and valued_at (timestamp). Creates the schema only and writes no rows.
```

Bad — talks about ifs, maybes, and musings the reader did not ask for:

```
Add order_valuations table to the billing database

unit_value uses numeric(30, 15) to preserve rate precision; the billing owner should
confirm this against the recon math, and numeric(30, 4) is the alternative. Migration
apply not run locally (no local billing database). If another migration with this number
lands first, renumber before merge. The model and accessors are intentionally out of scope.
```

**The non-diff judgment still has a home, just not the commit body:**

- **Actionable follow-ups** — something a reader should do (confirm a value with an owner, revisit a tradeoff) — go in the **PR description**.
- **Risks and open questions** — edge cases tests do not cover, assumptions, validation gaps, unresolved tone findings — are **surfaced to the user in-session** when the pipeline completes. Curie's Known Risks / Open Questions and Friedman's Review Notes feed this surfacing.

Standard verification (format, lint, type, test) is not enumerated in the commit body or transported anywhere. The next environment re-runs it from its own suite.

If a deployment-specific bridge protocol exists (e.g., `protocols/local/coder-handoff`), follow it for the PR description path, skipped-check handling, and any environment-specific setup the user must run. Friday does not write a `handoff_<N>.md` file.

## PR Description

The PR description goes through two passes.

**First pass: Friday drafts.** After Curie returns, Friday writes a draft PR description to `scratch/output/_<feature-slug>/pr-description.md`. This is synthesized from the pipeline's accumulated context: design rationale, implementation approach, validation results, and any actionable follow-ups a reviewer should act on (e.g. an owner-review item). It reads as the user's own work, with no agent names and no pipeline references.

**Second pass: Asimov scrubs.** Asimov reads `pr-description.md` alongside the diff. He applies the same catalog he applies to code prose, with the strictness appropriate to externally-visible content. The PR description is paste-ready output, not a session artifact, so the bar is higher than for code comments. Asimov edits the file in place; the version in the feature directory after Asimov returns is the version the user copies into GitHub.

The format follows the target repo's PR conventions. At minimum:

```markdown
## Summary
<What this PR does and why, 2-4 sentences.>

## Changes
- <Grouped by concern, not by file. One line per logical change.>
```

If the target repo has a PR template, follow it instead of the minimum format above.

After presenting the PR description path and the git-setup commands, immediately ask the user whether to push the branch to the remote. This is a gated action — do not push without explicit approval — but the question should always be asked so the user does not have to prompt for it. If a deployment-specific handoff protocol specifies a transport mechanism (e.g., WIP branches), use that instead of pushing directly to the feature branch.

## Related Protocols

- `finding-disposition` — the authority for the tiers every review station assigns, the gate that assigns them, and the report sectioning. Blocking is this pipeline's go/no-go binary
- `pipeline-narrative` — governs the accumulating output document Friday maintains throughout the pipeline
- `validation-plan` — governs the format of Curie's plan
- `protocols/asimov-catalog.md`, the pattern catalog Asimov consumes during the tone scrub
- Deployment-specific bridge protocols (e.g., `protocols/local/coder-handoff`) — govern the PR description path, skipped-check handling, and the environment setup commands the user runs
