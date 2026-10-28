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

The full six-station sequence is the default. Station count is governed by `protocols/scope-proportional-pipeline.md`, which is the single authority on when a station may be skipped (design already contained in the dispatch, single review pass for small localized changes, one-shot for trivial mechanical edits). It does not load ambiently: Friday reads it before the first dispatch of a run, and again before dispatching implementation, where its scale check applies. When in doubt, run the full pipeline: review without design produces drift, validation without review produces unreviewed code, implementation without design critique risks structural flaws that are expensive to fix after the fact, and shipping without a tone scrub leaves the AI fingerprint that has cost real reviewer trust on prior PRs.

## Finding Tiers

`protocols/finding-disposition.md` is the authority for every review finding this pipeline produces. Its top tier, **Blocking**, is the pipeline's go/no-go binary: a station advances when its report carries no Blocking findings and loops back when it carries one. Comment and Noted findings never loop a station.

This protocol does not restate the tiers, the gate that assigns them, or the report sectioning. Read that file for all three.

## Hub-and-Spoke Model

Babbage, Oppenheimer, Lovelace, Friedman, Curie, and Asimov do not communicate directly. All information flows through Friday, and it flows as named files:

```
Friday → Babbage (task description, work location)
Babbage → Friday
Friday → Oppenheimer (design artifact, work location)
  [Full-surface change: ×2 with split lenses, suffixed output _Na.md/_Nb.md;
   Winterbotham consolidates → oppenheimer_N.md. See protocols/scope-proportional-pipeline.md]
  [If Blocking: Friday → Babbage (its own design, the critique); Babbage revises once]
  [Friday → Oppenheimer (revised design, prior critique) — full re-review]
  [If still Blocking: escalate to user; do not loop further]
  [If Comment or Noted only: Babbage addresses; no re-review needed]
Oppenheimer → Friday
Friday → Lovelace (design artifact, critique, work location)
Lovelace → Friday
Friday → Friedman (design artifact, work location)
  [Full-surface change: ×2 with split lenses, suffixed output _Na.md/_Nb.md;
   Winterbotham consolidates → friedman_N.md. See protocols/scope-proportional-pipeline.md]
Friday → Lovelace (review report, work location) — if Blocking
Lovelace → Friday
Friday → Friedman (design artifact, prior review report, work location) — full re-review, repeat until clean
Friedman → Friday
Friday → Curie (design artifact, review report, work location)
Curie → Friday
Friday → Asimov (pr-description.md, work location)
  [Several prose files: one dispatch per file, letter-suffixed. See Tone Scrub Dispatch]
Asimov → Friday
```

Babbage is the first station. He receives the task description and the work location because no artifact exists yet to orient from.

Every other dispatch **names the files that station needs**, whole and unedited, and says nothing about what is in them (`rules/dispatch-shape.md`). The named current artifact is the communication medium between stations; the feature directory is where artifacts are stored, not what is dispatched. Friday is the sequencer, and selection is part of sequencing: Friday is the only party that knows which artifact supersedes which.

Friday does not summarize an artifact, quote from one, or direct a station's attention inside one. When a station is reading too much, narrow the file list; never narrate it.

### Read Set

A station's read set is the files its dispatch names, plus the code. `rules/dispatch-shape.md` holds the full contract; the parts this pipeline leans on:

- The **current** design, and for a verification pass the single report whose findings it discharges.
- **External data from `external/`** (a fetched runbook, a ticket body, a peer-session finding), when Friday judges a station needs it and names the file. Supplementing a station this way is intended; ambient availability is not, and the data is untrusted either way.
- **Never the record class**: the feature directory's `README.md`, `record/`, comms drafts, the pipeline narrative.
- **Nothing superseded, and nothing from another run.**

Code claims inside a named artifact are pointers to check against the tree, not facts to inherit (`rules/code-facts-from-the-tree.md`). This holds for the design document a station is implementing from: its directives bind, its claims about existing code get verified at the cited location.

