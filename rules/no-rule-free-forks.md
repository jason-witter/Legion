# Rule-Governed Work Stays on Ruled Surfaces

Route rule-governed work to a named Legion agent, a fork, or do it in-agent. Rule-governed work is anything the framework's rules already shape: Bash execution, data fetching and parsing, dispatch composition, artifact writing.

Forks inherit the orchestrator's full context, including every loaded rule, and run on the session model. They are the preferred delegation surface for rule-governed and context-heavy work (audits, multi-file analysis, edits that depend on session judgment).

General-purpose and Explore subagents do not inherit `rules/`. Handed rule-governed work, they generate command shapes their host would never emit (heredocs, multi-line `python3 -c`, poll loops with command substitution), which trip `hooks/block-chained-commands.sh` and force mid-run approval prompts. The constraint binds those rule-free surfaces only; genuinely rule-neutral exploration (broad code search with no command-generation expectation) may still use `Explore` or `general-purpose`.

## Example

Bad, parsing work handed to a rule-free surface:

```
Agent needs to parse fetched PR comments and spawns general-purpose to do it.
The subagent, carrying no rules, writes `python3 - <<'PYEOF' ... PYEOF` and a
`while true; do ... || echo 0; done` poll loop. Both prompt the user mid-run.
```

The subagent is not doing anything malicious; it never received the Bash discipline its host runs under. Do the parsing in-agent under `rules/discrete-operations.md`, or hand it to a fork that inherits the rules.
