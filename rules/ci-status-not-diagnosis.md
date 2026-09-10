# CI Status, Not CI Diagnosis

Record a failing check as a fact: check name, conclusion, and the item it belongs to. The user decides whether a failure is worth investigating.

Diagnosis is a separate, user-initiated task. Fetching build logs, following triggered-pipeline drill-downs, and invoking the CI system's CLI to locate the failing test all belong to that task, not to a review, digest, or briefing pass. Those passes report the check state and move on.

## Applies to

Any agent or protocol reporting on external work: PR review, feedback digest, session briefing, queue triage. Also the orchestrator when it summarizes a queue inline.

## Examples

Good, the check state is a fact in the report:

```
## CI Status
- ci/build: FAILURE
- check-required-reviews: SUCCESS
```

Bad, the pass turns into an investigation:

```
## CI Status
- ci/build: FAILURE. Followed the failed trigger to lint-python build 186924 and
  pulled the job log; the failure is a line-length violation at
  payments/lib/job.py:88.
```

The bad example spends the pass's budget on work the user did not ask for, prompts for CLI permissions mid-run, and buries the fact the user wanted (the build is red) inside a diagnosis they may discard.

## Rationale

A red build is frequently unrelated to the change under review: a flaky test, a base-branch regression, an unrelated pipeline. Diagnosing every one costs a full drill-down per failure and produces findings that get thrown away. When the user wants the cause, they ask, and the diagnosis gets a dispatch of its own.
