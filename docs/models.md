# Model Selection

Every agent definition includes a `model` field in its frontmatter. Legion ships with all agents set to `sonnet` — a reasonable default that balances cost and capability.

## Upgrading Agents

Some agents benefit from stronger models. To upgrade an agent, edit its definition file and change the `model` field:

```yaml
---
name: babbage
model: opus
---
```

Since `~/.claude/agents/` is symlinked to the Legion repo, you're editing the file directly. The change takes effect on the next Claude Code session.

## Which Agents Benefit from Stronger Models

**Babbage (Architect)** — does open-ended codebase exploration and design work. A stronger model traces side effects more reliably, identifies non-obvious interactions between components, and produces more complete designs. This is where model quality has the highest leverage — a missed design decision propagates through the entire pipeline.

**Lovelace (Implementer)** — implements from Babbage's design while reading and matching existing codebase patterns. A stronger model handles complex multi-file changes more reliably and is less likely to introduce subtle bugs in unfamiliar code.

**Fagan (PR Reviewer)** — cold-starts on a PR with no prior context. A stronger model reasons more effectively about correctness across a full diff, catches non-obvious security implications, and integrates existing reviewer comments more accurately.

**All other agents** work well on sonnet. Their tasks are more structured — applying checklists, following defined protocols, fetching and formatting data — and don't require the same depth of reasoning.

## Cost Considerations

Parallel dispatch multiplies model cost. Reviewing 3 PRs dispatches 3 Fagan instances simultaneously. A backlog triage might dispatch Foley plus Grace plus multiple follow-up agents. If these are all running on opus, the cost adds up quickly.

The default of sonnet everywhere is intentional — it prevents accidental cost spikes from parallel dispatch. Upgrade selectively based on where you see quality gaps.

## Keeping Your Preferences Across Updates

When you pull an upstream Legion update that modifies an agent definition, git may show a conflict on the `model` line if you've changed it locally. This is a one-line merge conflict — resolve it by keeping your preferred model.

If you use the same model overrides consistently, consider noting them somewhere persistent (a local file, your shell notes) so you can quickly restore them after updates.
