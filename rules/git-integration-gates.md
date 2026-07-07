# Git Integration Gates

These require explicit user approval: `git push`, `git merge` into shared branches, history-rewriting `git rebase`, and force operations.

Everything local is ungated — edits, staging, commits, branches, stash.

## No Remote Path Flags

No `git -C <path>`; `cd` in one call, then the git command in the next. Enforced by `hooks/block-git-c-flag.sh`.
