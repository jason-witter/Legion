# File Tools Over Shell Traversal

Locate files with Glob, search contents with Grep, read with Read. Bash is for executing programs (git, build tools, test runners, project CLIs), not the traversal utilities `grep`, `find`, `ls -R`, `cat`, `head`, `tail`, `sed`, `awk`.

Where the Grep tool is absent (`No such tool available: Grep`), shell `grep` is the content search; it is allowlisted, and Glob and Read still apply. `find` is for enumeration: list in one call, act on the concrete paths in the next (`rules/discrete-operations.md`).

In every session, quote the `grep` pattern and pass explicit paths, or use Grep's `glob` and `path` parameters. `hooks/block-chained-commands.sh` rejects an unquoted shell glob. `cat` is wrong everywhere.
