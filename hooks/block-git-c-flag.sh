#!/bin/bash
# PreToolUse hook: rejects git calls carrying a global flag before the subcommand.
#
# -C enforces rules/git-integration-gates.md. The rest enforce rules/local/git-log-no-pager.md,
# which had no mechanical backing until agents kept emitting `git -c core.pager= status` and the
# user got a permission prompt per call: allow rules match a command prefix, so a flag in front of
# the subcommand matches no rule at all while the plain form is already allowlisted and silent.

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

# Pager control specifically: git only pages on a TTY and the Bash tool is not one, so these buy
# nothing and cost a permission prompt each.
if echo "$stripped" | grep -qE 'git\s+(-c\s+core\.pager|-P\s|--no-pager\s)'; then
  echo '{"decision":"block","reason":"Drop the pager flag and start the call with the subcommand: git log, git status, git show. Git does not page without a TTY, so -c core.pager=, -P and --no-pager change nothing here, and a flag before the subcommand matches no allow rule so it prompts the user. Use --oneline, -n <count>, or a head pipe to keep output short."}'
  exit 0
fi

# Any other global flag before the subcommand breaks prefix matching the same way.
if echo "$stripped" | grep -qE 'git\s+(-c\s|--git-dir|--work-tree|--exec-path)'; then
  echo '{"decision":"block","reason":"Start the call with the git subcommand; a global flag in front of it matches no allow rule and prompts the user. If the flag is genuinely needed, ask rather than working around it."}'
  exit 0
fi

exit 0
