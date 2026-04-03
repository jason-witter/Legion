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

### Step 1 - Fetch PR metadata

Dispatch Grace to fetch PR metadata using `protocols/pr-data-fetch.md`. This provides both agents with the PR description, diff stats, CI status, existing review comments, and commit history.

If the input is a branch name with no open PR, fetch the diff against the base branch directly. Oppenheimer and Fagan can still operate on a branch diff without PR metadata, but note the reduced context in their dispatches.

### Step 2 - Determine output directory

Derive the output path per `protocols/local/scratch-output-conventions.md`:

- With PR number: `scratch/output/YYYY-MM-DD/pr-<number>-<slug>/`
- Without PR number: `scratch/output/YYYY-MM-DD/<branch-slug>/`

### Step 3 - Dispatch Fagan and Oppenheimer in parallel

Both agents run simultaneously as background tasks. Their raw output is working material - the orchestrator synthesizes it into the final artifact.

**Fagan** receives:
- PR identifier (number + repo) or branch name
- Grace's metadata payload
- Task: full code inspection per `protocols/pr-review.md`

**Oppenheimer** receives:
- The PR diff and description (or branch diff)
- Grace's metadata payload
- Codebase access for surrounding context
- Task: stress-test the design - structural flaws, missed edge cases, scaling concerns, incorrect abstractions

Fagan inspects code quality and correctness. Oppenheimer inspects design and architecture. The overlap is intentional - convergent findings from independent lenses are high-signal.

### Step 4 - Synthesize and write pre-ship-review.md

After both agents complete, the orchestrator reads both reports and produces a single `pre-ship-review.md` in the task directory. This is the durable artifact - the individual agent outputs are working material.

The synthesis:

1. **Identify convergent findings** - issues flagged by both agents carry extra weight
2. **Deduplicate** - where both agents flag the same issue, present it once with both perspectives noted
3. **Categorize** - group findings by severity (blocker / major / minor) with the verdict up front: ship, fix then ship, or rethink
4. **Organize** - code inspection findings and design critique findings side by side, not in separate sections

Present the synthesis to the user in chat as well. The file is the record; the chat delivery is the alert.

### Step 5 - Handoff (conditional)

If findings require code changes, offer to produce a handoff document for the fixes. This follows the deployment-specific handoff protocol if one exists (`protocols/local/coder-handoff.md`), scoped to the findings from Steps 3-4.

The handoff is not automatic. The user decides whether to fix locally, dispatch a mob iteration, or hand off to a remote environment.

## Edge Cases

- **No PR exists for the branch**: Fagan and Oppenheimer operate on the branch diff against main. Note reduced context (no PR description, no existing reviews) in the synthesis.
- **PR already has reviews**: Grace fetches existing review comments. Both agents account for already-raised issues per their standard protocols.
- **One agent fails**: Surface the failure. Present the surviving agent's report as the sole analysis. Do not re-dispatch automatically.
- **No findings**: Report that both agents cleared the PR. This is a positive signal worth stating explicitly.
- **Large diff (1000+ lines)**: Note the size in the synthesis. Both agents handle large diffs per their own protocols, but flag that a diff this large may warrant splitting.
