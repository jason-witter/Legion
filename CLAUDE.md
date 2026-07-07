# Legion — Multi-Agent Mob Programming System

Project context for any agent working in this repo. Agent identities live in `agents/`.

## Overview

Legion is a mob programming orchestration system built on Claude Code. It provides Friday (a global chief-of-staff persona), specialized agents, and reusable protocols that work in any codebase the user opens.

Legion's domain is wherever Claude Code gets invoked from — a monorepo, a collection of repos, a single project. The framework is codebase-agnostic.

## Architecture

The directory layout lives in README.md's Structure section; that is the single source of truth. In brief: `agents/` (definitions), `rules/` (behavioral rules, symlinked into every session and subagent), `protocols/` (agent-facing procedures, read on demand), `hooks/` (mechanical enforcement), `scripts/`, `scratch/` (working output), each with a `local/` subdirectory for deployment-specific content.

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
