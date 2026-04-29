# Design Output

Governs the artifact shape and output convention for technical design work.

## Parameters

- `feature-slug` — kebab-case identifier for the feature (e.g., `add-payment-validation`). Once a PR number is known, prefix it: `pr-274330-add-payment-validation`. Caller-supplied or derived from the task description.

## Steps

1. **Determine the slug** — If not supplied, derive from the task name: lowercase, hyphenated, concise (3–5 words). If a PR number is known, prefix with `pr-<number>-`.

2. **Write the design document** to `scratch/output/_<feature-slug>/babbage_<N>.md` where N is the next available number starting at 1 (e.g., `babbage_1.md`, `babbage_2.md`). `scratch/` resolves to the HopLegion repo per `rules/scratch-path-resolution.md`. See format below. This is the handoff to the implementer.

3. **Report the path** to the caller.

## Design Document Format

The design document is a handoff instrument for the implementer. It states the chosen approach and what to build.

```markdown
## Task: [Task name or brief description]

### Approach
[One paragraph. The chosen direction and the deciding reason.]

### Affected Files
- `path/to/file.py` — [what changes]
- `path/to/other.py` — [what changes]

### Interface Contracts
[Function signatures, class interfaces, data shapes — whatever is relevant]

### Data Flow
[How data moves through this change, if non-trivial]

### Test Strategy
[What to test: unit, integration, edge cases]

### Risks and Edge Cases
[Known failure modes and boundary conditions. Call out any that apply: security
implications, database or schema changes, customer-facing behavior changes,
performance impact. If none apply, say so briefly — the absence is worth stating.]

### Open Questions
[Anything that requires a decision before implementation can proceed]
```

For straightforward tasks, inline notes suffice — not every task needs all sections. Use judgment: if the implementer could build this correctly from three sentences, write three sentences. Even a brief design should be written to disk when it will be passed to an implementer by path.

## Code in Design Documents

Code blocks are for **interface contracts**: function signatures, proto definitions, class interfaces, data shapes. These are the boundaries the implementer must conform to.

Implementation logic is described in **prose** that states what the code must do, what constraints it must satisfy, and why. The implementer derives the function bodies from the description and the codebase, not by transcribing the design document.

A design that contains complete function implementations is doing Lovelace's job. It also hides its own blind spots: a literal code line like `resolve_store_country(user_id)` looks complete, but it masks the design question of whether that function's internal behavior is appropriate in the new context.

Good:
```
_fetch_and_create_batch_jobs streams user IDs from the reporting replica,
accumulates them into batches of `batch_size`, and persists groups of
PERSIST_BATCH_SIZE jobs atomically using _persist_jobs_and_increment_step_atomically.
The query must not hold a database cursor open for the full iteration — use
chunked pagination to bound cursor lifetime.
```

Bad:
```python
def _fetch_and_create_batch_jobs(...):
    rows = _BackfillPaymentQueries.select_distinct_user_ids_with_completed_payments(...)
    for row in rows:
        current_batch.append(row['user_id'])
        # ... 40 more lines of implementation
```

The first tells the implementer what to build and names a constraint (cursor lifetime) that the implementer must solve. The second tells the implementer what to type.

## Edge Cases

- If the output directory does not exist, create it before writing.
