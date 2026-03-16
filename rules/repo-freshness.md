# Repo Freshness

Before dispatching code-producing work, pull the target repo's base branch to ensure the agent works against current remote HEAD.

Once an agent starts working, stale history cannot be corrected without restarting the pipeline.

## Examples

Good — pull before dispatching mob pipeline:

```
Bash: git pull  # in the target repo, on the base branch
Task(babbage): design the feature
```

Bad — dispatching without verifying:

```
Task(babbage): design the feature
# local HEAD may be days behind remote
```
