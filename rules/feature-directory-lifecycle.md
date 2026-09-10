# Feature Directory Lifecycle

Agent output for a feature lives in `scratch/output/_<slug>/`.

## Naming

- Before PR: `_<feature-slug>/` (e.g. `_subscription-expiry-warning/`)
- After PR creation: `_pr-<number>-<feature-slug>/`

When a PR number becomes known, rename the directory to include it. `scripts/local/morning-briefing.sh` enforces this at session start by matching each authored open PR's head branch against existing `_<slug>/` directories on exact slug equality; in-session renames happen whenever a PR is created mid-session. The rename is idempotent.

## One Feature, Several Pull Requests

A feature that ships as several pull requests keeps one directory; a directory per PR leaves every copy partial and none authoritative. The rename reconciliation is a one-to-one match on exact slug equality and cannot express a directory owning several PRs, so:

- **Anchor the directory to one branch.** Give the branch carrying the feature's substance the directory's slug; that PR's number is what the directory takes at the next session start.
- **Record the mapping inside the directory.** Write a file listing each slice, its branch, and its merge position when the decomposition is decided; nothing in the tooling can derive it later.
- **Let satellites stay unmatched.** Their slugs differ by design and the reconciliation skips them. That is the intended outcome, not drift, and not a reason to loosen exact matching to partial, which would rename the directory on whichever satellite PR opened first.

Give satellite branches slugs that do not partially overlap the anchor's, so the branch-alignment check (`rules/local/branch-naming.md`) does not flag them on creation.

## Artifact Numbering

Before incrementing an artifact number (e.g. `friedman_2.md`), list the directory contents; the directory is truth, not memory of prior context. `scripts/next-artifact.sh <feature-dir> <agent> [stage-infix]` prints the next filename deterministically; prefer it over manual counting.

## Stage-Specific Naming

- Mob pipeline: `<agent>_<N>.md` (e.g. `friedman_1.md`)
- Pre-ship review: `<agent>_preship_<N>.md` (e.g. `fagan_preship_1.md`)
- Consolidated pre-ship: `pre-ship-review.md` (always this name, no numbering)

Parallel passes append a letter suffix before the extension (`fagan_preship_1a.md`); the consolidated canonical drops the letter (`fagan_preship_1.md`).
