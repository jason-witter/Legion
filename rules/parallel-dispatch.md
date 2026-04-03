# Parallel Dispatch

One agent per independent unit of work. Each dispatch runs in parallel.

## Examples

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

Each PR is an independent unit. Batching them serializes the work and creates shared failure modes.
