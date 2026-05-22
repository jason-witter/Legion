# Git Integration Gates

These require explicit user approval: `git push`, `git merge` into shared branches, history-rewriting `git rebase`, and force operations.

Everything local is ungated — edits, staging, commits, branches, stash.

## No Remote Path Flags

No `git -C <path>`. To run git in a different directory: `cd` in one call, then run the git command in the next. `-C` bypasses permission pattern matching — `Bash(git push*)` won't match `git -C /repo push`.

Enforced by `hooks/block-git-c-flag.sh` — the tool call will be rejected.
