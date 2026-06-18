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

All six stations run on every pipeline. No station is conditional — skipping any station is not a valid shortcut. Review without design produces drift, validation without review produces unreviewed code, implementation without design critique risks structural flaws that are expensive to fix after the fact, and shipping without a tone scrub leaves the AI fingerprint that has cost real reviewer trust on prior PRs.

## Hub-and-Spoke Model

Babbage, Oppenheimer, Lovelace, Friedman, Curie, and Asimov do not communicate directly. All information flows through Friday:

```
Friday → Babbage (task description, feature slug)
Babbage → Friday
Friday → Oppenheimer ×2 in parallel (feature slug, worktree path; suffixed output: _Na.md, _Nb.md)
Friday → Winterbotham (consolidate oppenheimer_Na.md + oppenheimer_Nb.md → oppenheimer_N.md)
  [If blockers: Friday → Babbage with blocking findings; Babbage revises once]
  [Friday → Oppenheimer (full re-review of revised design)]
  [If still blockers: escalate to user; do not loop further]
  [If non-blocker findings only: Babbage addresses; no re-review needed]
Oppenheimer → Friday
Friday → Lovelace (feature slug, worktree path)
Lovelace → Friday
Friday → Friedman ×2 in parallel (feature slug, worktree path; suffixed output: _Na.md, _Nb.md)
Friday → Winterbotham (consolidate friedman_Na.md + friedman_Nb.md → friedman_N.md)
Friday → Lovelace (terse blockers: what and where) — if blockers
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

After each station completes, Friday decides: advance, loop back, or escalate. The general principle: clean output advances, blockers loop back to the originating station, persistent blockers escalate to the user.

Specific guardrails:

- **Oppenheimer initial review**: Two Oppenheimer instances run in parallel on the initial design. Each performs a full independent pass and writes a suffixed report (`oppenheimer_<N>a.md` and `oppenheimer_<N>b.md`). Winterbotham consolidates both into the canonical `oppenheimer_<N>.md`, deduplicating and preserving the highest severity when both flag the same issue. This catches findings that a single non-deterministic pass might miss.
- **Oppenheimer revision re-review**: Babbage gets one revision attempt. Oppenheimer performs a full re-review of the revised design (not scoped to prior blockers). Non-blocker findings (warnings, informational) go back to Babbage without Oppenheimer re-review.
- **Design-level issues surfaced during review or validation**: Escalate to the user rather than routing between Lovelace and Friedman. Implementation cannot fix a design problem.
- **Coverage gaps**: Do not automatically block. Friday decides whether to route back or proceed.
- **Loop cap**: 3 Friedman-Lovelace iterations (see iteration loop below). 1 Babbage-Oppenheimer revision. If blockers persist after the cap, escalate.
- **Asimov is terminal**: Asimov runs once. Findings he resolves are absorbed into the squash commit. Findings he cannot resolve mechanically (genuine technical phrasing the catalog cannot reach, ambiguous identifier renames, anything that would change behavior) are recorded in `asimov_<N>.md` and surfaced to the user. They do not loop back to Lovelace and do not re-enter the Friedman queue. The pipeline halts on substantive blockers from earlier stations, not on tone findings.

## Friedman-Lovelace Iteration Loop

**Friedman initial review**: Two Friedman instances run in parallel on the initial implementation. Each performs a full independent pass and writes a suffixed report (`friedman_<N>a.md` and `friedman_<N>b.md`). Winterbotham consolidates both into the canonical `friedman_<N>.md`, deduplicating and preserving the highest severity when both flag the same issue.

When Friedman returns blockers, the pipeline enters an iteration loop. Friday manages each cycle:

**Step 1: Friday compresses Friedman's blockers for Lovelace.**

Friday reads Friedman's full report and extracts the blockers as terse findings: what is broken and where. No reasoning chain, no suggested fixes, no Friedman's analysis of why. Just: this location, this problem.

This is compression without interpretation. Friday removes context (Friedman's reasoning) but does not add context (orchestrator opinions on how to fix). Subtraction is safe; addition is anchoring.

Lovelace reads the code at the cited locations, sees the problem herself, and derives the fix. If she cannot see why something is broken from looking at the code, that signals either the finding is wrong or the issue requires a design-level conversation that should escalate rather than iterate.

**Step 2: Lovelace addresses blockers and commits.**

Lovelace implements fixes for every blocker. She commits the changes so the diff history is traceable. She reports back what was changed and flags anything she could not address or interpreted ambiguously.

**Step 3: Friday dispatches Friedman for re-review.**

Re-review is a full pass, not scoped to prior blockers. Friedman receives the feature slug and worktree path (same as initial review). His report from the prior iteration is in the feature directory for reference. Iteration re-reviews are a single instance (not dual), since the scope of changes is smaller.

**Step 4: Friedman reports.**

- **No blockers** — loop exits; advance to Curie
- **Prior blockers unresolved** — flag specifically which ones remain; loop continues
- **New blockers introduced by the revision** — include with findings; loop continues

**Loop cap: 3 iterations.** If Friedman still has blockers after 3 Lovelace revision cycles, Friday halts and surfaces to the user. Do not continue looping silently — escalate with the full blocker list and iteration history.

## Station Responsibilities

Each station receives the feature slug and work location from Friday, orients from the feature directory and codebase per its own definition, does its work, and writes its artifact to the feature directory. Friday sequences stations and makes go/no-go decisions; agents own their own orientation and execution.

## Worktree Lifecycle

When code-producing agents use worktree isolation, the deployment's worktree rule (`rules/local/no-worktree-isolation.md`) owns pre-dispatch setup, base verification, and post-dispatch transport. Friday follows that rule across the full pipeline.

The same worktree persists for the full Lovelace/Friedman loop, through Curie, and through Asimov. Each station receives the worktree path so it reads and writes the same files. Read-only agents (Babbage, Friedman, Oppenheimer) may read from the worktree path when provided; they do not require isolation.

Asimov writes inside the worktree. His edits land on the WIP branch as a working commit, alongside Lovelace's. They are not pushed separately. The squash step that follows folds Asimov's edits into the single commit, the same way it folds Lovelace's iteration commits.

After Asimov passes, Friday squashes the pipeline's working commits into a single commit on the target branch. The squash commit message reflects what the code does, with no agent names, no pipeline references, and no revision history. Its body carries the commit-body kernel (the non-diff-visible judgment that reaches the next environment; see the Bridge section). Transport of that squashed commit (worktree removal, branch positioning) follows the worktree rule.

## Single Commit Output

The mob pipeline produces a single commit on the target branch. Lovelace, iterations, and Asimov may create multiple working commits during the pipeline, but Friday squashes them during worktree teardown (see above) before pushing. The iteration history (Friedman findings, revision cycles, tone-scrub edits) is internal to the pipeline and does not appear in git.

The commit reads as the user's own work.

## Bridge to the Next Environment

The mob does not author a handoff document. The work leaves the mob through three channels: the diff (what changed), the squash commit body (the non-diff-visible judgment), and the PR description (the paste-ready artifact). Whoever runs the next step (a different agent, a different environment, or the user directly) reads the branch, not a prose summary.

The squash commit body carries a **commit-body kernel**: the judgment the diff cannot show. Friday composes it at squash time from two sources:

- **Curie's Known Risks / Open Questions** — edge cases not covered by tests, external dependencies, assumptions, validation gaps, including any unresolved tone findings from Asimov.
- **Friedman's Review Notes** — non-blocking observations and tradeoffs worth a later look.

(A deployment-specific bridge protocol may add a third source, e.g., skipped local checks in `protocols/local/coder-handoff`.)

The kernel is composed before the squash and scrubbed by Asimov per `rules/user-authorship.md`: no agent names, no pipeline vocabulary. It reads as the author's own notes on the commit. The squash then folds it into the single commit body, where the next reader picks it up with `git log -1`. If there are no risks and no notable observations, the commit body is just the standard description of what the code does; do not manufacture caveats.

Standard verification (format, lint, type, test) is not enumerated here or transported anywhere. The next environment re-runs it from its own suite. Only the non-diff-visible judgment needs a channel, and that channel is the commit body.

If a deployment-specific bridge protocol exists (e.g., `protocols/local/coder-handoff`), follow it for kernel composition, the PR description path, and any environment-specific setup the user must run. Friday no longer writes a `handoff_<N>.md` file.

## PR Description

The PR description goes through two passes.

**First pass: Friday drafts.** After Curie returns, Friday writes a draft PR description to `scratch/output/_<feature-slug>/pr-description.md`. This is synthesized from the pipeline's accumulated context: design rationale, implementation approach, validation results. It reads as the user's own work, with no agent names and no pipeline references.

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

- `pipeline-narrative` — governs the accumulating output document Friday maintains throughout the pipeline
- `validation-plan` — governs the format of Curie's plan
- `protocols/asimov-catalog.md`, the pattern catalog Asimov consumes during the tone scrub
- Deployment-specific bridge protocols (e.g., `protocols/local/coder-handoff`) — govern the commit-body kernel composition, the PR description path, and the environment setup commands the user runs
