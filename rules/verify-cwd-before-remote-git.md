# Verify Working Directory Before Remote Git Operations

Before any git operation whose effect depends on which repo it runs against, verify the working directory with `pwd`. This applies to:

- `git push`, including `git push --delete`
- `git branch -m` and `git branch -D`
- Any operation that targets a remote or rewrites the local branch namespace

The Bash tool description says working directory persists between commands. It does, mostly. Across a session with multiple `cd` calls, subagent dispatches, worktree creation and removal, and parallel work in two repos that share branch-name conventions, cwd can end up somewhere unexpected. The failure mode is silent: a `git push` against the wrong repo succeeds when both repos accept the branch ref, and you do not find out until you look at the URL in the push output.

The cost of `pwd` before each gated git operation is one bash call. The cost of pushing to the wrong remote is a recovery pass (delete the orphan ref, restore the local branch state) and the trust hit when the user sees a push to a repo they did not authorize.

## How to apply

Right before any gated git operation, run `pwd` in its own Bash call and confirm the result matches the repo you intend to operate on. Do not rely on cumulative memory of prior `cd` commands.

Cross-check the remote when the operation is push-shaped: `git remote -v` should show the URL you expect.

Same-name branches across multiple repos amplify this hazard. If both `acme/webapp` and `acme/framework` have a branch matching `feature/foo`, none of the standard git error messages will flag the wrong-repo case. Verify cwd explicitly.
