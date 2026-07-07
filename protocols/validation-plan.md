# Validation Plan Protocol

Create a plan that specifies what to test, how to test it, and what success looks like for a given implementation. Also defines the report format for communicating results after execution.

## Purpose

Code that cannot be run locally needs clear instructions on what to test and how. A validation plan makes that handoff explicit and unambiguous. The report format closes the loop — it communicates what was written, what was run, and whether the implementation is ready.

## Output Location

Write the validation report to the feature directory:

```
scratch/output/_<feature-slug>/curie_<N>.md
```

`scratch/` resolves to the framework repo per `rules/scratch-path-resolution.md`. The feature slug is provided by the pipeline context. N is the next available number starting at 1 (e.g., `curie_1.md`, `curie_2.md`).

## Validation Plan Format

```markdown
## Validation Plan: [Task or change description]

### Prerequisites
[Environment setup, dependencies, services that need to be running]

### Checks

#### 1. [Check name]
- **Run:** `[exact command]`
- **Expect:** [success criteria]
- **On failure:** [what it means, how to interpret]
- **Priority:** blocking / informational

#### 2. [Check name]
...

### Manual Verification (if any)
[Steps that require human judgment — UI behavior, visual correctness, etc.]
```

The plan covers:
- Unit tests (new and existing)
- Integration tests if applicable
- Static analysis / linting (if the project uses it)
- Type checking (if the project uses it)
- Any manual verification steps that can't be automated

## Validation Report Format

```markdown
## Validation: [Task or change description]

### Tests Written
[List of new test files or test cases added, or "none — existing coverage sufficient"]

### Validation Plan
[Reference to the plan, or inline if brief]

### Execution Results
[If tests were run locally: pass/fail counts, full error output for failures]
[If tests were not run: "Validation plan produced for remote execution. Tests not run locally — [reason]."]

### Coverage Assessment
[What is covered, what is not, any gaps worth noting]

### Recommendation
[Pass — ready for Friday to present for merge]
[Blocked — failures or coverage gaps require resolution before merge]
[Plan-only — validation plan ready for remote execution; results pending]
```

## Writing Good Validation Plans

1. **Be specific about commands** — Exact test paths and file targets
2. **Set clear expectations** — How many tests, what should pass
3. **Document behavior** — So the executor knows if it "works"
4. **Flag ambiguities** — If something is unclear, note it
5. **Don't assume environment** — List all setup steps

## Example Plan (Python stack)

```markdown
## Validation Plan: Token bucket rate limiter middleware (feature/api-rate-limiting)

### Prerequisites
1. `pip install -r requirements.txt` (if requirements changed)
2. `export RATE_LIMIT_ENABLED=true`

### Checks

#### 1. Unit tests
- **Run:** `pytest tests/middleware/test_rate_limiter.py -v`
- **Expect:** 8 tests pass: under-limit requests allowed, over-limit requests blocked with 429, Retry-After header present, token refill over time, per-user isolation, per-endpoint limits, internal-request bypass
- **On failure:** the limiter core logic does not match the design. Document the failing case; fixing is the user's hands-on work.
- **Priority:** blocking

#### 2. Type checking
- **Run:** `mypy src/middleware/rate_limiter.py`
- **Expect:** no errors
- **On failure:** annotation gap introduced by the new middleware; resolve before merge
- **Priority:** blocking

#### 3. Linting
- **Run:** `ruff check src/middleware/`
- **Expect:** no violations
- **On failure:** style-only findings; auto-fix where possible
- **Priority:** informational

#### 4. Integration tests
- **Run:** `pytest tests/integration/test_api_rate_limiting.py -v`
- **Expect:** 3 tests pass: limit applies to API endpoints, limit does not apply to webhook endpoints, rate-limit headers present in responses
- **On failure:** middleware wiring or route scoping is wrong even if unit-level logic passes
- **Priority:** blocking

### Manual Verification
None. Note for the report's coverage assessment: storage is in-memory only (resets on server restart); Redis-backed distributed limiting is out of scope for this change.
```
