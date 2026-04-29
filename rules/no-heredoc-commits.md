# No Heredocs in Commit Messages

Use `git commit -m "message"` with regular quoted strings. Do not use the `$(cat <<'EOF' ... EOF)` heredoc pattern.

PreToolUse hooks strip quoted strings before checking for violations. Heredoc content is not inside quotes and false-positives on patterns like `&&` or `git -C`.
