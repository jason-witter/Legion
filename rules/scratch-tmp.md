# Scratch Ephemeral Files

Two paths, different owners, different retention.

## scratch/output/_inbox/ — orchestrator writes for the user

When you produce user-facing output not tied to an active feature (a one-off reply, a standalone draft, a quick script, a short-lived paste buffer), write it to `scratch/output/_inbox/`. The archive script applies its 14-day inactivity policy to the directory, so forgotten files age into the archive rather than getting silently deleted.

**Feature-relevant output goes in the feature directory, not the inbox.** If the output belongs to work tracked in `scratch/output/_<slug>/` or `_pr-<number>-<slug>/` (a paste-ready message, brief, scenario, or draft for that feature), write it there with the rest of the feature's context. It stays findable next to the work and archives with the feature. The inbox is a flat catch-all that gets hard to search; reserve it for genuinely isolated, feature-less items. See `rules/feature-directory-lifecycle.md`.

**Do not copy output to the user's clipboard.** Write the file and tell the user its path, or show the content inline. Auto-copying earns nothing. The user reads it over, gets distracted, copies other things, and comes back, so the clipboard is stale by the time they want it. They copy when ready.

**Name inbox files `<YYYY-MM-DD>-<N>-<slug>.md`**, where N increments per file per day (e.g., `2026-07-01-1-refund-reply.md`). The date prefix keeps entries ordered instead of mixing together and gives the archive script a deterministic date to sweep on rather than relying on mtime. Before choosing N, list the inbox for that day's existing entries rather than guessing, the same discipline as feature-directory artifact numbering. This mirrors the Sherlock outbox convention.

## scratch/tmp/ — agent and hook infrastructure

Agents and hooks write here for session-scoped state: dispatch gate state, watchdog alerts, fetch artifacts that agents stage for their own inspection. Wiped in full on every session start by `scripts/local/archive-scratch-output.sh`.

Do not write user-facing ephemera here. The aggressive wipe means anything the user is expected to read or run will disappear before they can get to it.

## Why not /tmp/

Do not use `/tmp/` or other system temp directories. `scratch/` paths resolve through the standard scratch path resolution rule and avoid permission issues.
