# Verify Working Directory Before Remote Git Operations

Before any git operation whose effect depends on which repo it runs against, verify the working directory with `pwd`. This applies to:

- `git push`, including `git push --delete`
- `git branch -m` and `git branch -D`
- Any operation that targets a remote or rewrites the local branch namespace

Across a session with `cd` calls, subagent dispatches, and worktree churn, cwd can end up somewhere unexpected, and the failure is silent: a push against the wrong repo succeeds when both repos accept the branch ref.

## How to apply

Right before any gated git operation, run `pwd` in its own Bash call and confirm the result matches the intended repo; do not rely on cumulative memory of prior `cd` commands. When the operation is push-shaped, cross-check with `git remote -v`. Same-name branches across multiple repos amplify the hazard; no standard git error flags the wrong-repo case.
