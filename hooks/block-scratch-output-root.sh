#!/bin/bash
# PreToolUse hook: blocks Write calls that dump artifacts directly in scratch/output/
# without a feature directory.
# Enforces the output convention: artifacts go in scratch/output/_<feature-slug>/.

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')

[ "$tool" != "Write" ] && exit 0

file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$file_path" ] && exit 0

# Resolve the Legion scratch output root
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRATCH_OUTPUT="$(cd "$HOOK_DIR/../scratch/output" 2>/dev/null && pwd)"
[ -z "$SCRATCH_OUTPUT" ] && exit 0

# Only care about files written to scratch/output/
case "$file_path" in
  "$SCRATCH_OUTPUT"/*) ;;
  *) exit 0 ;;
esac

# Strip the output root to get the relative path
relative="${file_path#"$SCRATCH_OUTPUT"/}"

# Allow known top-level directories (archive, _briefing, tmp)
first_segment="${relative%%/*}"
case "$first_segment" in
  archive|_briefing|tmp) exit 0 ;;
esac

# Check that the path has at least two segments (directory/file)
# A file directly in scratch/output/ (no subdirectory) is a violation
case "$relative" in
  */*) exit 0 ;;
esac

echo '{"decision":"block","reason":"Artifacts must go in a feature directory: scratch/output/_<feature-slug>/. Do not write directly to scratch/output/."}'
exit 0
