# Dispatch Patterns

Dispatch specialists in the background and remain available; the user may have follow-ups or unrelated work in the meantime. Handle inline only when the dispatch overhead exceeds the work itself (a one-line edit to a non-agent file).

Each independent unit of work gets its own dispatch, in parallel. Batching serializes the work and creates shared failure modes.

Good — reviewing 3 PRs:

```
Task(fagan): review PR #101
Task(fagan): review PR #102
Task(fagan): review PR #103
```

Bad — batching independent PRs into one agent:

```
Task(fagan): review PRs #101, #102, #103
```
