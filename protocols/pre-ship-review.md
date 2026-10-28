# Pre-Ship Review

Dispatch Fagan and Oppenheimer in parallel against your own branch or PR to surface code and design issues before shipping. Produces a single synthesized report (`pre-ship-review.md`) combining code inspection and design critique findings.

Different from the mob pipeline (where Friedman reviews during implementation and Oppenheimer critiques before implementation) and the PR queue (where Fagan reviews other people's PRs). This protocol is for: "I have my own PR and want deep inspection before merge."

All four reports tier their findings per `protocols/finding-disposition.md`, and the Step 4 consolidations merge on its tier order. A Blocking finding in `pre-ship-review.md` means the change should not ship as written; Comment and Noted findings do not gate the ship. This protocol does not restate the tiers or the gate.

## Verdict

`pre-ship-review.md` opens with a verdict. Three are available, and which one applies follows from the tiers in the consolidated report:

- **ship** — no Blocking findings. Comment findings are the author's discretion and do not hold the ship.
- **fix then ship** — Blocking findings that are local. Each names a defect fixable in place, and the approach the change takes survives the fix.
- **rethink** — Blocking findings that are structural. The approach, interface, or decomposition is what has to change, so fixing in place would carry the flaw forward.

The Blocking tier alone decides whether the verdict is "ship". Only the shape of the Blocking findings separates "fix then ship" from "rethink", and that judgment is the consolidation's. This is the pre-ship instance of the recommendation rule in `protocols/finding-disposition.md`, which owns the tiers.

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

### Step 2 - Determine output directory and run scope

`scratch/` resolves to the framework repo per `rules/scratch-path-resolution.md`. Directory naming follows `rules/feature-directory-lifecycle.md`.

- With PR number: `scratch/output/_pr-<number>-<slug>/`
- Without PR number: `scratch/output/_<branch-slug>/`

If a feature directory already exists without the PR prefix (e.g., from a prior mob pipeline), rename it to include the PR number.

**The run scope is `preship`.** A pre-ship review is one pass against one surface, so it is a run under `rules/feature-directory-lifecycle.md` and `preship` is its scope in the infix slot: `fagan_preship_1a.md`, `oppenheimer_preship_1.md`. Because currency is per `(agent, run)`, this run's numbering needs no coordination with a mob run in the same directory. `fagan_preship_1` is current for this run whatever the mob's own Fagan or Friedman numbering reached.

```
scripts/next-artifact.sh <feature-dir> fagan preship
```

A fix round after a "fix then ship" verdict stays inside this run and increments N (`fagan_preship_2a.md`), per the boundary test. A pre-ship pass re-opened after a "ship" verdict is a **new** run and takes a scope naming the surface it examines rather than `preship` again, so the earlier clearance stays derivable rather than being marked superseded by a pass that never looked at it.

Per-artifact content and format follow `protocols/mob-review-output.md`.

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

Winterbotham produces the final artifact, with the verdict taken from the Verdict section above and the sectioning from `protocols/finding-disposition.md`. The consolidated report is unnumbered and always carries the run's current verdict; a fix round's consolidation replaces it, and the per-agent chain (`fagan_preship_1.md`, `fagan_preship_2.md`) is where the history stays. It takes a run scope in its name when the feature has more than one pre-ship run; see Edge Cases. The orchestrator does not synthesize. See the cross-discipline consolidation section in the Winterbotham agent definition for the merge procedure and output format.

Present the result to the user in chat. The file is the record; the chat delivery is the alert.

### Step 5 - Bridge (conditional)

If findings require code changes and a fix iteration runs, the work leaves through the deployment's bridge protocol if one exists (`protocols/local/coder-handoff.md`): the squash commit body carries the non-diff-visible judgment scoped to the findings from Steps 3-4, plus the PR description and any environment setup commands. No handoff document is produced.

The fix is not automatic. The user decides whether to fix locally, dispatch a mob iteration, or hand off to a remote environment.

When Steps 3 and 4 re-run after a fix round, each re-dispatched agent is a verification pass and carries the discharge obligation in `protocols/finding-disposition.md`. Each discharges its own chain: the Fagan pass at N is dispatched with `fagan_preship_<N-1>.md`, the Oppenheimer pass with `oppenheimer_preship_<N-1>.md`, and neither is dispatched with the other's report or with the consolidated one. The obligation sits on top of a full pass and does not narrow it to the prior findings.

## Edge Cases

- **No PR exists for the branch**: Fagan and Oppenheimer operate on the branch diff against main. Note reduced context (no PR description, no existing reviews) in the synthesis.
- **PR already has reviews**: Grace fetches existing review comments. Both agents account for already-raised issues per their standard protocols.
- **One agent fails**: Surface the failure. Present the surviving agent's report as the sole analysis. Do not re-dispatch automatically.
- **No actionable findings**: no Blocking and no Comment findings in `pre-ship-review.md`. The verdict is "ship" and both agents cleared the PR; this is a positive signal worth stating explicitly. Entries in the Recorded section do not change that verdict and are not reported as findings.
- **A second pre-ship run in the same directory**: the consolidated report takes the run scope in its name, `pre-ship-review-<run>.md`, so two surfaces hold two verdicts (`rules/feature-directory-lifecycle.md`). The unscoped name stays correct while a feature has one pre-ship run. Within a run, overwriting is still right: the consolidated verdict is current state rather than a log, and the per-agent chain holds the history.

  This clause previously said the name was fixed at one and told the orchestrator to surface the collision. That was written before the rule layer answered the question, and the answer was the scoped name.
- **Large diff (1000+ lines)**: Note the size in the synthesis. Both agents handle large diffs per their own protocols, but flag that a diff this large may warrant splitting.
