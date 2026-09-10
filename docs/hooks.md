# Hooks

Legion uses Claude Code hooks to mechanically enforce rules that the model violates through instruction alone. Rules tell the model what to do; hooks block the tool call when it doesn't.

## Current Hook Set

Generic enforcement hooks (ship in the public snapshot, wired for every session):

| Hook | Event | Enforces |
|------|-------|----------|
| `block-chained-commands.sh` | PreToolUse: Bash | `rules/discrete-operations.md` (chaining, command substitution) and `rules/no-inline-script-bodies.md` (heredocs, including on `git commit`) |
| `block-git-c-flag.sh` | PreToolUse: Bash | `rules/git-integration-gates.md` (no `git -C`) |
| `block-agent-names-in-commits.sh` | PreToolUse: Bash | `rules/user-authorship.md` (no agent names in commit messages) |
| `block-scratch-output-root.sh` | PreToolUse: Write | `rules/scratch-path-resolution.md` (no writes to the scratch output root) |

Deployment-coupled hooks (excluded from the public snapshot; wired per deployment):

| Hook | Event | Purpose |
|------|-------|---------|
| `agent-watchdog-start.sh` | PostToolUse: Agent | Spawns a background monitor for each background agent dispatch |
| `agent-watchdog-monitor.sh` | (helper) | The monitor itself; spawned by the start hook, never wired in settings. Writes stall and lifetime-expiry alerts to `scratch/tmp/watchdog-alerts/` |
| `deliver-watchdog-alerts.sh` | PostToolUse: Agent, Read | Surfaces watchdog alerts as additionalContext and consumes them so each alert delivers exactly once |
| `check-branch-feature-alignment.sh` | PreToolUse: Bash | Blocks branch creation when the branch slug partially overlaps a feature directory slug (`rules/local/branch-naming.md`) |
| `morning-briefing-runner.sh` | SessionStart | Runs the deployment's session-start briefing |

`hooks/tests/test-block-hooks.sh` is the regression harness for the block hooks. Run it after any hook change; it feeds JSON payloads through the real scripts and asserts block/pass decisions.

## Architecture

Hook scripts live in `hooks/` within the framework repo and are referenced by absolute path from settings. Claude Code loads hooks from the settings hierarchy, not from `additionalDirectory` registration. Two wiring surfaces exist:

- The user's `~/.claude/settings.json` for hooks that apply to every session. Generic enforcement hooks belong here. Fresh installs via `install.sh` wire them automatically when no settings file exists; otherwise the installer prints the block to add.
- A repo's `.claude/settings.local.json` for hooks scoped to one product repo.

Wiring drift is detectable mechanically: the deployment's `scripts/local/check-hook-wiring.sh` compares `hooks/*.sh` against the command references in the settings files and reports unwired hooks and dangling references.

## How It Works

Each script receives the tool call as JSON on stdin. It inspects `tool_name` and `tool_input`, then either exits silently (allow), prints a `{"decision":"block","reason":"..."}` object (reject), or prints a `hookSpecificOutput` object with `additionalContext` (inform). The block reason is surfaced to the model so it can self-correct.

Scripts exit early for non-matching tools. A Bash hook ignores Read, Edit, etc. The block hooks require `jq`.

## Adding a Hook

1. Write a script in `hooks/` that reads stdin JSON and emits a decision or exits cleanly.
2. Make it executable and add cases to `hooks/tests/test-block-hooks.sh`.
3. Wire it in the appropriate settings surface (see Architecture). Decide which side of the public-release boundary it lives on: generic hooks enforce a rule in `rules/` and contain no deployment-specific references; deployment-coupled hooks stay out of the snapshot per `protocols/local/public-release.md`.
4. If the hook enforces an existing rule, note the relationship in both files.
5. Run the wiring checker to confirm nothing is unwired or dangling.

## When to Use Hooks vs Rules

**Rules** are instructions. They guide the model's planning and generation, work most of the time, and degrade under context pressure or competing instructions.

**Hooks** are enforcement. They reject the tool call after the model has already decided to make it. They are deterministic. The model cannot comply with a hook by accident or violate it through inattention.

Use hooks for constraints where a single violation has outsized cost (permission bypass, destructive operations) or where the model has repeatedly failed to comply through rules alone. When a rule admits "recall alone has failed in practice," that is the signal to extend a hook rather than strengthen the prose.
