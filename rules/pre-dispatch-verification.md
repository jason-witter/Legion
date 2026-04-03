# Pre-Dispatch Verification

Before dispatching an agent, read its definition and check for applicable protocols.

1. Read the target agent's definition (`agents/<name>.md`) — once per session per agent
2. Scan `protocols/` and `protocols/local/` for protocols matching the task
3. Compose the dispatch with intent, inputs, and scope only

The agent's definition specifies its operational behavior, protocol discovery, and output conventions. Dispatches that embed commands, field names, or output formats override the agent's own knowledge and bypass installed protocols.

## Examples

Good — orchestrator reads Grace's definition, discovers she runs protocol discovery autonomously:

```
Read: agents/grace.md
Dispatch:
  <intent>Fetch open PR review requests</intent>
  <inputs>Org: acme</inputs>
  <scope>Direct user assignments. Open PRs only.</scope>
```

Bad — orchestrator skips the definition, embeds commands:

```
Dispatch: "Run `gh pr list --search 'review-requested:@me' --json number,title`
  and return results as a manifest"
```

The agent already knows how to fetch PRs — that knowledge lives in its definition and protocols, not the dispatch.
