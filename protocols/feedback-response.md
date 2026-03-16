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

Friday provides each station with a curated summary of prior output — not raw transcripts — and decides whether to advance, loop back, or halt.

## Context Briefs

**Lovelace's initial brief contains:**
- The Denniston digest (feedback items and proposed actions)
- Branch name and relevant implementation context (files, existing approach)
- No design document — the digest is the spec

**Friedman's brief contains:**
- The Denniston digest, so Friedman can verify each feedback item was addressed
- A summary of Lovelace's changes
- The original task description

**Curie's brief contains:**
- Branch name and summary of what changed
- Friedman's approval confirmation
- The full set of changes for test planning

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

## Handoff

After Curie completes, Friday produces a handoff document. The pipeline is not complete until the handoff exists.

The handoff document is self-contained. It includes at minimum:

- Branch name and PR reference
- Summary of feedback items addressed (one line per item)
- Files changed with one-line descriptions
- Curie's validation plan (or a reference to it)
- Non-blocking observations from Friedman's review
- Open questions or known risks

If a deployment-specific handoff protocol exists, follow it. Otherwise write the handoff to `scratch/output/YYYY-MM-DD/handoffs/<branch-name>.md` and report the path to the user.

## Related Protocols

- `mob-pipeline` — the greenfield pipeline; use when no Denniston digest exists or the task requires a new branch
- `pipeline-narrative` — governs the accumulating output document Friday maintains throughout the pipeline
- `validation-plan` — governs the format of Curie's plan
- Deployment-specific handoff protocols — govern the shape and content of the terminal handoff document
