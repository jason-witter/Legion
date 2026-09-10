# File Tools Over Shell Traversal

Locate files with Glob, search contents with Grep, and read files with Read. Reserve Bash for executing programs: git, build tools, test runners, project CLIs. Shell traversal utilities (`grep`, `find`, `ls -R`, `cat`, `head`, `tail`, `sed`, `awk`) duplicate the file tools and, under a restrictive permission setup, trip prompts that stall the run; the file tools never prompt and return structured results.

## Sessions without the Grep tool

Some sessions do not provide the Grep tool (calling it returns `No such tool available: Grep`). There the preference inverts for content search: shell `grep` is the sanctioned path, and the rest of the rule (Glob for discovery, Read for reading) applies unchanged. If `Bash(grep:*)` is also not allowlisted in that session shape, every content search prompts and no path avoids it; surface the gap to the user so the deployment allowlists it, rather than absorbing a prompt per search.

## Where the Grep tool exists

Shell `grep` is the common violation: unallowlisted, every invocation prompts, while `Bash(find:*)` is allowlisted. Where the shell is genuinely required, `find` is the escape hatch: enumerate in one call, then act on concrete paths in the next (`rules/discrete-operations.md` forbids folding the producer into a `$(...)`, and forbids `find -exec`, which the harness prompts on regardless of the allow list).

Never pass an unquoted shell glob to `grep`, in either session shape: `grep -n 'pattern' dir/*.md` expands to a multi-file argument list and prompts regardless of allow rules. Quote the pattern and pass explicit paths, or use the Grep tool's `glob` and `path` parameters. `hooks/block-chained-commands.sh` rejects the unquoted form mechanically.

## Examples

Good, locating and reading with the file tools:

```
Glob: **/reconcile_*.py
Grep: "def reap_stale" (path: app/workflows/)
Read: app/workflows/reconcile_sweeper.py
```

Bad, shell traversal for the same work (in a session without the Grep tool, the first line becomes the correct approach; the `cat` and unquoted-glob lines stay wrong in every session):

```
Bash: grep -rn 'def reap_stale' app/           # prompts, grep is not allowlisted
Bash: grep -n 'def reap_stale' app/*.py        # prompts, and the glob expands
Bash: cat app/workflows/reconcile_sweeper.py
```
