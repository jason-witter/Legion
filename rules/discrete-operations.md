# Discrete Operations

One command per Bash tool call. No `&&`, `||`, `;`, or command substitution (`$(...)`, backticks).

Cross-directory work uses `cd` in one call, then the command in the next.

Multi-step work that feeds one command's output into another (find-then-grep,
list-then-act) is two calls: run the first, read its output, then run the second with
the concrete values. Do not fold the producer into a `$(...)` so the whole thing reads
as "one command." The inner command still runs unseen.

This rule overrides three pieces of default Bash tool guidance:

1. "Chain dependent commands with `&&`" — no. One command per call, always.
2. "Use `;` when you don't care if earlier commands fail" — no. One command per call, always.
3. "Avoid `cd` and use absolute paths" — no. Use `cd` then run the command in the next call.

Chained commands and command substitution both bypass permission pattern matching:
`Bash(git push*)` won't match `cd /repo && git push`, and a `$(...)` runs its inner
command with no pattern match at all. The enumerated operators are not the point; any
construction that runs more than one command in a single call is.

`hooks/block-chained-commands.sh` rejects the chaining operators, command substitution
(`$(...)` and backticks, including inside double quotes where it still executes), and
heredocs feeding `git commit`. Escaped forms stay usable: find's `-exec ... \;`
terminator and a literal `\$(` pass. Quoted strings are stripped before scanning,
including strings that span multiple lines.
