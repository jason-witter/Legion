# Rule-Governed Work Stays on Ruled Surfaces

Route rule-governed work (Bash execution, data fetching and parsing, dispatch composition, artifact writing) to a named Legion agent, a fork, or do it in-agent. Forks inherit the orchestrator's full context, including every loaded rule, and run on the session model; they are the preferred delegation surface for rule-governed and context-heavy work.

General-purpose and Explore subagents do not inherit `rules/`. Handed rule-governed work, they generate command shapes their host would never emit (heredocs, multi-line `python3 -c`, poll loops with command substitution), which trip `hooks/block-chained-commands.sh` and force mid-run approval prompts. Genuinely rule-neutral exploration (broad code search with no command-generation expectation) may still use `Explore` or `general-purpose`.

## Example

Bad, parsing work handed to a rule-free surface:

```
Agent needs to parse fetched PR comments and spawns general-purpose to do it.
The subagent, carrying no rules, writes `python3 - <<'PYEOF' ... PYEOF` and a
`while true; do ... || echo 0; done` poll loop. Both prompt the user mid-run.
```

Do the parsing in-agent under `rules/discrete-operations.md`, or hand it to a fork that inherits the rules.
