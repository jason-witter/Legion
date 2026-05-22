#!/bin/bash
# PreToolUse hook: rejects git commit commands that contain agent names.
# Enforces rules/user-authorship.md mechanically.

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')

[ "$tool" != "Bash" ] && exit 0

command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only check git commit commands
echo "$command" | grep -q 'git commit' || exit 0

# Only enforce in product repos, not the Legion framework repo itself.
# CLAUDE_PROJECT_DIR points to the primary working directory, which may not
# be where the commit is happening (Legion is an additionalDirectory).
# Compare basenames: the hook lives at <framework-root>/hooks/, so its parent
# is the framework root. If the git root's basename matches, we're committing
# inside the framework repo and the rule does not apply.
LEGION_DIR="${LEGION_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
git_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$git_root" ] && [ "$(basename "$git_root")" = "$(basename "$LEGION_DIR")" ]; then
  exit 0
fi

# Build agent name pattern dynamically from agents/ directory.
# Excludes the orchestrator identity (CLAUDE.md defines that, not an agent file).
AGENTS_DIR="$LEGION_DIR/agents"

if [ ! -d "$AGENTS_DIR" ]; then
  exit 0
fi

agent_names=$(ls "$AGENTS_DIR"/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//' | paste -sd '|' -)

[ -z "$agent_names" ] && exit 0

if echo "$command" | grep -iEq "\b($agent_names)\b"; then
  echo "{\"decision\":\"block\",\"reason\":\"User authorship: commit messages must not reference mob agent names. Rewrite the message without agent references.\"}"
  exit 0
fi

exit 0
