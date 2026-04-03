# Mob Pipeline Protocol

Coordinate Babbage, Oppenheimer, Lovelace, Friedman, and Curie to produce code changes against a software repo. Friday orchestrates — the agents do not communicate directly.

## Usage

Invoke when a coding task needs the full mob: design a technical approach, implement it, review the implementation, and validate it works. Each station completes before the next begins. Friday manages every handoff.

## Station Sequence

Pipelines follow this fixed order:

1. **Babbage** (design) — produces a technical approach: scope, interface contracts, affected files, test strategy
2. **Oppenheimer** (design critique) — stress-tests the design for structural flaws before implementation begins
3. **Lovelace** (implementation) — produces code matching Babbage's design
4. **Friedman** (review) — evaluates Lovelace's implementation for correctness, security, and style
5. **Curie** (validation) — verifies the implementation works as intended

All five stations run on every pipeline. No station is conditional — skipping any station is not a valid shortcut. Review without design produces drift, validation without review produces unreviewed code, and implementation without design critique risks structural flaws that are expensive to fix after the fact.

## Hub-and-Spoke Model

Babbage, Oppenheimer, Lovelace, Friedman, and Curie do not communicate directly. All information flows through Friday:

```
Friday → Babbage
Babbage → Friday
Friday → Oppenheimer (with Babbage's design document ONLY — no Babbage conversation, reasoning, or dispatch context)
  [If blockers: Friday → Babbage with blocking findings; Babbage revises once]
  [Friday verifies revision against blocking findings — targeted check, not full design review]
  [If not addressed: escalate to user; do not loop]
Oppenheimer → Friday
Friday → Lovelace (with design + Oppenheimer report)
Lovelace → Friday
Friday → Friedman (with design + implementation context)
Friedman → Friday
Friday → Lovelace (with Friedman's findings) — if blockers
Lovelace → Friday
Friday → Friedman (re-review) — repeat until clean
Friedman → Friday
Friday → Curie (with full prior context)
Curie → Friday
```

The Oppenheimer dispatch is stateless by design. He receives only the design document and codebase access — no Babbage conversation history, no dispatch context, no reasoning chain. This is not a constraint to work around; a review anchored to the designer's reasoning is not an independent review.

Friday provides each station with a curated summary of prior output — not raw transcripts — and decides whether to advance, loop back, or halt after each station completes.

## Handoff Convention

Each station reports back to Friday and signals what matters most from its output — the key decisions, significant findings, or blockers. Friday uses those signals to:

1. Distill the station's contribution into the running pipeline narrative (see `pipeline-narrative`)
2. Construct the context brief for the next station

The context brief for any station contains:
- The current session date (`YYYY-MM-DD`) — required for any date-parameterized protocol (e.g., output paths). Agents must not infer the date from input paths.
- The original task description
- A summary of prior stations' decisions — not raw transcripts
- Any open questions or constraints surfaced so far

## Go / No-Go Between Stations

After each station completes, Friday makes a go/no-go decision before advancing:

- **Babbage → Oppenheimer**: Always route to Oppenheimer. If the design is incomplete or contradictory, loop back to Babbage first.
- **Oppenheimer → Lovelace**: If no blocking findings, pass the design and Oppenheimer report to Lovelace. If blockers present, return to Babbage with the specific blocking findings. Babbage revises once. Friday reviews the revision against the blocking findings — this is a targeted check, not a full design review. If addressed, advance to Lovelace with the revised design and the original Oppenheimer report. If not addressed, escalate to the user. No second Oppenheimer pass — do not loop.
- **Lovelace → Friedman**: If implementation is visibly incomplete or substantially deviates from design without explanation, loop back before review.
- **Friedman → Lovelace**: If Friedman has blockers, route back to Lovelace. Do not pass to Curie until Friedman approves clean. If Friedman surfaces design-level issues (not implementation errors), consider whether Babbage re-engagement is warranted before re-routing to Lovelace.
- **Curie → Done**: If validation reveals test failures, route back to Lovelace. If validation reveals coverage gaps, Friday decides whether to route back or proceed — coverage gaps do not automatically block. If validation reveals design-level failures, the issue may require Babbage and Lovelace re-engagement; escalate to the user rather than looping silently.

A loop always restarts from the station where the problem originated, not from the beginning.

## Friedman–Lovelace Iteration Loop

When Friedman returns blockers, the pipeline enters an iteration loop. Friday manages each cycle:

**Step 1: Friday briefs Lovelace for re-engagement.**

The brief contains:
- Friedman's full findings (blockers only — suggestions and observations are not re-engagement triggers)
- The original task description and Babbage's design
- A note on which iteration this is (e.g., "Friedman revision 1")

Lovelace does not receive Friedman's full review report verbatim. Friday distills: here are the specific issues, here is what needs to change.

**Step 2: Lovelace addresses blockers and commits.**

Lovelace implements fixes for every blocker in the brief. She commits the changes — each revision cycle produces a commit so the diff history is traceable. She reports back what was changed and flags anything she could not address or interpreted ambiguously.

**Step 3: Friday briefs Friedman for re-review.**

The brief contains:
- Lovelace's summary of changes made
- The original blocker list, so Friedman can verify each was addressed
- A note on which iteration this is

Friedman does a targeted re-review: he verifies every prior blocker is resolved and runs all lenses for any new code introduced in the revision. He is not re-reviewing unchanged code.

**Step 4: Friedman reports.**

