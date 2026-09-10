# Validation Plan Protocol

Specify what to verify, how to verify it, and what success looks like for an implementation the
author cannot execute. Produces one file: the validation artifact.

## Output Location

```
scratch/output/_<feature-slug>/curie_<N>.md
```

`scratch/` resolves to the framework repo per `rules/scratch-path-resolution.md`. The feature slug
comes from pipeline context. N is the next available number starting at 1; list the directory before
choosing it (`rules/feature-directory-lifecycle.md`).

## Artifact Format

One file, these sections, this order. The recommendation leads: downstream stations and the user
read the verdict first, and evidence placed ahead of it buries the thing they came for.

```markdown
# Validation: [task or change description]

## Recommendation
[Pass — ready to present for merge]
[Blocked — failures or coverage gaps require resolution before merge]
[Plan-only — plan ready for remote execution; results pending]

## Tests Written
[New test files and cases, or "none — existing coverage sufficient" with the reasoning]

## Tests and What Each Catches
[One row per new test. See below.]

## Validation Plan

### Prerequisites
[Environment setup, dependencies, services that must be running]

### Checks

#### 1. [Check name]
- **Run:** `[exact command]`
- **Expect:** [success criteria, including counts]
- **On failure:** [what a negative result means]
- **Priority:** blocking / informational

### Manual Verification
[Steps requiring human judgment, or "none"]

## Coverage Assessment
[What is covered, what is not, and which risk classes remain open by realization]

## Known Risks
[Edge cases the tests do not reach, assumptions, validation gaps, open questions]

## Execution Results
[Pass/fail counts if the suite was run; otherwise the reason it was not and where it will run]
```

The plan covers unit tests, integration tests where applicable, static analysis, type checking, and
any manual verification that cannot be automated.

## Tests and What Each Catches

One row per new test. The failure-mode sentence is the entry; the category is shorthand beside it.

```markdown
| Test | Category | What it catches |
|---|---|---|
| `test_<name>` | feature-exercising | One sentence naming the real failure mode, actionable without opening another file. |
| `test_<name>` | contract-shape | The failure mode, plus the reach limit: what a passing result does not establish. |
```

Categories come from `protocols/test-quality.md`. Feature-exercising and contract-shape are
acceptable; tautology, branching-only, library-semantics, and restated-literals are refused and
surface as quality concerns.

**A row carrying only a category is not an entry.** The category names resolve inside this framework
and nowhere outside it, so a column of bare labels reads as established vocabulary to a reader with
no way to reach the definition, and they supply a meaning of their own. The sentence is the field
that survives leaving the framework; the label is the field that does not. Observed 2026-08-28: a
bare-label column reached the user unreadable, and two artifacts written under identical agent
instructions rendered this section in different shapes, because the shape was specified nowhere the
author looks for it.

Close the section with the refused-category count, and a clustering note when one applies. This
section is the input to the Coverage Assessment: a suite that mostly runs the production path and
asserts observable outcomes is meaningfully validated when it runs green, and a suite built on
refused-category tests is nominally green and substantively unverified. Record that distinction here
so the terminal synthesis sees it.

## Known Risks

This section leaves the artifact. Known Risks and open questions ride into the commit body and are
surfaced to the user in-session when the pipeline completes (`protocols/mob-pipeline.md`, the
deployment's handoff protocol). Anything genuinely uncertain belongs here rather than omitted to make
the branch read clean.

## Writing Good Plans

1. **Exact commands** — full test paths and file targets, not a description of them
2. **Countable expectations** — how many tests, which behaviors, what should pass
3. **Interpretable failures** — what a negative result tells the executor
4. **Named ambiguities** — where something is unclear, say so in place
5. **No assumed environment** — list the setup steps

Where the implementation surface is genuinely too thin to test meaningfully (a one-line getter, a
passthrough wrapper), record "no meaningful test surface exists for this path" rather than padding
with shallow coverage. That is a more useful signal than a tautology that always passes.

## Example: a Checks block

```markdown
#### 1. Unit tests
- **Run:** `pytest tests/middleware/test_rate_limiter.py -v`
- **Expect:** 8 tests pass: under-limit allowed, over-limit blocked with 429, Retry-After present,
  token refill over time, per-user isolation, per-endpoint limits, internal-request bypass
- **On failure:** limiter core logic does not match the design. Document the failing case.
- **Priority:** blocking

#### 2. Type checking
- **Run:** `mypy src/middleware/rate_limiter.py`
- **Expect:** no errors
- **On failure:** annotation gap introduced by the new middleware; resolve before merge
- **Priority:** blocking
```

## Example: a Tests and What Each Catches row

```markdown
| Test | Category | What it catches |
|---|---|---|
| `test_over_limit_request_returns_429` | feature-exercising | Drives the real middleware past the bucket ceiling and asserts the response status and Retry-After header. Fails if the ceiling comparison is inverted or the header is dropped. |
| `test_limiter_sql_filters_by_user` | contract-shape | Asserts the `WHERE user_id` clause is present. Catches a renamed column; does not catch a refactor that preserves the substring while dropping the predicate's effect. |
```

## Edge Cases

- Existing coverage is sufficient: say so in Tests Written with the reasoning, and leave Tests and
  What Each Catches empty rather than classifying tests written elsewhere.
- The change has no automatable verification: the plan is the Manual Verification section, and the
  recommendation is Plan-only.