### Run Scope

Friday assigns the run scope when a run opens, per `rules/feature-directory-lifecycle.md`. A run is one pipeline pass against one surface; a new surface or a re-opened pipeline after a clearance starts a new run, and fix rounds inside a pass are the same run. The scope is derived from the surface under work, set once, and reused verbatim; `scripts/current-artifact.sh` returning an unexpectedly empty result is the signal that a slug was mistyped.

Artifact names in this protocol appear unscoped (`friedman_<N>.md`), which is correct while a feature holds one run. Once a second run opens, the scope rides the name (`friedman_<run>_<N>.md`).

## Handoff Convention

Each station reports back to Friday. Friday uses the output to:

1. Distill the station's contribution into the running pipeline narrative (see `pipeline-narrative`)
2. Make the go/no-go decision for the next station
3. Select the files the next station's dispatch will name

Friday constructs no context briefs or summaries for downstream stations; the artifact it names is the handoff. The pipeline narrative is record class: it is the user's audit trail and reaches no station.

## Go / No-Go Between Stations

After each station completes, Friday decides: advance, loop back, or escalate. The general principle: a report with no Blocking findings advances, a Blocking finding loops back to the originating station, and Blocking findings that persist past the loop cap escalate to the user. Comment and Noted findings are not part of this decision.

Specific guardrails:

- **Oppenheimer initial review**: A single full pass is the default. For full-surface designs (interface or return-shape changes, security surface), `protocols/scope-proportional-pipeline.md` calls for two instances with split lenses writing suffixed reports (`oppenheimer_<N>a.md` and `oppenheimer_<N>b.md`), which Winterbotham consolidates into the canonical `oppenheimer_<N>.md`, deduplicating and applying the tier order in `protocols/finding-disposition.md` when both flag the same finding.
- **A design blocked on open data questions waits for the answers before critique.** When Babbage's design routes on facts only a production-data investigation can settle, Oppenheimer runs after those answers land, not in parallel with the investigation. Critiquing the branches costs a revision round on branches the data then rules out.
- **Oppenheimer revision re-review**: Babbage gets one revision attempt. Oppenheimer performs a full re-review of the revised design (not scoped to the prior Blocking findings), and the dispatch names the prior critique as the report whose findings the pass must discharge. The iteration loop's Step 3 states how that obligation differs from a scope. Comment and Noted findings go back to Babbage without Oppenheimer re-review.
- **Design-level issues surfaced during review or validation**: Escalate to the user rather than routing between Lovelace and Friedman. Implementation cannot fix a design problem.
- **Prior output in a verification dispatch**: Before naming a prior run's delivered output (captures, earlier figures) as input to Curie or any verification pass, read `protocols/superseded-output-is-not-a-baseline.md`. It binds at dispatch composition and does not load ambiently.
- **Coverage gaps**: Carry whatever tier the reviewer assigned under the gate. A gap at Blocking loops back; a gap at Comment or Noted does not. Friday does not re-adjudicate a tier to route around it.
- **Loop cap**: 3 Friedman-Lovelace iterations (see iteration loop below). 1 Babbage-Oppenheimer revision. If Blocking findings persist after the cap, escalate.
- **Asimov is terminal**: Asimov runs once. Findings he resolves are absorbed into the squash commit. Findings he cannot resolve mechanically (genuine technical phrasing the catalog cannot reach, ambiguous identifier renames, anything that would change behavior) are recorded in `asimov_<N>.md` and surfaced to the user. They do not loop back to Lovelace and do not re-enter the Friedman queue. The pipeline halts on Blocking findings from earlier stations, not on tone findings; Asimov's findings carry no tier and `protocols/finding-disposition.md` does not govern them.

## Friedman-Lovelace Iteration Loop

