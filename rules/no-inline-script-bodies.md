# No Inline Bodies: Scripts and Commit Messages

Anything longer than a one-liner rides a file, not the command line. Write the script to a file and execute the file; write the commit message to a file and pass it with `-F`. Never inline a program body into a Bash call with a heredoc (`python3 - <<'EOF'`, `bash <<'EOF'`, `jq -f - <<'EOF'`) or a multi-line `-c` string, and never build a commit message with `$(cat <<'EOF' ... EOF)`.

```
Write: <session-scratchpad>/audit-dataclass-shapes.py
Bash:  python3 /abs/path/to/audit-dataclass-shapes.py

Write: <session-scratchpad>/commit-msg.txt
Bash:  git commit -F /abs/path/to/commit-msg.txt
```

Why the file form: a heredoc always prompts the user regardless of the allow list, because the permission matcher cannot evaluate a command whose body carries a heredoc (an allow rule as broad as `Bash(python3 *)` does not help). Heredoc content also sits outside quotes, so hook scanning neither strips nor parses it. A file is inspectable and rerunnable, and a typo costs one Edit instead of a full retype. `hooks/block-chained-commands.sh` rejects heredoc markers mechanically, including on `git commit`.

## Where the file goes

The harness session scratchpad, not `scratch/tmp/`: a concurrent session's SessionStart sweep wipes `scratch/tmp/` and can delete an in-flight agent's files mid-run (see `docs/rule-history/no-inline-script-bodies.md`). `scratch/tmp/` remains correct for framework-owned state per `rules/scratch-tmp.md`. Use the file tools to write the file; `echo`/`printf` reintroduce the quoting problem.

## Commit messages

- A title, or a title plus one short paragraph: `git commit -m "title"` or `git commit -m "title" -m "one short paragraph"`. The command stays readable in a permission prompt, which is the whole test.
- Anything longer: `-F <file>`. Chained `-m` flags put the entire body in the permission prompt as one unreadable line; the file form keeps the command short and the message revisable. Point `-F` at a file containing exactly the message text, not at a document that also carries headings, fences, or commentary.
- `--amend` follows the same split (`--amend -F <file>`); amending after a push requires force, gated per `rules/git-integration-gates.md`.

## Scope

A genuine one-liner with no multi-line body and no heredoc stays a one-liner; the trigger is an inlined program, not the use of `python3` or `jq`. This composes with `rules/discrete-operations.md`, which governs the shape of the Bash calls you do make: that rule forbids chaining and command substitution, this one forbids smuggling a program or message body into the call.

## Example

Bad, the body is inlined and the call prompts:

```
Bash: python3 - <<'PYEOF'
      import ast
      SHAPES = {'candidate': {'reward', 'invoice_item_ids'}}
      ...
      PYEOF
```

The bad example stalls the run on a permission prompt, hands the user a wall of unreviewable code to approve, and loses the script the moment the call completes. Good is the Write-then-execute pair at the top.
