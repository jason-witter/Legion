# Branch Create Protocol

Create feature branches for orchestrator-driven work (fix-ups, lightweight tasks, branches the orchestrator stages before dispatching code-producing agents).

For mob and other code-producing dispatches that use `isolation: "worktree"`, the harness creates the branch as part of worktree setup. See `rules/local/no-worktree-isolation.md`. This protocol covers the cases where the orchestrator creates the branch directly.

## Invariants

1. **Base on current `origin/main`.** New work branches must reflect remote HEAD, not whatever the local main happens to be at. Stale bases produce merge conflicts and reviewers second-guessing the diff. Run `git fetch origin` immediately before creating the branch; the harness uses tracking refs, not local main.

2. **Align with the existing feature directory slug, if one exists.** When `scratch/output/_<slug>/` (or `_pr-<number>-<slug>/`) exists for the work, the branch slug must match. Drift orphans the directory and breaks the morning briefing's automatic rename. Deployment-specific rules (`rules/local/branch-naming.md`) define the exact prefix and separator conventions, and may enforce the alignment with a hook.

3. **Push is gated.** `git push` requires explicit user approval per `rules/git-integration-gates.md`. The protocol does not push on its own.

## Verification

After creating the branch:

```
git log --oneline -3
```

The tip should match `origin/main` HEAD (zero commits ahead). If commits from another feature branch appear, the base is wrong; reset or recreate before continuing.

## Naming

When a feature directory exists, derive the branch slug from the directory name (with the deployment's separator convention applied). When no directory exists, derive a short, descriptive slug from the task. Hand-rolled shell pipelines for slug derivation are unnecessary; pick a name that reads cleanly.

The deployment's prefix convention (e.g., `<initials>/` in `rules/local/branch-naming.md`) determines the leading segment.

## Post-Merge Cleanup

After the PR merges, delete the local and remote branches. Branches are ephemeral transport; they do not need to live past the merge.

```
git branch -d <branch-name>
git push origin --delete <branch-name>
```

The remote delete is gated per `rules/git-integration-gates.md`.
