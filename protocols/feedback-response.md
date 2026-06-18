# Feedback Response Protocol

Coordinate Lovelace, Friedman, and Curie to address PR reviewer feedback on an existing branch. Friday orchestrates — the agents do not communicate directly.

## Usage

Invoke when a Denniston digest exists and the task is addressing reviewer feedback on an existing PR branch. The Denniston digest is the design document — Babbage is skipped. Work happens on the existing PR branch, not a new one.

This protocol is a sibling to `mob-pipeline`. It references the same agents and hub-and-spoke model, but defines its own station sequence for this entry condition.

## Entry Condition

Both of these must be true before invoking:

1. A Denniston digest exists for the PR — it contains the reviewer feedback and the proposed response actions
2. The work target is an existing branch with an open PR (not a greenfield implementation)

If either condition is absent, use `mob-pipeline` instead.

## Station Sequence

Three stations, in order:

1. **Lovelace** (implementation) — addresses feedback items identified in the Denniston digest; commits changes to the existing branch
2. **Friedman** (review) — evaluates Lovelace's changes for correctness, completeness against the feedback, and any regressions introduced
3. **Curie** (validation) — produces a validation plan for the revised implementation

Babbage is not invoked. The Denniston digest provides the scoped analysis and action list that Babbage would otherwise produce.

## Hub-and-Spoke Model

All information flows through Friday:

```
Friday → Lovelace (with Denniston digest + branch context)
Lovelace → Friday
Friday → Friedman (with digest + implementation changes)
Friedman → Friday
Friday → Lovelace (with Friedman's findings) — if blockers
Lovelace → Friday
Friday → Friedman (re-review) — repeat until clean
Friedman → Friday
Friday → Curie (with full prior context)
Curie → Friday
```

Each station receives the feature slug and work location. Agents orient from the feature directory and the codebase per their definitions. Friday sequences stations and makes go/no-go decisions. The Denniston digest in the feature directory serves as the spec (no separate design document).

**Curie's brief contains:**
- Branch name and summary of what changed
- Friedman's approval confirmation
- The full set of changes for validation

## Go / No-Go Between Stations

- **Lovelace → Friedman**: If implementation is visibly incomplete or deviates from the digest without explanation, loop back before review.
- **Friedman → Lovelace**: If Friedman has blockers, route back to Lovelace. Do not pass to Curie until Friedman approves clean.
- **Curie → Done**: If Curie identifies validation failures, surface to the user. Do not loop automatically.

A loop always restarts from the station where the problem originated.

## Friedman–Lovelace Iteration Loop

Same mechanics as `mob-pipeline`. Loop cap is 3 iterations — if Friedman still has blockers after 3 Lovelace revision cycles, Friday halts and surfaces to the user with the full blocker list and iteration history.

Friedman's re-review is targeted: verify each prior blocker is resolved and check any new code introduced in the revision. Unchanged code is not re-reviewed.

## Validation Output

Curie produces a validation plan per the `validation-plan` protocol. In environments where tests cannot run locally, the plan is the primary deliverable. Pass it to the deployment's local handoff protocol for remote execution.

## Bridge to the Next Environment

The protocol does not author a handoff document. Like `mob-pipeline`, the work leaves through the diff, the squash commit body, and the PR description.

After Curie completes, Friday composes the **commit-body kernel** at squash time from:

- **Curie's Known Risks / Open Questions** — edge cases not covered, assumptions, validation gaps.
- **Friedman's Review Notes** — non-blocking observations on the revision.

For this protocol the kernel scopes to the feedback iteration: which review items were addressed and any residual risk in the changes. The kernel is scrubbed by Asimov per `rules/user-authorship.md` (no agent names, no pipeline vocabulary) and folded into the single squash commit body, which the next reader picks up with `git log -1`. If a deployment-specific bridge protocol exists (e.g., `protocols/local/coder-handoff`), follow it for kernel composition and the environment setup commands the user runs. Friday no longer writes a `handoff_<N>.md` file.

Write a PR description to `scratch/output/_<feature-slug>/pr-description.md`. Since this protocol operates on an existing PR, the description is an update draft that summarizes the feedback addressed in this iteration. The user decides whether to append it to the existing PR body or replace it. See the **PR Description** section in `mob-pipeline` for format guidance.

## Related Protocols

- `mob-pipeline` — the greenfield pipeline; use when no Denniston digest exists or the task requires a new branch
- `pipeline-narrative` — governs the accumulating output document Friday maintains throughout the pipeline
- `validation-plan` — governs the format of Curie's plan
- Deployment-specific bridge protocols (e.g., `protocols/local/coder-handoff`) — govern the commit-body kernel composition, the PR description path, and the environment setup commands the user runs
