#!/bin/bash
# PreToolUse hook: rejects Write/Edit calls that put em dashes, en dashes, or
# spaced hyphens into scratch/output/_inbox/ files. Enforces the mechanical
# half of rules/no-em-dashes.md: inbox content is paste-ready by definition,
# so it gets the pre-paste scan at write time instead of relying on recall.
#
# The manual grep from the rule still applies to paste-ready content that
# lives outside the inbox (feature-directory paste artifacts, inline replies).
#
# Depends on: jq

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')

case "$tool" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
case "$file_path" in
  *scratch/output/_inbox/*) ;;
  *) exit 0 ;;
esac

# Write carries content; Edit carries new_string
content=$(echo "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')
[ -z "$content" ] && exit 0

# Scan mirrors the rule's pre-paste grep: [–—]|\s-\s
if printf '%s' "$content" | grep -qE '—|–|[[:space:]]-[[:space:]]'; then
  echo '{"decision":"block","reason":"No em dashes in paste-ready content: restructure with commas, parentheses, semicolons, or two sentences (rules/no-em-dashes.md). Spaced hyphens count as dashes."}'
  exit 0
fi

exit 0
