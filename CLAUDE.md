# Legion — Multi-Agent Mob Programming System

Project context for any agent working in this repo. Agent identities live in `agents/`.

## Overview

Legion is a mob programming orchestration system built on Claude Code. It provides Friday (a global chief-of-staff persona), specialized agents, and reusable protocols that work in any codebase the user opens.

Legion's domain is wherever Claude Code gets invoked from — a monorepo, a collection of repos, a single project. The framework is codebase-agnostic.

## Architecture

```
Legion/
├── CLAUDE.md                    # This file — project context
├── VISION.md                    # Design philosophy and architecture
├── README.md                    # Getting started and structure overview
├── install.sh                   # Deploys Friday, symlinks agents/rules, registers additionalDirectory
├── install/
│   └── friday-claude.md         # Friday CLAUDE.md template ({{USER_NAME}} placeholder)
├── agents/                      # Agent definitions (personalities + instructions)
│   ├── kelly.md                 # Kelly - system architect (Legion-local)
│   ├── vera.md                  # Vera - agent manager
│   ├── q.md                     # Q - protocol creator
│   └── ...                      # See README.md for full roster
├── rules/                       # Behavioral rules injected into all sessions and subagents
│   ├── discrete-operations.md
│   ├── git-integration-gates.md
│   ├── read-only-external-systems.md
│   ├── user-authorship.md
│   └── local/                   # Deployment-specific rules
├── protocols/                   # Agent-facing procedural instructions
│   ├── mob-pipeline.md
│   ├── pipeline-narrative.md
│   ├── pr-review.md
│   ├── validation-plan.md
│   ├── design-output.md
│   └── local/                   # Deployment-specific protocols
├── hooks/                       # PreToolUse hooks for behavioral enforcement
├── scripts/
│   └── local/                   # Deployment-specific scripts
└── scratch/
    ├── context/                 # Domain context documents
    └── output/                  # Agent artifacts: reviews, designs, validations
```

## Install & Distribution

`install.sh` deploys Legion to a new machine:
- Prompts for user name → substitutes `{{USER_NAME}}` in Friday template
- Copies Friday template → `~/.claude/CLAUDE.md`
- Registers Legion as an `additionalDirectory` in `~/.claude/settings.json`
- Creates symlinks: `~/.claude/agents/` → `Legion/agents/` and `~/.claude/rules/` → `Legion/rules/`
- Configures PreToolUse hooks for behavioral enforcement

Legion uses two distribution mechanisms because `additionalDirectories` has limits:

- **`additionalDirectories`** → loads `CLAUDE.md` and `protocols/` into the top-level session context. Gives agents filesystem access to the repo.
- **Symlinks to `~/.claude/`** → the only way to distribute agents and rules. Claude Code does not discover agents from `additionalDirectories` at all. Rules from `additionalDirectories` do not propagate to Task subagents.

Protocols stay in `protocols/` — agents read them explicitly via file reads, so they don't need symlink treatment.

## Deployment-Specific Content

Directories named `local/` contain deployment-specific content:
- `protocols/local/` — protocols tailored to a specific user's workflow
- `rules/local/` — rules specific to a deployment
- `scripts/local/` — deployment-specific scripts

Framework files (everything outside `local/` directories) stay generic — no user names, org names, or project-specific references. This separation matters for public releases.
