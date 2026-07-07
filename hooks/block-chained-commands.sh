#!/bin/bash
# PreToolUse hook: rejects Bash calls that chain multiple commands, embed
# command substitution, or pipe heredocs into git commit. Enforces
# rules/discrete-operations.md and rules/no-heredoc-commits.md mechanically.
#
# Analysis stages (each feeds the next):
#   1. Flatten newlines to \r so quoted strings spanning multiple lines are
#      visible to the per-line sed stages (a multi-line commit message with
#      semicolons used to false-positive here).
#   2. Drop backslash-escaped characters. Makes find's -exec terminator (\;)
#      and escaped quotes inside messages invisible to later stages.
#   3. Drop single-quoted strings (bash allows no escapes inside them).
#   4. Scan for command substitution: $( or backtick. This runs before
#      double-quote stripping because substitution still executes inside
#      double quotes.
#   5. Drop double-quoted strings.
#   6. Scan for chaining operators: &&, ||, ;
#   7. Scan git commit commands for heredoc markers (<<).
#
# Depends on: jq

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')

[ "$tool" != "Bash" ] && exit 0

command=$(echo "$input" | jq -r '.tool_input.command // empty')
[ -z "$command" ] && exit 0

# Stage 1: flatten newlines so quote-pair matching works across lines
flat=$(printf '%s' "$command" | tr '\n' '\r')

# Stages 2-3: drop escaped characters, then single-quoted strings
nosingle=$(printf '%s' "$flat" | sed -E "s/\\\\.//g; s/'[^']*'//g")

# Stage 4: command substitution executes even inside double quotes
if printf '%s' "$nosingle" | grep -qE '\$\(|`'; then
  echo '{"decision":"block","reason":"Discrete operations: no command substitution. The inner command runs unseen by permission matching. Run the producer as its own call, read its output, then run the consumer with concrete values (rules/discrete-operations.md)."}'
  exit 0
fi

# Stage 5: drop double-quoted strings
stripped=$(printf '%s' "$nosingle" | sed -E 's/"[^"]*"//g')

# Stage 6: chaining operators
if printf '%s' "$stripped" | grep -qE '&&|\|\||;'; then
  echo '{"decision":"block","reason":"Discrete operations: one command per Bash call. Split chained commands into separate invocations."}'
  exit 0
fi

# Stage 7: heredocs feeding git commit bypass message-argument scanning
if printf '%s' "$stripped" | grep -qE '(^|[^[:alnum:]_-])git[[:space:]]' && printf '%s' "$stripped" | grep -qE '[[:space:]]commit([[:space:]]|$|\r)'; then
  if printf '%s' "$stripped" | grep -q '<<'; then
    echo '{"decision":"block","reason":"No heredocs in commit messages: use git commit -m with a regular quoted string (rules/no-heredoc-commits.md)."}'
    exit 0
  fi
fi

exit 0
