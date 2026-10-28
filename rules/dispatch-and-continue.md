# Dispatch Patterns

Dispatch specialists in the background and remain available. Handle inline only when the dispatch overhead exceeds the work itself (a one-line edit to a non-agent file).

Each independent unit of work gets its own dispatch, in parallel. Do not batch.

```
Good: Task(fagan): review PR #101
      Task(fagan): review PR #102
Bad:  Task(fagan): review PRs #101, #102
```

## A spawned helper returns; it cannot message its spawner

A helper's result reaches its spawner only as the helper's final message. A subagent thread holds no address for its spawner and no `ListAgents`, so it cannot `SendMessage` it; only the orchestrator holds reachable addresses.

- Instruct a helper to return its findings, not send them.
- A result that must survive the parent goes on disk, with the path named in the return.

Prefer routing a second unit of work back through the orchestrator (`protocols/mob-pipeline.md`) over nesting a helper. Nesting is not forbidden.
