# Legion

A multi-agent mob programming framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

A single Claude Code pass on a coding task makes design decisions, implementation choices, and test strategy calls simultaneously, with no independent check on any of them. Errors compound silently. Legion separates these concerns into stations: an architect designs, a critic stress-tests the design, an implementer writes code, a reviewer finds bugs, and a validator confirms it works. Each station checks the last.

## The Pipeline

```
Friday → Babbage → Oppenheimer → Lovelace → Friedman → Curie → Friday
```

**Friday** is your primary interface. You talk to Friday; Friday sequences the pipeline, decides whether to advance or loop back, and produces the handoff when the work is done.

**Babbage** (Architect) reads the codebase and produces a technical design: approach, interface contracts, affected files, test strategy. The design is complete enough that the next station can implement without re-deriving the approach.

**Oppenheimer** (Design Critic) stress-tests the design for structural flaws before implementation begins. Challenges assumptions, identifies missed edge cases, and gates the design. Blocking issues go back to Babbage.

**Lovelace** (Implementer) writes production code from the approved design, matching the patterns already established in your codebase. New code fits the repo it lives in.

**Friedman** (Reviewer) applies a structured inspection: correctness, security, code quality, test coverage, pattern consistency. Every finding has a severity and a specific location. Blockers go back to Lovelace; the loop repeats until the review is clean.

**Curie** (Validator) assesses test coverage, writes tests if needed, and produces a validation plan. When the local environment supports it, she runs the suite. When it doesn't, the plan is the handoff for remote execution.

## Support Agents

Beyond the mob pipeline, specialist agents handle other work:

- **Fagan** reviews pull requests you didn't write. Cold-starts from the diff, applies a structured inspection, writes a findings report.
- **Denniston** digests review feedback on your own PRs. Categorizes what needs code changes, what is conversation, and what is blocking.
- **Grace** retrieves data from external systems (GitHub, task trackers). Read-only.
- **Foley** triages backlogs and assesses whether tasks are ready for dispatch.
- **Penkovsky** writes tickets for out-of-scope issues surfaced during work.
- **Kelly** plans pipelines and multi-agent coordination.
- **Winterbotham** consolidates parallel review passes into a single canonical report.
- **Vera** designs new agents, revises existing ones, assesses roster gaps.
- **Q** creates and maintains protocols.
- **Iris** runs structured review cycles on agent definitions.

## Usage

Open any repo with Claude Code. Friday is already there.

**Implement a feature:**
> Add rate limiting to the /api/webhooks endpoint. Max 100 requests per minute per API key. Here's the ticket: [context]

Friday kicks off the full pipeline. You get a handoff document when it's done.

**Review a PR:**
> Review PR #1847

Fagan fetches the diff, applies a structured inspection, and writes a findings report. You decide what to post.

**Review multiple PRs at once:**
> Review PRs #1847, #1852, and #1860

Three Fagan instances run in parallel, one per PR.

**Ask a question:**
> How does the payment retry logic work?

Simple questions get answered inline. No pipeline, no agents dispatched.

**Catch up on feedback:**
> What's the feedback on my PR #1823?

Denniston categorizes all review comments: what needs code changes, what is conversation, what is blocking.

See `docs/cookbook.md` for more examples including backlog triage, customizing your deployment, and capturing out-of-scope issues.

## Getting Started

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and configured.

> **Already using Claude Code?** The install replaces `~/.claude/CLAUDE.md` (your global persona) and symlinks over `~/.claude/agents/` and `~/.claude/rules/`. If you have existing configuration in these locations, the install script will detect it, show you what will be affected, and back everything up to `~/.claude/backup-*/` before making changes.

```bash
git clone <repo-url> Legion
cd Legion
./install.sh
```

The install script:
- Detects and backs up any existing Claude Code configuration
- Prompts for your name and installs Friday as `~/.claude/CLAUDE.md`
- Registers Legion as an `additionalDirectory` in `~/.claude/settings.json`
- Symlinks `agents/` and `rules/` into `~/.claude/`
- Configures behavioral enforcement hooks

Once installed, every repo you open with Claude Code gets the full legion.

## How It Works

Legion uses two distribution mechanisms because Claude Code's `additionalDirectories` has limits:

**`additionalDirectories`** loads Legion's project context and protocols into every session. It also gives agents filesystem access to read protocols on demand.

**Symlinks** are the only way to distribute agents and rules to subagents. Claude Code doesn't discover agents from additional directories, and rules don't propagate to Task subagents. The symlinks solve both.

```
~/.claude/
  CLAUDE.md          # Friday (your orchestrator persona)
  settings.json      # additionalDirectories, hooks
  agents/            # symlink -> Legion/agents/
  rules/             # symlink -> Legion/rules/
```

Changes to agent definitions or rules take effect immediately.

## Customizing Your Deployment

Directories named `local/` hold deployment-specific content:

```
protocols/local/    # Your protocols
rules/local/        # Your rules
scripts/local/      # Your scripts
```

Framework content (everything outside `local/`) stays generic. Your customizations go in the `local/` directories and won't conflict with upstream updates.

## Key Principles

**80/20**: The legion handles routine coding, testing, and validation. You focus on debugging, architecture, and decisions that require judgment.

**Human-in-the-loop**: The legion never pushes code, merges branches, posts comments, or modifies external systems without your approval. Agents fetch and analyze; you act.

**Sequential quality**: Each pipeline station builds on the previous one's work and catches what was missed.

**Codebase-native**: New code matches the patterns already in your repo. No imposed style, no gratuitous abstractions, no "improvements" beyond what was asked.

## Structure

```
agents/             # Agent definitions
rules/              # Behavioral rules
  local/            # Your rules
protocols/          # Procedural instructions for agents
  local/            # Your protocols
hooks/              # PreToolUse hooks for behavioral enforcement
scripts/
  local/            # Your scripts
docs/               # Framework documentation
install.sh          # Deployment script
install/
  friday-claude.md  # Friday template
scratch/            # Working directory for agent output (gitignored)
```

## Documentation

- `docs/cookbook.md` — concrete examples of common workflows
- `docs/agent-definitions.md` — how to write effective agent definitions
- `docs/protocol-writing.md` — how to write effective protocols
- `docs/rule-writing.md` — how to write effective rules
- `docs/hooks.md` — how behavioral enforcement hooks work
- `docs/models.md` — model selection guidance
- `VISION.md` — design philosophy and architecture rationale

## License

MIT
