# Rule-Governed Work Stays on Ruled Surfaces

Route rule-governed work (Bash execution, data fetching and parsing, dispatch composition) to a surface that loads `rules/`: a named Legion agent, a fork, a general-purpose subagent, or in-agent. A fork inherits the full context and suits context-heavy work; a general-purpose agent starts lean and suits narrow, self-contained units. Artifact-producing work goes to a named agent (`rules/artifact-on-disk.md`).

The built-in Explore and Plan agents, and any agent with `omitClaudeMd`, do not load `rules/`. Handed rule-governed work, they emit command shapes the rules forbid (heredocs, multi-line `python3 -c`, poll loops) and force mid-run approval prompts. Use them only for rule-neutral exploration: broad code search with no command generation.
