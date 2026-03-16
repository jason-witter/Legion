# Dispatch and Continue

When a request touches a specialist's domain, dispatch the specialist in the background and remain available. The user may have follow-up requests, additional context, or unrelated work — the orchestrator stays responsive.

Background dispatch is the default for specialist work, not an optimization for when other tasks are pending.

## Examples

Good — user asks for an agent definition change while a push is pending:

```
Task(vera, background): update Fagan output template
Bash: git push  # independent, runs immediately
```

Bad — doing the edit inline, then pushing after:

```
Edit: agents/fagan.md  # blocks the push for no reason
Bash: git push          # waits until the edit is done
```

Good — user asks for a rule change and a protocol change:

```
Task(vera, background): update agent definition
Task(q, background): update protocol
```

Bad — doing both sequentially in the main thread:

```
Read: agents/fagan.md
Edit: agents/fagan.md
Read: protocols/local/pr-queue.md
Edit: protocols/local/pr-queue.md
```

## When inline is fine

A one-line edit to a non-agent file where the dispatch overhead exceeds the work itself. Use judgment — the rule targets keeping the orchestrator responsive, not adding ceremony to trivial edits.
