# CI Status, Not CI Diagnosis

Record a failing check as a fact: check name, conclusion, and the item it belongs to. The user decides whether a failure is worth investigating.

Diagnosis (fetching build logs, following triggered-pipeline drill-downs, running the CI system's CLI to find the failing test) is a separate, user-initiated task, not part of a review, digest, or briefing pass.

Applies to any agent or protocol reporting on external work (PR review, feedback digest, session briefing, queue triage), and to the orchestrator summarizing a queue inline.

Good:

```
- ci/build: FAILURE
```

Bad:

```
- ci/build: FAILURE. Pulled the job log; line-length violation at job.py:88.
```
