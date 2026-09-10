# Dispatch Shape

Every agent dispatch is exactly three fields. Agents derive operational details from their own definitions and protocols.

```
<dispatch>
  <intent>The goal — stated as an outcome, not a procedure</intent>
  <inputs>File paths, identifiers, parameters. Raw data only.</inputs>
  <scope>What is in scope, what is excluded, any constraints.</scope>
</dispatch>
```

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

The bad example embeds a CLI command, JSON fields, and an output format that already live in the agent's definition.

## Dispatch the Problem, Not Candidate Solutions

Raw task data (ticket descriptions, bug reports, error logs) belongs in inputs. Candidate solutions, teammate opinions, and proposed fixes do not; subagents treat dispatch content as authoritative, so an included option anchors the agent instead of letting it derive the approach from the material.

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

The bad example pre-selects the solution space; the agent evaluates the orchestrator's menu rather than independently assessing the code.

## Dispatch Location, Not Content

Pass the feature slug and let downstream agents read prior artifacts from the feature directory themselves. Summarizing a prior agent's output into the dispatch constrains the agent to the orchestrator's interpretation: if the summary missed a call site, the agent misses it too.

Good:

```
<intent>Review the implementation for the signup flow experiment changes</intent>
<inputs>Feature slug: pr-1234-signup-flow-experiment. Worktree: /path/to/worktree</inputs>
<scope>Independent review.</scope>
```

Bad:

```
<intent>Review the implementation for the signup flow experiment changes</intent>
<inputs>Feature slug: pr-1234-signup-flow-experiment. Worktree: /path/to/worktree.
The design renamed the experiment and fixed two call sites in rate_limiter.py and webhook_routes.py.</inputs>
<scope>Pay particular attention to variant rename correctness and redundant lookup elimination.</scope>
```

The bad example tells the agent what the design did and what to focus on, so the agent verifies the orchestrator's summary instead of discovering the scope from the code.
