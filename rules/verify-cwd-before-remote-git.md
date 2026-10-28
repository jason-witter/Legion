# Verify Working Directory Before Remote Git Operations

Right before any git operation whose effect depends on which repo it runs against, run `pwd` in its own Bash call and confirm it matches the intended repo. Do not rely on memory of prior `cd` calls. For push-shaped operations, also cross-check with `git remote -v`.

This applies to:

- `git push`, including `git push --delete`
- `git branch -m` and `git branch -D`
- Any operation that targets a remote or rewrites the local branch namespace

A wrong-repo push fails silently: it succeeds when both repos accept the branch ref.