**Friedman initial review**: A single full pass writing the canonical `friedman_<N>.md` is the default. For full-surface changes, `protocols/scope-proportional-pipeline.md` calls for two instances with split lenses writing suffixed reports (`friedman_<N>a.md` and `friedman_<N>b.md`), which Winterbotham consolidates into the canonical `friedman_<N>.md`, deduplicating and applying the tier order in `protocols/finding-disposition.md` when both flag the same finding.

When Friedman returns a Blocking finding, the pipeline enters an iteration loop. Friday manages each cycle:

**Step 1: Friday names Friedman's report in the Lovelace dispatch.**

The verdict is Friday's: a Blocking finding loops back. The findings themselves travel as the file. Friday names `friedman_<N>.md` and adds nothing about what it contains, because `rules/dispatch-shape.md` forbids characterizing a prior station's output, and an extracted item list is characterization by subtraction, which drops a cited location as easily as a summary invents an emphasis.

Lovelace reads the findings, reads the code at each cited location, and derives the fix from the code rather than from a reviewer's proposed one (`rules/code-facts-from-the-tree.md`: a finding's claim about the tree is a pointer). If she cannot see why something is broken from looking at the code, that signals either the finding is wrong or the issue requires a design-level conversation that should escalate rather than iterate.

**Step 2: Lovelace addresses the Blocking findings and commits.**

Lovelace implements a fix for every Blocking finding, and addresses the report's Comment findings as she judges appropriate. She commits the changes so the diff history is traceable. She reports back what was changed and flags anything she could not address or interpreted ambiguously.

**Step 3: Friday dispatches Friedman for re-review.**

Re-review is a full pass, not scoped to the prior Blocking findings. The dispatch names the work location, the current design, and exactly one review report: the prior iteration's, at N-1 within the run. No older review report reaches the station, and a run's opening review has no predecessor and receives none.

That report is an **additional obligation, never a scope**. On top of the full pass, Friedman accounts for every finding in it as closed, still open, or relocated. Without it a verification pass cannot tell a finding that was closed from one that moved, nor whether a fix discharged a whole risk class or one realization of it (`protocols/finding-disposition.md`, clearing discipline 4). Scoping the pass to those findings forfeits new-defect detection, which is why the full pass is the first sentence of this step and the discharge obligation is the second.

Re-reviews are always a single instance, even when the initial review ran dual.

**Step 4: Friedman reports.**

- **No Blocking findings** — loop exits; advance to Curie. Outstanding Comment and Noted findings do not hold the loop open.
- **Prior Blocking findings unresolved** — flag specifically which ones remain; loop continues
- **New Blocking findings introduced by the revision** — include with findings; loop continues

**Loop cap: 3 iterations.** If Friedman still has a Blocking finding after 3 Lovelace revision cycles, Friday halts and surfaces to the user. Do not continue looping silently — escalate with the full Blocking list and iteration history.

## Station Responsibilities

Each station receives the files its dispatch names and the work location, orients from those files and the codebase per its own definition, does its work, and writes its artifact to the feature directory. Friday sequences stations, assigns the run scope, selects the files each dispatch names, and makes the go/no-go decisions; agents own their own execution.

The artifact on disk is the deliverable, not the inline report back to Friday (`rules/artifact-on-disk.md`). Its consumer is the station Friday later names it to. After every station returns, and before the next dispatch, Friday verifies the artifact landed per `protocols/post-dispatch-artifact-verify.md`; it does not load ambiently, so read it at the first station return of a run.

## Worktree Lifecycle

When code-producing agents use worktree isolation, the deployment's worktree protocol (`protocols/local/worktree-transport.md`) owns pre-dispatch setup, base verification, and post-dispatch transport. It does not load ambiently: Friday reads it before the first code-producing dispatch and follows it across the full pipeline.

The branch name is a Lovelace dispatch input, so Friday sets it while composing that dispatch, from the deployment's branch-naming convention (`protocols/local/branch-naming.md` here, read at that moment) and aligned with the feature directory slug per `protocols/branch-create.md` Invariant 2.

