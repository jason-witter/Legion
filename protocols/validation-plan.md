# Validation Plan Protocol

Create a plan that specifies what to test, how to test it, and what success looks like for a given implementation. Also defines the report format for communicating results after execution.

## Purpose

Code that cannot be run locally needs clear instructions on what to test and how. A validation plan makes that handoff explicit and unambiguous. The report format closes the loop — it communicates what was written, what was run, and whether the implementation is ready.

## Output Location

Write the validation report to the feature directory:

```
scratch/output/_<feature-slug>/curie.md
```

`scratch/` resolves to the HopLegion repo per `rules/scratch-path-resolution.md`. The feature slug is provided by the pipeline context. Use `curie_<N>.md` where N is the next available number starting at 1 (e.g., `curie_1.md`, `curie_2.md`).

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
# Validation Plan: feature/api-rate-limiting

## Branch Info
- Branch: feature/api-rate-limiting
- Implementation: Token bucket rate limiter middleware

## Setup Steps
1. `pip install -r requirements.txt` (if changed)
2. `export RATE_LIMIT_ENABLED=true`

## Validation Checklist

### Unit Tests
- [ ] Run: `pytest tests/middleware/test_rate_limiter.py -v`
- [ ] Expected: 8 tests pass
  - test_allows_requests_under_limit
  - test_blocks_requests_over_limit
  - test_refills_tokens_over_time
  - test_handles_multiple_users
  - test_respects_different_rate_limits_per_endpoint
  - test_returns_429_when_limited
  - test_includes_retry_after_header
  - test_bypasses_rate_limit_for_internal_requests

### Type Checking
- [ ] Run: `mypy src/middleware/rate_limiter.py`
- [ ] Expected: No errors (all types properly annotated)

### Linting
- [ ] Run: `ruff check src/middleware/`
- [ ] Expected: No violations

### Integration Tests
- [ ] Run: `pytest tests/integration/test_api_rate_limiting.py -v`
- [ ] Expected: 3 tests pass
  - test_rate_limit_applies_to_api_endpoints
  - test_rate_limit_does_not_apply_to_webhooks
  - test_rate_limit_headers_present_in_response

## Expected Behavior

- API requests are rate limited to 100 req/min per user
- When limit exceeded, return 429 with Retry-After header
- Token bucket refills at 100 tokens/minute
- Internal requests bypass rate limiting
- Webhook endpoints not rate limited

## Known Limitations

- In-memory storage only (resets on server restart)
- Does not support Redis-backed distributed rate limiting yet

## If Tests Fail

Document failures and flag for the user's debugging.
The executor documents failures. Fixing them is the user's hands-on work.

## Success Criteria

- [x] Unit tests: 8/8 pass
- [ ] Type checking: Clean
- [ ] Linting: Clean
- [ ] Integration tests: 3/3 pass
- [ ] Behavior matches specification
```
