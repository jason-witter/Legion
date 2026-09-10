#!/bin/bash
# PreToolUse hook: rejects Bash calls that chain multiple commands, embed
# command substitution, or pipe heredocs into git commit. Enforces
# rules/discrete-operations.md and rules/no-inline-script-bodies.md mechanically.
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
#  7b. Scan every other command for heredoc markers. A heredoc plus braces and
#      quotes is unevaluable by the permission matcher, so the call always
#      prompts however broad the allow rule is.
#   8. Scan for unquoted glob metacharacters. Anything surviving quote
#      stripping is expanded by the shell, which the permission matcher
#      cannot evaluate, so the call always prompts the user.
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
    echo '{"decision":"block","reason":"No heredocs in commit messages: use git commit -m with a regular quoted string for short messages, or write the message to a file and pass it with git commit -F (rules/no-inline-script-bodies.md)."}'
    exit 0
  fi
fi

# Stage 7b: any other heredoc. The permission matcher refuses to evaluate a command
# carrying a heredoc alongside braces and quotes, so the call always prompts however
# broad the allow rule is. Fires after Stage 7 so commit heredocs keep their specific
# message, and before Stage 8 so a script body's globs do not produce a misleading one.
if printf '%s' "$stripped" | grep -q '<<'; then
  echo '{"decision":"block","reason":"No inline multi-line script bodies: a heredoc always prompts the user and stalls the run, because the permission matcher cannot evaluate what the shell will expand. Write the script to a file in the session scratchpad with the Write tool, then run it as a plain invocation (python3 /abs/path/script.py), which matches normally and leaves the script inspectable and rerunnable (rules/no-inline-script-bodies.md)."}'
  exit 0
fi

# Stage 8: unquoted glob. Surviving quote stripping means the shell expands it,
# which the permission matcher cannot evaluate, so the user is always prompted.
# Only * is scanned: ? and [ ] are the same class but appear unquoted in URLs
# and jq filters often enough that blocking them would cost more than it saves.
if printf '%s' "$stripped" | grep -q '\*'; then
  echo '{"decision":"block","reason":"Unquoted shell glob: expansion bypasses permission matching, so this call always prompts the user and stalls the run. For searching contents use the Grep tool, whose glob and path parameters cover this natively; for file discovery use the Glob tool. If a program must receive the pattern itself, wrap it in single quotes so the program expands it rather than the shell, or enumerate with find in one call and act on concrete paths in the next (rules/file-tools-over-shell-traversal.md)."}'
  exit 0
fi

exit 0
