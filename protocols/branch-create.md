# Branch Create Protocol

Create feature branches for orchestrator-driven work (fix-ups, lightweight tasks, branches the orchestrator stages before dispatching code-producing agents).

For mob and other code-producing dispatches that use `isolation: "worktree"`, the harness creates the branch as part of worktree setup. See `protocols/local/worktree-transport.md`. This protocol covers the cases where the orchestrator creates the branch directly.

## Invariants

1. **Base on current `origin/main`.** New work branches must reflect remote HEAD, not whatever the local main happens to be at. Stale bases produce merge conflicts and reviewers second-guessing the diff. Run `git fetch origin` immediately before creating the branch; the harness uses tracking refs, not local main.

2. **Align with the existing feature directory slug, if one exists.** When `scratch/output/_<slug>/` (or `_pr-<number>-<slug>/`) exists for the work, the branch slug must match. Drift orphans the directory and breaks the morning briefing's automatic rename. The deployment's branch-naming protocol (`protocols/local/branch-naming.md` here) defines the exact prefix and separator conventions, what to do when a user-proposed name breaks alignment, and any hook that enforces it. It does not load ambiently: read it before creating the branch.

3. **Push is gated.** `git push` requires explicit user approval per `rules/git-integration-gates.md`. The protocol does not push on its own.

## Verification

After creating the branch:

```
git log --oneline -3
```

The tip should match `origin/main` HEAD (zero commits ahead). If commits from another feature branch appear, the base is wrong; reset or recreate before continuing.

## Naming

When a feature directory exists, derive the branch slug from the directory name (with the deployment's separator convention applied). When no directory exists, derive a short, descriptive slug from the task. Hand-rolled shell pipelines for slug derivation are unnecessary; pick a name that reads cleanly.

The deployment's prefix convention (e.g., `<initials>/` in `protocols/local/branch-naming.md`) determines the leading segment.

## One Feature, Several Pull Requests

A feature that ships as several pull requests keeps one feature directory. Where the deployment renames feature directories to carry a PR number by matching a PR's head branch to the directory slug, that match is one-to-one on exact slug equality and cannot express a directory owning several PRs.

- **Anchor the directory to one branch.** Give the branch carrying the feature's substance the directory's slug; that PR's number is the one the directory takes.
- **Record the mapping inside the directory.** Write a file listing each slice, its branch, and its merge position when the decomposition is decided.
- **Let satellites stay unmatched.** Their slugs differ by design and the rename skips them. Do not loosen exact matching to partial.

Give satellite branches slugs that do not partially overlap the anchor's, so the deployment's branch-alignment check (Invariant 2) does not flag them on creation.

## Post-Merge Cleanup

After the PR merges, delete the local and remote branches. Branches are ephemeral transport; they do not need to live past the merge.

The feature directory is different: if work continues against it past the merge, it needs a hold before the deployment's archive process moves it. Read the deployment's archive protocol (`protocols/local/archive-scratch-output.md` here) at the merge.

```
git branch -d <branch-name>
git push origin --delete <branch-name>
```

The remote delete is gated per `rules/git-integration-gates.md`.
