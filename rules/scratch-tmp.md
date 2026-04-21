# Scratch Tmp for Ephemeral Files

When you need to write a throwaway file (clipboard content, temp output for the user to copy), write it to `scratch/tmp/`. This directory is wiped on every session start.

Use `pbcopy < scratch/tmp/<file>` to copy content to the user's clipboard.

Do not use `/tmp/` or other system temp directories. `scratch/tmp/` resolves through the standard scratch path resolution rule and avoids permission issues.
