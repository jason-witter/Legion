# A Superseded Output Is Not a Baseline

Agreement with a prior output is evidence only while that output is still believed. Where it is not, agreement is not reassurance; it is the absence of a change that was supposed to happen.

This is the currency model of `rules/feature-directory-lifecycle.md` one level up. There, currency governs **artifacts**: a station reads nothing superseded and nothing from another run. Here it governs **delivered output**, the data a prior run produced. Same discriminator, same reason.

## The discriminator is supersession, not iteration

Iterative work is not the trigger, and a long-running feature is not disqualified from having a baseline. Ask instead whether the prior output is still believed. Two things end that, and either is sufficient:

- **The change is meant to move it.** Where the point of the work is that the old figures were wrong, incomplete, or unpriced, a check that they still agree is a check that the work did not happen. Bounding the movement to "only where expected" reintroduces the same problem, because the expected population is exactly the one under change.
- **Supersession has accumulated past attribution.** After enough passes, the prior output embeds a stack of decisions nobody can enumerate on demand. A delta then cannot be assigned to the change under test, and an undecomposable delta is not evidence whichever way it comes out.

Both were true of the same comparison on 2026-09-24, which is what made it degenerate.

## Where a baseline is real, use it

A prior output the change is **not** supposed to move is a regression check, and a good one. Unchanged surface, unchanged population, an expected delta of zero: compare, and treat a difference as a defect. This is the ordinary case on a stable surface and this rule does not touch it.

The test is not how old the feature is or how many runs preceded it. It is whether a difference, if one appeared, would tell you something you could act on.

## It binds at dispatch composition

The part that keeps getting missed. The failure is not a validation plan that turns out to contain a comparison; it is the orchestrator naming prior output as a station's input and asking for an acceptance instrument built on it. Stop at the dispatch.

Two disguises, because both read as diligence:

- **"Rough consistency, not equivalence."** Loosening the tolerance does not change what the instrument is.
- **"The captures already exist, so it is free."** The captures are not the cost. The station reading them, the checker it writes, and the context it burns are.

## What to reach for instead

Establish correctness from the change: read it, review it, and where an invariant matters, express it as an identity **inside a single run**. A run that ties to itself needs no predecessor.

Where the change genuinely cannot be trusted without an empirical read, say so in one sentence and let the user decide whether to buy it. Do not build the instrument first and present it as the plan.

## Removing a check is not an event

When a comparison drops out, name it in one sentence and move on. A "what we no longer verify" section, a risk entry pricing the absent comparison, or a drift bound computed to stand in for it are the same failure wearing a diligent face.

Composes with `protocols/scope-proportional-pipeline.md`, which governs how many stations a change earns; this governs whether a verification station has a valid question to answer at all.
