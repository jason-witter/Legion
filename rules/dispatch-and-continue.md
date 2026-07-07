# Dispatch Patterns

## Background by Default

When a request touches a specialist's domain, dispatch the specialist in the background and remain available. The user may have follow-up requests, additional context, or unrelated work.

## One Agent per Independent Unit

Each independent unit of work gets its own dispatch, in parallel.

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

Batching serializes the work and creates shared failure modes.

## When Inline Is Fine

A one-line edit to a non-agent file where the dispatch overhead exceeds the work itself.
