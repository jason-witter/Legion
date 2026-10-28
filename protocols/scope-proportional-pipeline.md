# Scope-Proportional Pipeline

The mob pipeline (Babbage -> Oppenheimer -> Lovelace -> Friedman -> Curie -> Asimov) is the protocol for substantive design work. Match station count and review-pass count to scope.

Skip Babbage when the dispatch already contains the fix.

## Size the task before the first dispatch

A ticket's wording does not size the change; the surface does. Before dispatching Babbage on tracker work, read the code the ticket names far enough to answer one question: does the requested behavior already exist? A few minutes on the file headers and filters is cheaper than a design pass that discovers it.

Where the answer reduces the work to a mechanical change (a column, a comment correction, a constant), the orchestrator states the fix and dispatches Lovelace directly. Where it does not, Babbage runs as usual.

Observed 2026-09-30: an "add a new promotion to two reports" ticket ran three design passes, two critiques and two production investigations, roughly 250k tokens per design pass, to arrive at a label column and comment fixes. Both views already included the promotion through a rule-based filter visible in their first 250 lines.

A design pass that surfaces risks beyond the ask (a payout basis, an attribution defect) reports them; it does not absorb them into scope. Pre-existing defects go to a ticket.

## When the model is the runtime

Skills, plugins, slash commands and agent definitions run on a model that reasons. Their product is guidance: what to fetch, how to judge it, what to say when a connection fails. Code belongs in them only for what the model cannot do through its tools (a credential flow, an API no tool reaches, a check that must hold whatever the model decides).

Ask before the first dispatch which parts of the request need code at all, and put the answer in the dispatch scope as a constraint. The mob is built for production code, and pointed at a model-runtime request without that constraint it reimplements the model's reasoning in code: templates, validators, deterministic pipelines, and then the tests and security review that code demands.

A word like "consistent" or "reliable" in a model-runtime request is about the reader's experience, not a determinism requirement. Pin its meaning before it reaches a design station.

Observed 2026-10-15: a weekly status-update skill ("fetch my PRs and Asana tasks, draft a post") ran four design passes, two critiques and an implementation, about $60 by the user's count, to produce 4,664 lines: a 2,806-line script and 86 tests pinning byte-identical evidence bundles and a draft linter. What was needed was a SKILL.md, a writing guide and a 100-line Asana fetch. Every critique round hardened the machinery and none asked whether it was needed; the security finding that drove two revisions existed only because the design had the model and the code splitting a job the model could do alone.

## Check scale against the ask before implementation

When a design clears critique and before Lovelace runs, the orchestrator compares the design's footprint (files, rough line count of new code, test count) against what the ask implies. Report that footprint in the station report alongside the decisions. Where the footprint is out of proportion to the ask, it is a policy decision for the user, not a station handoff: surface it before dispatching implementation. This is one of the pauses `CLAUDE.md`'s pipeline-autonomy constraint leaves room for.

The same check applies across revision rounds. A revision that adds machinery to close a finding is weighed against removing the thing the finding is about.

## Review passes

A single review pass at the station's configured effort is the default, for Friedman on implementations and for Oppenheimer on designs. Reserve a dual pass for full-surface changes: an interface or return-shape change, or a security surface. When a dual pass runs, the two passes carry different lenses (one weighted to correctness and concurrency, the other to security and tests) rather than two identical inspections, and Winterbotham merges the suffixed reports into the canonical one.

## Examples

Good, full pipeline because the work has real design surface:

```
Iter-2 fix-up: introduce four narrow-UPDATE helpers, plumb worker_id through five
functions, change _call_job return shape from `result` to `(result, bool)`. Babbage
designs the helper interfaces, the plumbing, and the call-site refactor. Lovelace ->
Friedman dual with split lenses (return-shape change makes this full-surface) -> Curie.
```

Good, Lovelace one-shot because the dispatch is the design:

```
A review bot flagged: reaper SQL leaves `last_started_at` stale, allowing re-claim of
just-dequeued rows. Add `last_started_at = :now` to the SET clause of
_CLAIM_SQL at reap_jobs.py:74-96, plus a behavioral test
asserting the field is stamped to NOW. Lovelace implements; single Friedman pass;
Curie updates the validation plan.
```

## Effort and model overrides, per dispatch

The Agent tool takes `model` and `effort` overrides per dispatch; the roster's `model:` frontmatter sets each station's default. This section binds every dispatch that sets an override, inside the mob or not. Where a protocol fixes the override for its own dispatches (`pr-review.md` Review Effort), that protocol wins.

**The discriminator is the question's shape, not the round number.** A pass is cheap when its question is narrow and already specified: confirm these two named edits do what they claim, merge these two reports, check these files agree with each other.

- **Definition default** for a cold pass, an adversarial review, an unfamiliar surface, or any pass whose question is "is this correct."
- **Lower effort** for a pass whose question is "did the named change land," a consolidation, a consistency check across files already written, or a mechanical survey.
- **Never lower** because a surface has been reviewed before. Prior coverage narrows nothing unless the fix under review was itself precisely specified.

Do not reach for the dial to make a large pipeline affordable; cut rounds or scope for that, per the rest of this rule.

- The dispatch can express the fix mechanically (file, line, exact change): skip Babbage.
- The change is a typo, revert, or one-line config with obvious semantics: consider Lovelace one-shot with no review.
- The change introduces or alters an interface, changes a return shape, or has security implications: run the full pipeline with dual split-lens review passes.
- Everything else: full pipeline with single review passes, the default.

When in doubt, run the full pipeline.
