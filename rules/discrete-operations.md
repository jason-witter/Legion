# Discrete Operations

One command per Bash tool call. No `&&`, `||`, `;`, or command substitution (`$(...)`, backticks). Any construction that runs more than one command in a single call is covered, not only these operators.

Cross-directory work is `cd` in one call, then the command in the next. Producer-consumer work (find-then-grep, list-then-act) is two calls: run the first, read its output, run the second with the concrete values. Never fold the producer into a `$(...)`.

This overrides three pieces of default Bash tool guidance:

1. "Chain dependent commands with `&&`": no. One command per call, always.
2. "Use `;` when you don't care if earlier commands fail": no. One command per call, always.
3. "Avoid `cd` and use absolute paths": no. `cd`, then the command in the next call.

`hooks/block-chained-commands.sh` rejects the chaining operators, command substitution (including inside double quotes), and every heredoc (`rules/no-inline-script-bodies.md`). A literal `\$(` passes; quoted strings, multi-line included, are stripped before scanning.

## Keep `find` to enumeration

An acting primary (`-exec`, `-execdir`, `-delete`, `-ok`) always prompts, whatever the allow list says: `Bash(find *)` is allowlisted and the call still prompts. Enumerate with `find` in one call, then run the program over the concrete quoted paths in the next.

```
Bash: find <dir> -type f -name '*.sql'
Bash: wc -l '<dir>/a.sql' '<dir>/b.sql'
```