- **No blockers** — loop exits; advance to Curie
- **Prior blockers unresolved** — flag specifically which ones remain; loop continues
- **New blockers introduced by the revision** — include with findings; loop continues

**Loop cap: 3 iterations.** If Friedman still has blockers after 3 Lovelace revision cycles, Friday halts and surfaces to the user. Do not continue looping silently — escalate with the full blocker list and iteration history.

## Station Responsibilities

Each station receives a context brief from Friday, does its work, and reports back. Stations signal what matters most from their output — decisions, findings, blockers — so Friday can distill the narrative and brief the next station.

## Worktree Lifecycle

When code-producing agents use worktree isolation (see `rules/local/no-worktree-isolation.md`), Friday manages the worktree across the full pipeline:

**Setup (post-Babbage/Oppenheimer, pre-Lovelace dispatch):**

1. Run the branch check (`scripts/local/check-branch-pr.sh`) to determine the target branch name (feature branch or WIP branch if a PR exists)
2. Delete any stale WIP worktree and branches per `rules/local/reset-to-remote.md`
3. Fetch all refs: `git fetch origin`
4. Create the worktree from the remote ref: `git worktree add -b <target-branch> <worktree-path> origin/<base-branch>`
5. Pass the worktree path to Lovelace's dispatch as the working directory

**Shared across pipeline stations:**

The same worktree persists for the full Lovelace/Friedman loop and through Curie. Each station receives the worktree path so it reads and writes the same files. Read-only agents (Babbage, Friedman, Oppenheimer) may read from the worktree path when provided — they do not require isolation.

**Teardown (post-Curie, pre-handoff):**

After Curie passes validation and before writing the handoff document:

1. Inside the worktree, squash all commits into one: `git reset origin/<base-branch>` followed by a single `git commit`
2. From the main tree, remove the worktree: `git worktree remove <worktree-path>`
3. The WIP branch now exists as a local branch with a single squashed commit — ready to push

Friday writes the squash commit message at step 1. It reflects what the code does — no agent names, no pipeline references, no revision history.

## Single Commit Output

The mob pipeline produces a single commit on the target branch. Lovelace and subsequent iterations may create multiple working commits during the pipeline, but Friday squashes them during worktree teardown (see above) before pushing. The iteration history (Friedman findings, revision cycles) is internal to the pipeline and does not appear in git.

The commit reads as the user's own work.

## Handoff

After Curie passes validation, Friday produces a handoff document. The pipeline is not complete until the handoff exists. The handoff is how the work leaves the mob and reaches whoever runs the next step — a different agent, a different environment, or the user directly.

The handoff document is self-contained: it carries everything the recipient needs without access to the mob's internal artifacts (design docs, review reports, validation plans). If a deployment-specific handoff protocol exists (e.g., `protocols/local/coder-handoff`), follow it. Otherwise, the handoff includes at minimum:

- Branch name
- What the branch contains (problem and approach, not implementation details)
- Files changed with one-line descriptions
- Ordered verification steps with exact commands and expected results
- Commit guidance matching the target repo's style
- Non-blocking observations from the review
- Open questions or known risks

Write the handoff per `protocols/local/scratch-output-conventions.md` (e.g., `scratch/output/YYYY-MM-DD/<task-slug>/handoff.md`) and report the path to the user.

## PR Description

After writing the handoff, the orchestrator writes a PR description per `protocols/local/scratch-output-conventions.md` (e.g., `scratch/output/YYYY-MM-DD/<task-slug>/pr-description.md`). This is a draft the user copies into the GitHub PR body - it is not posted automatically.

The PR description is synthesized from the pipeline's accumulated context: the design rationale, implementation approach, and validation results. It reads as the user's own work - no agent names, no pipeline references.

The format follows the target repo's PR conventions. At minimum:

```markdown
## Summary
<What this PR does and why - 2-4 sentences.>

## Changes
- <Grouped by concern, not by file. One line per logical change.>

## Test plan
- <What was tested and how. Specific commands or scenarios.>
```

If the target repo has a PR template, follow it instead of the minimum format above.

After presenting the handoff and PR description paths, immediately ask the user whether to push the branch to the remote. This is a gated action — do not push without explicit approval — but the question should always be asked so the user does not have to prompt for it. If a deployment-specific handoff protocol specifies a transport mechanism (e.g., WIP branches), use that instead of pushing directly to the feature branch.

## Artifact Registry

Each station produces a named artifact. Before producing any artifact, read the protocol that governs it.

| Artifact | Producing station | Governing protocol |
|---|---|---|
| Design document | Babbage | `protocols/design-output.md` |
| Design critique report | Oppenheimer | (no separate protocol — output format is in agent definition) |
| Implementation (code + commits) | Lovelace | Lovelace's own definition |
| Review report | Friedman | `protocols/pr-review.md` |
| Validation plan | Curie | `protocols/validation-plan.md` |
| Handoff document | Friday (orchestrator) | `protocols/local/coder-handoff.md` if present; otherwise the minimum field list in the **Handoff** section above |
| PR description | Friday (orchestrator) | See **PR Description** section above |

The governing protocol defines the artifact's required fields, format, and any constraints. An artifact produced without consulting its governing protocol may be structurally incomplete or deployment-incompatible.

## Related Protocols

- `pipeline-narrative` — governs the accumulating output document Friday maintains throughout the pipeline
- `validation-plan` — governs the format of Curie's plan
- Deployment-specific handoff protocols (e.g., `protocols/local/coder-handoff`) — govern the shape and content of the terminal handoff document
