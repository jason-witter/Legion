#!/bin/bash
# PreToolUse hook: rejects Bash calls that chain multiple commands.
# Enforces rules/discrete-operations.md mechanically.

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')

[ "$tool" != "Bash" ] && exit 0

command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Strip quoted strings to avoid matching operators inside commit messages or echo args
stripped=$(echo "$command" | sed "s/'[^']*'//g;s/\"[^\"]*\"//g")
if echo "$stripped" | grep -qE '&&|\|\||;'; then
  echo '{"decision":"block","reason":"Discrete operations: one command per Bash call. Split chained commands into separate invocations."}'
  exit 0
fi

exit 0
