#!/bin/bash
# PreToolUse hook: rejects Bash calls that use git -C.
# Enforces rules/git-integration-gates.md mechanically.

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')

[ "$tool" != "Bash" ] && exit 0

command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Strip quoted strings to avoid matching inside commit messages or echo args
stripped=$(echo "$command" | sed "s/'[^']*'//g;s/\"[^\"]*\"//g")
if echo "$stripped" | grep -qE 'git\s+-C\s'; then
  echo '{"decision":"block","reason":"No git -C. Use cd to the directory first, then run the git command."}'
  exit 0
fi

exit 0