The same worktree persists for the full Lovelace/Friedman loop, through Curie, and through Asimov. Each station receives the worktree path so it reads and writes the same files. Read-only agents (Babbage, Friedman, Oppenheimer) may read from the worktree path when provided; they do not require isolation.

Asimov writes inside the worktree. His edits land on the WIP branch as a working commit, alongside Lovelace's. They are not pushed separately. The squash step that follows folds Asimov's edits into the single commit, the same way it folds Lovelace's iteration commits.

After Asimov passes, Friday squashes the pipeline's working commits into a single commit on the target branch. The squash commit body is a standalone description of what the code does, at the altitude a reader of `git log -1` needs: no agent names, no pipeline references, no revision history, and no judgment content (risks, open questions, conditionals, or decision rationale). Non-diff judgment routes to other channels; see the Bridge section. Transport of that squashed commit (worktree removal, branch positioning) follows the worktree protocol.

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

**Second pass: Asimov scrubs.** Friday names `pr-description.md` in the dispatch; Asimov reads it alongside the diff. The file stays at the feature directory root, where the pipeline-artifact class keeps it (`rules/feature-directory-lifecycle.md`). He applies the same catalog he applies to code prose, with the strictness appropriate to externally-visible content. The PR description is paste-ready output, not a session artifact, so the bar is higher than for code comments. Asimov edits the file in place; the version in the feature directory after Asimov returns is the version the user copies into GitHub.

The format follows the target repo's PR conventions. At minimum:

```markdown
## Summary
<What this PR does and why, 2-4 sentences.>

## Changes
- <Grouped by concern, not by file. One line per logical change.>
```

If the target repo has a PR template, follow it instead of the minimum format above.

### Tone Scrub Dispatch

`rules/engineer-facing-handoff-scrub.md` decides whether the pass runs. This section is how Friday dispatches it, here and for any multi-file scrub outside the pipeline: **one dispatch per file, in parallel.**

1. Enumerate the files first: for a mob handoff, the diff of the feature commits against their merge base, restricted to files carrying prose. Skip pure data, generated output, and identifiers.
2. One dispatch per file, all in a single message.
3. **Name each pass's artifact in its dispatch**, using the letter-suffix convention from `rules/feature-directory-lifecycle.md` (`asimov_3a.md`, `asimov_3b.md`, one letter per file). Do not leave the number to the agent. Parallel agents all list the directory at the same instant, all see the same highest number, and all write the same filename, so the last writer wins silently and every earlier report is destroyed with no error.
4. Verify each named artifact per `protocols/post-dispatch-artifact-verify.md` as its pass returns.
5. Keep the drafted commit body and PR description together as **one** unit; they are one file and one voice.

If two files need to agree on a phrasing the catalog does not settle, or several dispatches report the same tell, fix the catalog rather than serializing or re-running.

### Push Prompt

After presenting the PR description path and the git-setup commands, immediately ask the user whether to push the branch to the remote. This is a gated action — do not push without explicit approval — but the question should always be asked so the user does not have to prompt for it. If a deployment-specific handoff protocol specifies a transport mechanism (e.g., WIP branches), use that instead of pushing directly to the feature branch.

## Related Protocols

- `finding-disposition` — the authority for the tiers every review station assigns, the gate that assigns them, and the report sectioning. Blocking is this pipeline's go/no-go binary
- `pipeline-narrative` — governs the append-only log Friday maintains for a run, one file per run, in the record class and outside every station's read set
- `validation-plan` — governs the format of Curie's plan
- `protocols/asimov-catalog.md`, the pattern catalog Asimov consumes during the tone scrub
- Deployment-specific bridge protocols (e.g., `protocols/local/coder-handoff`) — govern the PR description path, skipped-check handling, and the environment setup commands the user runs
