# No Inline Bodies: Scripts and Commit Messages

Anything longer than a one-liner rides a file, not the command line. Write the script to a file and execute the file; write the commit message to a file and pass it with `-F`. Never inline a program body into a Bash call with a heredoc (`python3 - <<'EOF'`, `bash <<'EOF'`, `jq -f - <<'EOF'`) or a multi-line `-c` string, and never build a commit message with `$(cat <<'EOF' ... EOF)`.

```
Write: <session-scratchpad>/audit.py
Bash:  python3 /abs/path/to/audit.py
Bash:  git commit -F /abs/path/to/commit-msg.txt
```

A heredoc always prompts, whatever the allow list says. `hooks/block-chained-commands.sh` rejects heredoc markers, including on `git commit`.

The file goes in the harness session scratchpad, not `scratch/tmp/`, which stays for framework-owned state. Write it with the file tools, not `echo` or `printf`.

## Commit messages

- A title, or a title plus one short paragraph: `-m "title"` or `-m "title" -m "paragraph"`.
- Anything longer: `-F <file>`, not chained `-m` flags. The file holds exactly the message text: no headings, fences, or commentary.
- `--amend` follows the same split; amending after a push requires force, gated per `rules/git-integration-gates.md`.

## Scope

A genuine one-liner with no multi-line body and no heredoc stays a one-liner; the trigger is an inlined program, not the use of `python3` or `jq`.
