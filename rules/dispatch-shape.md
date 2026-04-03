# Dispatch Shape

Every agent dispatch is exactly three fields:

```
<dispatch>
  <intent>The goal — stated as an outcome, not a procedure</intent>
  <inputs>File paths, identifiers, parameters. Raw data only.</inputs>
  <scope>What is in scope, what is excluded, any constraints.</scope>
</dispatch>
```

Agents derive operational details from their own definitions and protocols.

## Examples

Good:

```
<intent>Fetch open PR review requests for acme/webapp</intent>
<inputs>Repo: acme/webapp</inputs>
<scope>Open PRs only. Review requests, not authored PRs.</scope>
```

Bad:

```
<intent>Run `gh pr list --search "review-requested:@me" --json number,title`
and return results as a manifest with ITEM_COUNT header</intent>
<inputs>Repo: acme/webapp</inputs>
<scope>Open PRs only.</scope>
```

The bad example embeds a CLI command, specific JSON fields, and an output format. The agent already knows how to fetch PRs — that lives in its definition, not the dispatch.

## Dispatch the Problem, Not Candidate Solutions

Subagents treat dispatch content as authoritative. Including candidate solutions — even framed as options — anchors the agent to those options rather than letting it derive the right approach from the material.

Good:

```
<intent>Fix the authentication bypass in the password reset flow</intent>
<inputs>File: auth/reset.py. Bug report: unauthenticated users can reset any account's password.</inputs>
<scope>Determine root cause, design and implement the fix.</scope>
```

Bad:

```
<intent>Fix the auth bypass — two approaches to consider</intent>
<inputs>Approach A: add a token validation check before the reset. Approach B: rate-limit
the endpoint per the security team's suggestion. Approach C: any other approach.</inputs>
<scope>Compare approaches and recommend one.</scope>
```

The bad example pre-selects the solution space. The agent evaluates the orchestrator's menu rather than independently assessing the code. A teammate's suggestion ("the security team's recommendation") becomes an anchor rather than a data point the agent discovers or weighs on its own.

Raw task data — ticket descriptions, bug reports, error logs — belongs in inputs. Candidate solutions, teammate opinions, and proposed fixes do not. The agent should encounter those through its own investigation (git history, code comments, linked discussions) and weigh them accordingly.
