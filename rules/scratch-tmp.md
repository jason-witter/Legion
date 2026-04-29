# Scratch Ephemeral Files

Two paths, different owners, different retention.

## scratch/output/_inbox/ — orchestrator writes for the user

When you need to produce ephemeral output for the user to act on (clipboard content, paste buffers, quick scripts, short-lived drafts), write it to `scratch/output/_inbox/`. The archive script applies its 14-day inactivity policy to the directory, so forgotten files age into the archive rather than getting silently deleted.

Use `pbcopy < scratch/output/_inbox/<file>` to copy content to the user's clipboard.

## scratch/tmp/ — agent and hook infrastructure

Agents and hooks write here for session-scoped state: dispatch gate state, watchdog alerts, fetch artifacts that agents stage for their own inspection. Wiped in full on every session start by `scripts/local/archive-scratch-output.sh`.

Do not write user-facing ephemera here. The aggressive wipe means anything the user is expected to read or run will disappear before they can get to it.

## Why not /tmp/

Do not use `/tmp/` or other system temp directories. `scratch/` paths resolve through the standard scratch path resolution rule and avoid permission issues.
