# Validation Plan Protocol

Specify what to verify, how to verify it, and what success looks like for an implementation the
author cannot execute. Produces one file: the validation artifact.

## Output Location

```
scratch/output/_<feature-slug>/curie_<N>.md                 single-run feature
scratch/output/_<feature-slug>/curie_<run-scope>_<N>.md     run scope supplied
```

The artifact lands at the feature directory root, which is the pipeline-artifact class. `scratch/`
resolves to the framework repo per `rules/scratch-path-resolution.md`. The feature slug comes from
pipeline context.

The run scope is a lowercase token naming the surface this pipeline pass works (e.g. `refund`,
`taxcorr`). The dispatch supplies it when the feature holds more than one run; the station never
invents one. Get the filename from `scripts/next-artifact.sh <feature-dir> curie [run-scope]`: N is
counted inside the (agent, run) pair, so a second run's numbering does not continue the first
(`rules/feature-directory-lifecycle.md`, which defines a run and its boundary test).

Report the full filename to the caller, not the directory. What reaches a later station is the file
the dispatch names (`rules/dispatch-shape.md`). The orchestrator verifies the file landed per
`protocols/post-dispatch-artifact-verify.md` before advancing.

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

## Directives and Reasoning

Whoever executes this plan does so without the session behind it, usually on another machine, so
what they run has to be separable from what the artifact explains.

- **Directives bind.** The Recommendation, the Prerequisites, each Check (exact command, expected
  result, failure reading, priority), and each Manual Verification step. These are executed as
  written.
- **Reasoning explains.** The Coverage Assessment, each test's failure-mode sentence, and Known
  Risks. They say what a green run establishes and what it leaves open. Reasoning carries no step of
  its own.

A check that exists only as a sentence in the Coverage Assessment does not get run. Move it into
Checks or drop it; do not leave an instruction in a section the executor reads as commentary.

### Code claims carry `path:line`

Every statement this artifact makes about the existing tree carries its location: "the ceiling
comparison is at `rate_limiter.py:88`", not "the limiter compares against the ceiling." An uncited
code claim is unverified and is reported that way rather than repeated as established
(`rules/code-facts-from-the-tree.md`). A command is not a code claim; it is verified by running it.

The rule's reading half binds this station too: the design and review artifacts the dispatch names
are authoritative about what to build and about their findings, and their claims about the tree are
pointers to check before a Check or a coverage judgment is written on top of one.

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
- A check compares against a prior run's output (captures, earlier figures): read
  `protocols/superseded-output-is-not-a-baseline.md` before including it.
