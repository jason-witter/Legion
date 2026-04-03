# Repo Freshness

Before dispatching code-producing work, ensure the agent works against current remote HEAD. The mechanism depends on whether code-producing agents use worktree isolation or the main working tree.

Once an agent starts working, stale history cannot be corrected without restarting the pipeline.

## Main-Tree Mode

Checkout the base branch and pull before branching. Checkout is required — pulling updates the remote tracking ref but does not change the current checkout. Branching from a non-base branch carries its commits into the new branch.

Good — checkout, pull, then branch:

```
Bash: git checkout main
Bash: git pull
Bash: git checkout -b feature-branch
Task(babbage): design the feature
```

Bad — branching without checkout:

```
Bash: git pull  # updates origin/main but stays on current branch
Bash: git checkout -b feature-branch  # branches from wrong base
Task(babbage): design the feature
```

## Worktree Mode (Subagent Isolation)

Code-producing subagents use the Agent tool's `isolation: "worktree"` parameter (see `rules/local/no-worktree-isolation.md`). The Agent tool creates the worktree from the main tree's current HEAD, so the main tree must be on a fresh base before dispatch.

Good - fetch, checkout base, then dispatch with isolation:

```
Bash: git fetch origin
Bash: git checkout main
Bash: git pull
Agent(lovelace, isolation: "worktree"): implement the feature
```

Bad - dispatching without ensuring main is fresh:

```
Agent(lovelace, isolation: "worktree"): implement the feature
# worktree inherits stale local HEAD
```

Do NOT manually create worktrees for subagent dispatch. Subagents cannot access paths outside the registered working directories.

## Both Modes

Bad — dispatching without verifying:

```
Task(babbage): design the feature
# remote refs may be days behind
```

The deployment-specific rule (`rules/local/`) determines which mode applies. Babbage (design) and other read-only agents do not need freshness enforcement — the principle applies to code-producing agents.
