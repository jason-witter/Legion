#!/bin/bash
# PreToolUse hook: rejects Bash calls that duplicate dedicated search tools.
# Grep, Glob, and Read exist for these operations — Bash should not be used.

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')

[ "$tool" != "Bash" ] && exit 0

command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Extract the first word (the command being run)
first_word=$(echo "$command" | awk '{print $1}')

# Block commands that have dedicated tool equivalents
case "$first_word" in
  grep|rg|find|cat|head|tail|sed|awk)
    echo "{\"decision\":\"block\",\"reason\":\"Use the dedicated tool instead of Bash $first_word. Grep for content search, Glob for file search, Read for file contents, Edit for file modifications.\"}"
    exit 0
    ;;
esac

exit 0
