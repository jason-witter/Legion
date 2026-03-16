# Mob Pipeline Protocol

Coordinate Babbage, Lovelace, Friedman, and Curie to produce code changes against a software repo. Friday orchestrates — the agents do not communicate directly.

## Usage

Invoke when a coding task needs the full mob: design a technical approach, implement it, review the implementation, and validate it works. Each station completes before the next begins. Friday manages every handoff.

## Station Sequence

Pipelines follow this fixed order:

1. **Babbage** (design) — produces a technical approach: scope, interface contracts, affected files, test strategy
2. **Lovelace** (implementation) — produces code matching Babbage's design
3. **Friedman** (review) — evaluates Lovelace's implementation for correctness, security, and style
4. **Curie** (validation) — verifies the implementation works as intended

All four stations run in every pipeline. Skipping a station is not a valid shortcut — review without design produces drift, and validation without review produces unreviewed code.

## Hub-and-Spoke Model

Babbage, Lovelace, Friedman, and Curie do not communicate directly. All information flows through Friday:

```
Friday → Babbage
Babbage → Friday
Friday → Lovelace (with Babbage's design)
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

- **Babbage → Lovelace**: If the design is incomplete or contradictory, loop back to Babbage. Do not implement against an unclear spec.
- **Lovelace → Friedman**: If implementation is visibly incomplete or substantially deviates from design without explanation, loop back before review.
- **Friedman → Lovelace**: If Friedman has blockers, route back to Lovelace. Do not pass to Curie until Friedman approves clean.
- **Curie → Done**: If validation fails, report to the human. Do not loop automatically — failures at this stage require human judgment.

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

Write the handoff to `scratch/output/YYYY-MM-DD/handoffs/<branch-name>.md` and report the path to the user.

After presenting the handoff, immediately ask the user whether to push the branch to the remote. This is a gated action — do not push without explicit approval — but the question should always be asked so the user does not have to prompt for it. If a deployment-specific handoff protocol specifies a transport mechanism (e.g., WIP branches), use that instead of pushing directly to the feature branch.

## Artifact Registry

Each station produces a named artifact. Before producing any artifact, read the protocol that governs it.

| Artifact | Producing station | Governing protocol |
|---|---|---|
| Design document | Babbage | `protocols/design-output.md` |
| Implementation (code + commits) | Lovelace | Lovelace's own definition |
| Review report | Friedman | `protocols/pr-review.md` |
| Validation plan | Curie | `protocols/validation-plan.md` |
| Handoff document | Friday (orchestrator) | `protocols/local/coder-handoff.md` if present; otherwise the minimum field list in the **Handoff** section above |

The governing protocol defines the artifact's required fields, format, and any constraints. An artifact produced without consulting its governing protocol may be structurally incomplete or deployment-incompatible.

## Related Protocols

- `pipeline-narrative` — governs the accumulating output document Friday maintains throughout the pipeline
- `validation-plan` — governs the format of Curie's plan
- Deployment-specific handoff protocols (e.g., `protocols/local/coder-handoff`) — govern the shape and content of the terminal handoff document
