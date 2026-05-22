# Feature Directory Lifecycle

Agent output for a feature lives in `scratch/output/_<slug>/`. The directory name evolves as the feature progresses:

## Naming

- **Before PR**: `_<feature-slug>/` (e.g., `_gift-card-forfeiture-warning/`)
- **After PR creation**: `_pr-<number>-<feature-slug>/` (e.g., `_pr-277332-gift-card-forfeiture-warning/`)

When a PR number becomes known for an existing feature directory, rename the directory to include the PR number. The morning briefing script (`scripts/local/morning-briefing.sh`) enforces this categorically at session start by matching each authored open PR's head branch against existing `_<slug>/` directories. In-session renames may still happen during pre-ship review, Denniston digest, or any post-PR interaction when a PR is created mid-session. The rename is idempotent; if the directory already has the PR prefix, no action needed.

## Artifact Numbering

Before incrementing an artifact number (e.g., `friedman_2.md`), list the directory contents. Do not infer the next number from memory or prior conversation context. Memory is stale; the directory is truth.

## Stage-Specific Naming

Artifacts from different pipeline stages use an infix to distinguish them:

- **Mob pipeline**: `<agent>_<N>.md` (e.g., `friedman_1.md`, `oppenheimer_1.md`)
- **Pre-ship review**: `<agent>_preship_<N>.md` (e.g., `fagan_preship_1.md`, `oppenheimer_preship_1.md`)
- **Consolidated pre-ship**: `pre-ship-review.md` (always this name, no numbering)

Parallel passes append a letter suffix before the extension: `fagan_preship_1a.md`, `fagan_preship_1b.md`. The consolidated canonical drops the letter: `fagan_preship_1.md`.
