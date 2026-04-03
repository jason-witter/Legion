# Legion

Multi-agent mob programming framework for Claude Code.

## What It Does

Legion orchestrates a team of Claude Code agents in a mob programming pipeline:

1. **Friday** receives tasks, classifies complexity, delegates work
2. **Babbage** (Architect) explores the codebase and produces a design
3. **Lovelace** (Implementer) writes production-ready code from the design
4. **Friedman** (Reviewer) reviews for correctness, security, and style
5. **Curie** (Validator) writes tests and produces a validation plan

Support agents handle specialized work:

- **Fagan** — reviews external PRs (code you didn't write)
- **Denniston** — digests review feedback on your own PRs
- **Grace** — retrieves data from external systems (GitHub, task trackers)
- **Foley** — triages backlogs and assesses dispatch readiness
- **Penkovsky** — writes tickets for out-of-scope issues surfaced during work
- **Kelly** — builds and maintains Legion itself
- **Vera** — designs new agents, assesses roster gaps
- **Q** — creates and maintains protocols
- **Iris** — runs structured review cycles on agent definitions

## Structure

```
agents/             # Agent definitions (symlinked to ~/.claude/agents/)
rules/              # Behavioral rules (symlinked to ~/.claude/rules/)
  local/            # Deployment-specific rules
protocols/          # Agent-facing procedural instructions
  local/            # Deployment-specific protocols
hooks/              # PreToolUse hooks for behavioral enforcement
scripts/
  local/            # Deployment-specific scripts
install.sh          # Deployment script
install/
  friday-claude.md  # Friday base template
scratch/
  context/          # Domain context documents (gitignored)
  output/           # Agent artifacts: designs, reviews, validations (gitignored)
```

## Getting Started

```bash
git clone <repo-url> Legion
cd Legion
./install.sh
```

The install script:
- Prompts for your name and installs Friday as `~/.claude/CLAUDE.md`
- Registers Legion as an `additionalDirectory` in `~/.claude/settings.json`
- Symlinks `agents/` and `rules/` into `~/.claude/`
- Configures PreToolUse hooks for behavioral enforcement
- Creates the scratch directory structure

Any repo you open with Claude Code gets the full legion automatically.

## How Distribution Works

Legion uses two distribution mechanisms because `additionalDirectories` has limits:

**`additionalDirectories` (registered in `~/.claude/settings.json`):**
Loads `CLAUDE.md` and protocols into the top-level session context. Gives agents filesystem access to the Legion repo. Does NOT distribute agents (Claude Code doesn't discover agents from additional directories). Does NOT propagate rules to Task subagents.

**Symlinks into `~/.claude/`:**
The only way to make agents and rules work correctly across all contexts. `install.sh` creates:
- `~/.claude/agents/` → `Legion/agents/`
- `~/.claude/rules/` → `Legion/rules/`

Changes to agent definitions or rules in the repo propagate immediately — no reinstall needed.

```
~/.claude/
  CLAUDE.md          # Friday (copied from install/friday-claude.md)
  settings.json      # additionalDirectories, hooks
  agents/            # symlink -> Legion/agents/
  rules/             # symlink -> Legion/rules/
```

## Personalizing Your Deployment

Directories named `local/` hold deployment-specific content:

| Content | Location |
|---|---|
| Agent definitions | `agents/` |
| Behavioral rules | `rules/` |
| Framework protocols | `protocols/` |
| Your protocols | `protocols/local/` |
| Your rules | `rules/local/` |
| Your scripts | `scripts/local/` |
| Agent output artifacts | `scratch/output/` (gitignored) |

Framework files (everything outside `local/`) stay generic — no user names, org names, or project-specific references. Your deployment-specific content goes in the `local/` directories.

## Design

See `VISION.md` for design philosophy and architecture.
