# Rule history: no-inline-script-bodies

Empirical findings that motivated the rule, moved here from the rule body during the 2026-08-03 compression pass. The constraints they produced live in `rules/no-inline-script-bodies.md`; this file preserves the evidence.

## The concurrent-SessionStart discovery

`scripts/local/archive-scratch-output.sh` wipes `scratch/tmp/` at SessionStart, and SessionStart fires on compaction and on every new session, including a concurrent one. A second session opened while an agent was mid-run deleted that agent's scripts underneath it: a long-running implementation agent lost its verification scripts partway through. That incident is why agent-authored scripts go to the harness session scratchpad (session-scoped, isolated) rather than `scratch/tmp/`, and why the sweep later gained a 24-hour mtime grace (see `rules/scratch-tmp.md`).

## Chained -m flags for long commit bodies

An earlier revision of the commit-message rule implied building long bodies by chaining `-m` flags. In practice a nine-paragraph body became nine `-m` flags on one line, and the user was asked to approve a wall of prose in a permission prompt with no way to read or edit it. That cost, paid on every substantial commit, is why the rule moved to `git commit -F <file>` for anything longer than a title plus one short paragraph.
