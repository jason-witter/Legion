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
Friday → Lovelace (digest, work location)
Lovelace → Friday
Friday → Friedman (digest, work location)
Friedman → Friday
Friday → Lovelace (review report, work location), if Blocking
Lovelace → Friday
Friday → Friedman (digest, prior review report, work location), full re-review, repeat until clean
Friedman → Friday
Friday → Curie (digest, review report, work location)
Curie → Friday
```

Every dispatch names the files that station needs, whole and unedited, and says nothing about what is in them (`rules/dispatch-shape.md`). The Denniston digest serves as the spec (no separate design document). Friday sequences stations and makes go/no-go decisions; the read set and the re-review discharge obligation follow `mob-pipeline`.

## Go / No-Go Between Stations

- **Lovelace → Friedman**: If implementation is visibly incomplete or deviates from the digest without explanation, loop back before review.
- **Friedman → Lovelace**: If Friedman has blockers, route back to Lovelace. Do not pass to Curie until Friedman approves clean.
- **Curie → Done**: If Curie identifies validation failures, surface to the user. Do not loop automatically.

A loop always restarts from the station where the problem originated.

## Friedman–Lovelace Iteration Loop

Same loop structure as `mob-pipeline`, with one deliberate divergence on re-review scope. Loop cap is 3 iterations — if Friedman still has blockers after 3 Lovelace revision cycles, Friday halts and surfaces to the user with the full blocker list and iteration history.

Re-review scope diverges from `mob-pipeline` by design: there, re-review is a full pass because a mob revision can break previously-clean code anywhere in the change. Here the surface is a fix-up on a PR that has already been through full review (mob and human), so Friedman's re-review is targeted: verify each prior blocker is resolved and check any new code introduced in the revision. Unchanged code is not re-reviewed.

## Validation Output

Curie produces a validation plan per the `validation-plan` protocol. In environments where tests cannot run locally, the plan is the primary deliverable. Pass it to the deployment's local handoff protocol for remote execution.

## Bridge to the Next Environment

The protocol does not author a handoff document. Like `mob-pipeline`, the work leaves through the diff, the squash commit body, and the PR description.

The squash commit body is a standalone description of what the branch does, at the altitude a reader of `git log -1` needs. It carries no risks, open questions, conditionals, or decision rationale. See the **Bridge to the Next Environment** section in `mob-pipeline` for the describes-not-judges standard and the good/bad calibration.

The non-diff judgment routes to other channels, not the commit body:

- **Actionable follow-ups** (an item a reviewer should act on) go in the PR description.
- **Risks and open questions** — Curie's Known Risks / Open Questions and Friedman's Review Notes on the revision — are surfaced to the user in-session when the iteration completes.

Asimov scrubs the commit body in place per `rules/user-authorship.md` (no agent names, no pipeline vocabulary). If a deployment-specific bridge protocol exists (e.g., `protocols/local/coder-handoff`), follow it for the PR description path, skipped-check handling, and the environment setup commands the user runs. Friday does not write a `handoff_<N>.md` file.

Write a PR description to `scratch/output/_<feature-slug>/pr-description.md`. Since this protocol operates on an existing PR, the description is an update draft that summarizes the feedback addressed in this iteration. The user decides whether to append it to the existing PR body or replace it. See the **PR Description** section in `mob-pipeline` for format guidance. The PR description is engineer-facing prose; before handing it to the user, run the scrub per `rules/engineer-facing-handoff-scrub.md` (the Asimov tone-and-identifier pass).

## Thread Replies

A reply drafted for the user to post on a reviewer's thread keeps the code as the subject of every sentence, per `protocols/review-comment-register.md`, and runs only as long as the thread needs, per `protocols/review-reply-economy.md`. Neither loads ambiently; read both before drafting the first reply.

## Related Protocols

- `mob-pipeline` — the greenfield pipeline; use when no Denniston digest exists or the task requires a new branch
- `pipeline-narrative` — governs the accumulating output document Friday maintains throughout the pipeline
- `validation-plan` — governs the format of Curie's plan
- Deployment-specific bridge protocols (e.g., `protocols/local/coder-handoff`) — govern the PR description path, skipped-check handling, and the environment setup commands the user runs
