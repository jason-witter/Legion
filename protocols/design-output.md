# Design Output

Governs the artifact shape and output convention for technical design work.

## Parameters

- `feature-slug` — kebab-case identifier for the feature (e.g., `add-payment-validation`). Once a PR number is known, prefix it: `pr-1234-add-payment-validation`. Caller-supplied or derived from the task description.
- `run-scope` — optional lowercase token naming the surface this pipeline pass works (e.g. `refund`, `taxcorr`). Supplied by the dispatch when the feature holds more than one run; never invented by the station. `rules/feature-directory-lifecycle.md` defines a run and its boundary test.

## Steps

1. **Determine the slug** — If not supplied, derive from the task name: lowercase, hyphenated, concise (3–5 words). If a PR number is known, prefix with `pr-<number>-`.

2. **Write the design document** to the feature directory root, which is the pipeline-artifact class:

   ```
   scratch/output/_<feature-slug>/babbage_<N>.md                 single-run feature
   scratch/output/_<feature-slug>/babbage_<run-scope>_<N>.md     run scope supplied
   ```

   Get the filename from `scripts/next-artifact.sh <feature-dir> babbage [run-scope]` rather than counting: N is counted inside the (agent, run) pair, so a second run's numbering does not continue the first (`rules/feature-directory-lifecycle.md`). `scratch/` resolves to the framework repo per `rules/scratch-path-resolution.md`. See format below.

   One exception, named in Edge Cases: a design produced while triaging a backlog candidate is staged outside the feature directory until the candidate is dispatched.

3. **Report the full filename** to the caller, not the directory. The dispatch to the implementer names this file; nothing reaches the implementer by directory adjacency (`rules/dispatch-shape.md`). The orchestrator verifies the file landed per `protocols/post-dispatch-artifact-verify.md` before dispatching against it.

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

## Directives and Reasoning

The implementer reads this file without the conversation that produced it, so what binds has to be separable from the thinking behind it.

- **Directives bind.** The approach chosen, the files to change, the interfaces to conform to, the tests owed. State each directive in the section that owns it. A directive that appears only inside a rationale paragraph is one the implementer can read past, and a directive stated in two sections has two places to go stale.
- **Reasoning explains.** Why this direction over the alternative, what the risk is, what is still open. Reasoning never carries a directive that appears nowhere else.

By section: Affected Files, Interface Contracts, Data Flow, and Test Strategy are directive. Approach, Risks and Edge Cases, and Open Questions are reasoning. One exception: an Open Question that blocks implementation is itself a directive, because the instruction it carries is to stop and ask rather than to guess.

### Code claims carry `path:line`

Every statement this document makes about the existing tree carries its location: `pricing.py:873`, not "the flag is checked in the pricing module." The claim was true when the designer read it and the tree moves on its own, so the citation is what lets the implementer confirm it in one step. An uncited code claim is unverified; a station acting on this document reports it that way rather than repeating it as established (`rules/code-facts-from-the-tree.md`).

This is the authoring half of that rule. The reading half applies here too: a design's own code claims are pointers the designer followed once, and nothing downstream inherits them unchecked.

## Code in Design Documents

Code blocks are for **interface contracts**: function signatures, proto definitions, class interfaces, data shapes. These are the boundaries the implementer must conform to.

Implementation logic is described in **prose** that states what the code must do, what constraints it must satisfy, and why. The implementer derives the function bodies from the description and the codebase, not by transcribing the design document.

A design that contains complete function implementations is doing Lovelace's job. It also hides its own blind spots: a literal code line like `resolve_rate_limit(user_id)` looks complete, but it masks the design question of whether that function's internal behavior is appropriate in the new context.

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

- **Operator-run scripts.** When the change is a batch, remediation, backfill or migration script an operator runs by hand over a large population, read `protocols/operator-script-design.md` before writing. Its progress-reporting and per-user sequencing requirements are directives, stated in Interface Contracts or Data Flow. It does not load ambiently.

- **Backlog triage stages the design outside a feature directory.** A design written for a ranked backlog candidate goes to that pipeline's date directory as `design.md` (`protocols/local/backlog-triage-pipeline.md`, Stage 3), and moves into the feature directory as `babbage_<N>.md` when the candidate is actually dispatched. Three reasons the exception is the right shape rather than a gap to close:

  - **The work may never start.** Triage designs every candidate in parallel, and the queue persists across sessions. A feature directory per candidate would create directories for work that never opens a branch, each one a rename candidate for the briefing's PR reconciliation and each one carrying a feature's archive lifecycle.
  - **The slug is not known yet.** A feature slug anchors to the branch that carries the work (`protocols/local/branch-naming.md`), and no branch exists at triage. Choosing one early either constrains the branch name later or leaves the directory orphaned.
  - **There is no run yet.** The staged file carries no N because numbering is per (agent, run) pair and the run opens at dispatch. N is assigned at promotion by `next-artifact.sh`.

  The promotion is a **move, not a copy**, which is what keeps this compatible with the read-set contract: exactly one path to the design exists at any moment, so an orchestrator naming the file in a dispatch always names a real one. Two copies would leave a station reading the staged design after the feature directory's copy had moved on.
