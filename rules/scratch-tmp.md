# Scratch Ephemeral Files

Never use system temp directories. `scratch/` paths resolve per `rules/scratch-path-resolution.md`.

## scratch/output/_inbox/: user-facing output

User-facing output not tied to an active feature goes here; the archive script ages entries out 14 days after the date in the filename. Feature-relevant output goes in the feature directory (`rules/feature-directory-lifecycle.md`).

Name files `<YYYY-MM-DD>-<N>-<slug>.md`, N incrementing per file per day; list the day's entries before choosing N.

Write the file and tell the user its path. The path is the whole handoff: no inline paste of the content, no clipboard copy. Quote at most the one or two lines a pending decision needs.

## scratch/tmp/: agent and hook state

Session-scoped state for agents and hooks. Every SessionStart sweeps anything untouched for 24 hours, and SessionStart fires for concurrent sessions too, so the grace is not a guarantee: anything that must survive belongs in the harness session scratchpad. User-facing ephemera goes to the inbox, not here.
