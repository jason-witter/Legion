# Field Notes: Git Transport and Worktrees

Incident detail relocated from `rules/local/no-worktree-isolation.md` during the 2026-08-03 rules compression. The rule keeps the constraints; this file keeps the stories behind them.

## Follow-up dispatch landed on a concurrent session's feature branch

With two sessions open on one repo, a review-iteration dispatch (correctly carrying no isolation parameter) launched at the orchestrator's working directory, which a concurrent session had parked on an unrelated feature branch carrying two unpushed commits. The agent would have committed onto someone else's unpushed work. The mandatory base-verification instruction in every code-producing dispatch is what caught it; that incident is why the rule makes the instruction mandatory rather than advisory.

## Historical: feature-branch diff leakage

Earlier versions of the worktree rule predated the harness invariant and warned about feature-branch diffs leaking into fresh worktrees. The harness now always grounds `isolation: "worktree"` on `origin/main` HEAD regardless of orchestrator state, so that failure class is no longer possible. The warning was removed rather than carried forward.
