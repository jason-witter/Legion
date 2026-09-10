# Repo Freshness

Before dispatching code-producing work, ensure the agent works against current remote HEAD. Once an agent starts working, stale history cannot be corrected without restarting the pipeline.

Fetch all refs (`git fetch origin`), not a single branch. Single-branch fetch leaves other tracking refs stale.

Read-only agents (design, review) do not need freshness enforcement. The principle applies to code-producing agents only.

The deployment-specific rule (`rules/local/`) determines the mechanism: worktree isolation, WIP branch transport, branch currency checks.
