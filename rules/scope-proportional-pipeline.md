# Scope-Proportional Pipeline

The mob pipeline (Babbage -> Lovelace -> Friedman dual -> Curie) is the protocol for substantive design work. Match station count to scope. The pipeline exists to apply review pressure where it adds signal; apply less where less is needed.

Skip Babbage when the dispatch already contains the fix. If you can name the file, line, and exact change, the design IS the dispatch and Babbage's output will be ceremony.

Skip Friedman dual pass when the change is small and localized. One file, few lines, focused intent: a single review pass is proportional.

## Examples

Good, full pipeline because the work has real design surface:

```
Iter-2 fix-up: introduce four narrow-UPDATE helpers, plumb worker_id through five
functions, change _call_job return shape from `result` to `(result, bool)`. Babbage
designs the helper interfaces, the plumbing, and the call-site refactor. Lovelace ->
Friedman dual -> Curie.
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
- The change is one file with focused intent and no contract change: single Friedman pass.
- The change is a typo, revert, or one-line config with obvious semantics: consider Lovelace one-shot with no review.
- The change introduces or alters an interface, changes a return shape, or has security implications: run the full pipeline.

When in doubt, run the full pipeline. Ceremony is recoverable; missed design surface is not.
