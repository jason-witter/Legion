# Changelog

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
