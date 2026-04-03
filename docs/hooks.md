# Hooks

Legion uses Claude Code hooks to mechanically enforce rules that the model violates through instruction alone. Rules tell the model what to do; hooks block the tool call when it doesn't.

## Architecture

Hook scripts live in `hooks/` within the Legion repo. They are referenced by absolute path from the user's `~/.claude/settings.json` — Claude Code loads hooks from the settings hierarchy, not from `additionalDirectory` registration. Fresh installs via `install.sh` wire these automatically.

```
Legion/
  hooks/
    block-chained-commands.sh   ← enforces rules/discrete-operations.md
    block-git-c-flag.sh         ← enforces rules/git-integration-gates.md
    block-bash-search.sh        ← enforces dedicated-tool-over-bash principle

~/.claude/settings.json
  "hooks": {
    "PreToolUse": [
      { "hooks": [{ "type": "command", "command": "/path/to/Legion/hooks/block-chained-commands.sh" }] },
      { "hooks": [{ "type": "command", "command": "/path/to/Legion/hooks/block-git-c-flag.sh" }] },
      { "hooks": [{ "type": "command", "command": "/path/to/Legion/hooks/block-bash-search.sh" }] }
    ]
  }
```

## How It Works

Each script receives the tool call as JSON on stdin. It inspects `tool_name` and `tool_input`, then either exits silently (allow) or prints a `{"decision":"block","reason":"..."}` JSON object (reject). The reason is surfaced to the model so it can self-correct.

Scripts exit early for non-matching tools — a Bash hook ignores Read, Edit, etc.

## Adding a Hook

1. Write a script in `hooks/` that reads stdin JSON and emits a block decision or exits cleanly.
2. Make it executable.
3. Add a `PreToolUse` entry in the deployment's `~/.claude/settings.json` pointing to `/path/to/Legion/hooks/<script>.sh`. Note that `install.sh` handles this automatically.
4. If the hook enforces an existing rule, note the relationship in both files.

## When to Use Hooks vs Rules

**Rules** are instructions — they guide the model's planning and generation. They work most of the time but degrade under context pressure or competing instructions.

**Hooks** are enforcement — they reject the tool call after the model has already decided to make it. They are deterministic. The model cannot comply with a hook by accident or violate it through inattention.

Use hooks for constraints where a single violation has outsized cost (permission bypass, destructive operations) or where the model has repeatedly failed to comply through rules alone.
