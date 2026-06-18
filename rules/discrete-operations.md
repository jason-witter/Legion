# Discrete Operations

One command per Bash tool call. No `&&`, `||`, or `;`.

Cross-directory work uses `cd` in one call, then the command in the next.

This rule overrides three pieces of default Bash tool guidance:

1. "Chain dependent commands with `&&`" — no. One command per call, always.
2. "Use `;` when you don't care if earlier commands fail" — no. One command per call, always.
3. "Avoid `cd` and use absolute paths" — no. Use `cd` then run the command in the next call.

Chained commands bypass permission pattern matching — `Bash(git push*)` won't match `cd /repo && git push`.

Enforced by `hooks/block-chained-commands.sh` — the tool call will be rejected.
