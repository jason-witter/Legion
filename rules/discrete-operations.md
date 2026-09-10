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
heredocs feeding `git commit`. A literal `\$(` passes. Quoted strings are stripped
before scanning, including strings that span multiple lines.

## An acting `find` always prompts, whatever the allow list says

Keep `find` to enumeration. Any primary that *acts* rather than matches (`-exec`,
`-execdir`, `-delete`, `-ok`) makes the harness refuse to auto-allow the call, and it
refuses independently of the allow list: `Bash(find *)` is allowlisted and the call
still prompts. So an acting `find` is exactly the mid-run stall this rule exists to
prevent, and it is worse inside a subagent, where the prompt surfaces with the agent's
name on it and the user has no context for what it is doing.

`-delete` is the one that slips through, because it reads as a flag on a search rather
than as running a program. It is in the same class as `-exec` and prompts the same way.

Two calls instead: `find` to enumerate, then the program over the concrete quoted paths
it returned. `wc` and `rm`, like `find`, are allowlisted, so the enumerate-then-act pair
runs unprompted end to end.

```
Bash: find <dir> -type f -name '*.sql'
Bash: wc -l '<dir>/a.sql' '<dir>/b.sql' '<dir>/c.sql'

Bash: find <dir> -name 'page-*.yml'
Bash: rm -f '<dir>/page-1.yml' '<dir>/page-2.yml'
```

Bad, one call that always prompts:

```
Bash: find <dir> -type f -name '*.sql' -exec wc -l {} \;
Bash: find <dir> -name 'page-*.yml' -delete
```
