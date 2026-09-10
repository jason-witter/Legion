# Scratch Ephemeral Files

Two paths, different owners, different retention.

## scratch/output/_inbox/ — orchestrator writes for the user

User-facing output not tied to an active feature (a one-off reply, a standalone draft, a short-lived paste buffer) goes to `scratch/output/_inbox/`; the archive script ages entries out after 14 days of inactivity. Feature-relevant output goes in the feature directory instead, where it stays findable next to the work and archives with the feature (`rules/feature-directory-lifecycle.md`).

Name inbox files `<YYYY-MM-DD>-<N>-<slug>.md`, N incrementing per file per day (e.g. `2026-07-01-1-refund-reply.md`); list the day's existing entries before choosing N rather than guessing. The date prefix keeps entries ordered and gives the archive script a deterministic sweep date.

Write the file and tell the user its path. Do not also paste the content inline: they copy from the file, so the inline copy is pure duplication and it is the single largest source of reply bloat on paste-artifact turns (`rules/orchestrator-report-brevity.md`). Quote at most the one or two lines they need to make a decision about, and only when a decision is actually pending. The clipboard goes stale while they read and do other things, so auto-copying earns nothing either.

## scratch/tmp/ — agent and hook infrastructure

Agents and hooks write session-scoped state here: dispatch gate state, watchdog alerts, fetch artifacts staged for the agent's own inspection. `scripts/local/archive-scratch-output.sh` sweeps it at every SessionStart, deleting anything untouched for 24 hours. SessionStart also fires for concurrent sessions, so the 24-hour mtime grace is load-bearing but not a guarantee: anything that must survive the next sweep belongs in the harness-provided session scratchpad, which is session-isolated and never swept. `rules/no-inline-script-bodies.md` routes agent-authored scripts there for this reason. Incident detail: `docs/rule-history/artifacts-and-scratch.md`.

User-facing ephemera does not go here either; the sweep can delete it before the user reads it. It belongs in `scratch/output/_inbox/`.

## Why not /tmp/

`scratch/` paths resolve through `rules/scratch-path-resolution.md` and avoid permission issues; system temp directories do neither.
