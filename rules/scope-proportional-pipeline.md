# Scope-Proportional Pipeline

The mob pipeline (Babbage -> Oppenheimer -> Lovelace -> Friedman -> Curie -> Asimov) is the protocol for substantive design work. Match station count and review-pass count to scope. The pipeline exists to apply review pressure where it adds signal; apply less where less is needed.

Skip Babbage when the dispatch already contains the fix. If you can name the file, line, and exact change, the design IS the dispatch and Babbage's output will be ceremony.

## Review passes

A single review pass at the station's configured effort is the default, for Friedman on implementations and for Oppenheimer on designs. Reserve a dual pass for full-surface changes: an interface or return-shape change, or a security surface. When a dual pass runs, the two passes carry different lenses (one weighted to correctness and concurrency, the other to security and tests) rather than two identical inspections, and Winterbotham merges the suffixed reports into the canonical one. Redundant identical passes buy recall a strong single pass already provides; lens diversity catches what redundancy cannot.

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
Cursorbot flagged: reaper SQL leaves `last_started_at` stale, allowing re-claim of
just-dequeued rows. Add `last_started_at = :now` to the SET clause of
_CLAIM_STALE_JOBS_SQL at reap_stale_workflow_jobs.py:74-96, plus a behavioral test
asserting the field is stamped to NOW. Lovelace implements; single Friedman pass;
Curie updates the validation plan.
```

## Judgment cues

- The dispatch can express the fix mechanically (file, line, exact change): skip Babbage.
- The change is a typo, revert, or one-line config with obvious semantics: consider Lovelace one-shot with no review.
- The change introduces or alters an interface, changes a return shape, or has security implications: run the full pipeline with dual split-lens review passes.
- Everything else: full pipeline with single review passes, the default.

When in doubt, run the full pipeline. Ceremony is recoverable; missed design surface is not.
