# Pre-Ship Review

Dispatch Fagan and Oppenheimer in parallel against your own branch or PR to surface code and design issues before shipping. Produces a single synthesized report (`pre-ship-review.md`) combining code inspection and design critique findings.

Different from the mob pipeline (where Friedman reviews during implementation and Oppenheimer critiques before implementation) and the PR queue (where Fagan reviews other people's PRs). This protocol is for: "I have my own PR and want deep inspection before merge."

## Prerequisites

- A branch with code changes, or an open PR
- `gh` CLI installed and authenticated
- Fagan and Oppenheimer agents available for dispatch

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `pr_number` | One of these | PR number (resolves repo, branch, and metadata via Grace) |
| `branch` | required | Branch name (Grace resolves to PR if one exists) |
| `repo` | No | `OWNER/REPO` - defaults to current repo context |

## Execution Steps

### Step 0 - Ensure local branch matches PR HEAD

Before dispatching any reviewers, ensure the local checkout matches the PR's current HEAD. Some agents (notably Oppenheimer) read local files for full-file context rather than fetching from GitHub. If the local branch is stale, those agents will review old code while the PR diff shows current code, producing findings against code that no longer exists.

```
git fetch origin <branch>
git checkout <branch>
git reset --hard origin/<branch>
```

This is destructive to local state. If the local branch has unpushed work, stash or branch it first. For pre-ship reviews of your own PRs (the common case), the local branch should have no unpushed work.

### Step 1 - Fetch PR metadata

Dispatch Grace to fetch PR metadata using `protocols/pr-data-fetch.md`. This provides both agents with the PR description, diff stats, CI status, existing review comments, and commit history.

If the input is a branch name with no open PR, fetch the diff against the base branch directly. Oppenheimer and Fagan can still operate on a branch diff without PR metadata, but note the reduced context in their dispatches.

### Step 2 - Determine output directory

`scratch/` resolves to the HopLegion repo per `rules/scratch-path-resolution.md`. Directory naming follows `rules/feature-directory-lifecycle.md`.

- With PR number: `scratch/output/_pr-<number>-<slug>/`
- Without PR number: `scratch/output/_<branch-slug>/`

If a feature directory already exists without the PR prefix (e.g., from a prior mob pipeline), rename it to include the PR number.

Pre-ship review artifacts follow the naming conventions in `protocols/mob-review-output.md`. List the directory before picking artifact numbers.

### Step 3 - Dispatch dual Fagan and dual Oppenheimer in parallel

Four agents run simultaneously as background tasks: two Fagan instances and two Oppenheimer instances. Each pair works independently; convergent findings within a pair are high-signal, and convergent findings across disciplines are highest-signal.

**Fagan A and B** each receive:
- PR identifier (number + repo) or branch name
- Grace's metadata payload
- Task: full code inspection per `protocols/pr-review.md`
- Output path with parallel suffix: `fagan_preship_1a.md` / `fagan_preship_1b.md`

**Oppenheimer A and B** each receive:
- The PR diff and description (or branch diff)
- Grace's metadata payload
- Codebase access for surrounding context
- Task: stress-test the design (structural flaws, missed edge cases, scaling concerns, incorrect abstractions)
- Output path with parallel suffix: `oppenheimer_preship_1a.md` / `oppenheimer_preship_1b.md`

Fagan inspects code quality and correctness. Oppenheimer inspects design and architecture. The dual-pass pattern within each discipline catches findings that a single pass might miss; the cross-discipline overlap catches findings that a single lens might miss.

### Step 4 - Winterbotham consolidation (three passes)

After all four agents complete, dispatch Winterbotham three times:

1. **Same-agent: Fagan pair** (background) — Merge `fagan_preship_1a.md` + `fagan_preship_1b.md` into `fagan_preship_1.md`.
2. **Same-agent: Oppenheimer pair** (background, parallel with #1) — Merge `oppenheimer_preship_1a.md` + `oppenheimer_preship_1b.md` into `oppenheimer_preship_1.md`.
3. **Cross-discipline** (after #1 and #2 complete) — Merge `fagan_preship_1.md` + `oppenheimer_preship_1.md` into `pre-ship-review.md`.

Winterbotham produces the final artifact. The orchestrator does not synthesize. See the cross-discipline consolidation section in the Winterbotham agent definition for the merge procedure and output format.

Present the result to the user in chat. The file is the record; the chat delivery is the alert.

### Step 5 - Handoff (conditional)

If findings require code changes, offer to produce a handoff document for the fixes. This follows the deployment-specific handoff protocol if one exists (`protocols/local/coder-handoff.md`), scoped to the findings from Steps 3-4.

The handoff is not automatic. The user decides whether to fix locally, dispatch a mob iteration, or hand off to a remote environment.

## Edge Cases

- **No PR exists for the branch**: Fagan and Oppenheimer operate on the branch diff against main. Note reduced context (no PR description, no existing reviews) in the synthesis.
- **PR already has reviews**: Grace fetches existing review comments. Both agents account for already-raised issues per their standard protocols.
- **One agent fails**: Surface the failure. Present the surviving agent's report as the sole analysis. Do not re-dispatch automatically.
- **No findings**: Report that both agents cleared the PR. This is a positive signal worth stating explicitly.
- **Large diff (1000+ lines)**: Note the size in the synthesis. Both agents handle large diffs per their own protocols, but flag that a diff this large may warrant splitting.
