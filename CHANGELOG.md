# Changelog

## [v0.3] - 2026-04-21

### New
- Winterbotham agent consolidates parallel review passes into canonical reports, with same-agent and cross-discipline modes
- Dispatch gate hooks block specialist agent dispatch until the orchestrator has read the target definition and referenced protocols
- Agent watchdog hooks detect stuck agents and surface them to the orchestrator
- Session-orient framework protocol for session-start briefing patterns
- Mob review output protocol extracted from agent definitions
- Feature directory lifecycle rule: `_<slug>/` before PR, `_pr-<number>-<slug>/` after, stage-specific artifact naming, read-before-increment for artifact numbers
- `scratch/tmp/` for ephemeral throwaway files, wiped on session start
- No-em-dashes rule (parenthetical dashes read as LLM-generated)
- No-heredoc-commits rule (heredocs bypass Bash permission pattern matching)

### Changed
- Replaced orchestrator-curated context briefs with feature directory communication. Agents orient from `scratch/output/_<slug>/` rather than receiving pre-digested summaries. Prevents the interpretation-anchoring failure mode where downstream stations inherit upstream scope errors.
- Babbage-Lovelace boundary shifted: designs set direction, implementation owns the details
- Agent effort tiers rebalanced for Opus 4.7
- Pre-ship review runs dual Fagan/Oppenheimer passes with Winterbotham cross-discipline consolidation
- Fagan: explicit protocol discovery section, no dispatcher path dependency
- PR review protocol: inline line-content citation, ref-pinned fetches, bot-resolved thread handling
- Worktree base verification enforced in code-producing dispatches
- Oppenheimer re-review required after blockers are addressed
- README rewritten for public audience, VISION.md tightened

### Fixed
- Watchdog hooks corrected after initial rollout
- scratch/tmp wipe preserves .gitkeep

### Removed
- Orchestrator-curated context briefs (replaced by feature directory communication)
- Scratch-path-resolution hooks (agent/protocol guarantees cover it)

## [v0.2.1] - 2026-04-03

### Fixed
- README now reflects v0.2 changes: Oppenheimer in pipeline, Kelly as operations planner, pre-ship review in usage examples
- VISION.md pipeline diagram updated to include Oppenheimer design critique station

## [v0.2] - 2026-04-03

### New
- Pre-ship review protocol for parallel code inspection and design critique against your own PRs before shipping
- Oppenheimer agent - architectural design critic that stress-tests designs for structural flaws before implementation
- Scratch output conventions protocol - single source of truth for output directory structure
- Archive protocol and daily script to keep scratch/output/ clean (current work week at top level, older content archived)
- PR data fetch protocol extracted as shared resource for Fagan, Denniston, and queue pipelines
- Agent-name commit hook prevents agent references from leaking into git-visible artifacts

### Changed
- Kelly refactored from framework architect to operations planner - returns structured execution plans, does not dispatch agents directly
- Agents no longer contain output path knowledge - they describe what they produce, the orchestrator resolves where it goes
- Mob pipeline design critique station is now mandatory (previously could be skipped)
- Friedman applies adversarial investigation lens and verifies coverage preservation on restructured code
- Fagan verifies line numbers against actual branch files and skips resolved threads entirely
- PR review protocol includes thread resolution filtering
- Mob pipeline produces a single squashed commit with orchestrator-written message
- Worktree isolation is the default for code-producing agents via the Agent tool's isolation parameter
- Repo freshness rule requires checkout before branching, not just pull

### Fixed
- Agent-name commit hook now checks git toplevel instead of CLAUDE_PROJECT_DIR (works correctly in additional directories)
- Deployment-specific branch prefixes removed from framework agent examples

## [v0.1] - 2026-03-24

Initial release. Full agent roster, mob pipeline, PR review pipeline, support agents, documentation, and install script.
