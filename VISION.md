# Legion — Design Rationale

This document explains why Legion works the way it does. For what Legion is and how to set it up, see `README.md`.

## Why a Pipeline

A single agent pass — "implement this feature" — produces code that works but drifts. The agent makes design decisions, implementation choices, and test strategy calls simultaneously, with no independent check on any of them. Errors compound silently.

The mob pipeline separates concerns into stations. The architect doesn't implement. The implementer doesn't review. The reviewer doesn't validate. Each station's output is checked by a station with a different perspective. This is slower than a single pass, but the failure mode changes from "silently wrong" to "caught at the next station."

Implementation tested against independent review — with iteration loops until the review is clean — catches the class of bugs that a single-pass agent misses entirely: side effects of called methods, untested field mutations, design gaps that only surface during implementation.

## Why Sequential

Parallel stations sound faster but create coordination problems. If the implementer and reviewer work simultaneously, the reviewer is checking a moving target. If the architect and implementer overlap, the implementer starts building before the design is settled.

Sequential execution means each station works against a stable input. The design is final before implementation starts. The implementation is committed before review begins. The review is clean before validation runs. No station re-derives what the previous station already decided.

## Why Hub-and-Spoke

Agents don't talk to each other. All communication flows through Friday:

```
Friday → Babbage → Friday → Oppenheimer → Friday → Lovelace → Friday → Friedman → Friday → Curie → Friday
```

Direct agent-to-agent communication creates hidden state. If Lovelace asks Friedman a question mid-implementation, the orchestrator loses visibility into what was decided and why. Hub-and-spoke keeps the orchestrator as the single source of truth for pipeline state.

But hub-and-spoke creates its own risk: the orchestrator becomes a bottleneck for context, and its interpretation of each station's output anchors every downstream station.

## Why Feature Directory Communication

Early versions of the pipeline used orchestrator-curated context briefs. Friday read each station's output, summarized the key decisions, and passed that summary to the next station. This seemed efficient: each agent got exactly the context it needed, pre-digested and focused.

The problem is anchoring. When the orchestrator summarizes a design document and passes that summary to the reviewer, the reviewer's scope collapses to the orchestrator's interpretation of the design. If the design missed a call site, the summary misses it too, and the reviewer inherits that blind spot. In one observed failure, a design identified two call sites for a type signature change. The orchestrator passed that scope to every downstream station. The reviewer verified "all direct call sites pass the correct type" and approved. But transitive callers two hops up still carried the old type signature, and the bug shipped through five stations without detection.

The root cause was not carelessness. Every station did its job against the scope it received. The scope was wrong because the orchestrator's summary became the authoritative frame, and no station had the independence to challenge it.

The fix is structural: agents communicate through the feature directory, not through the orchestrator. Each station writes its artifact (`babbage_1.md`, `friedman_1.md`, etc.) to `scratch/output/_<feature-slug>/`. Each agent's definition tells it what to look for in the feature directory and how to use it. The orchestrator provides the feature slug and work location. That's it.

This changes the orchestrator's role from context curator to sequencer. Friday decides who goes next and whether the pipeline advances or loops back. Friday does not decide what the next agent knows.

The iteration loop is the one place Friday relays information between stations. When the reviewer finds blockers, Friday extracts what is broken and where, without the reviewer's reasoning or suggested fixes. The implementer reads the code at the cited locations and derives the fix. If she can't see the problem from the code alone, that's a signal to escalate, not to add more orchestrator context.

## Why Read-Only on External Systems

Agents fetch data from external systems. They never modify them. No posting comments, no closing tickets, no updating statuses.

The cost of a bad read is wasted time. The cost of a bad write is visible to others — a wrong comment on a PR, a ticket closed prematurely, a status changed incorrectly. The asymmetry justifies the constraint. The user decides what gets written externally and when.

## Why Codebase-Native

Agents match the patterns already in the codebase: naming, structure, error handling, import style. They don't improve adjacent code, impose a preferred style, or introduce abstractions beyond what was asked.

Code that looks like it was written by a different person — even if it's "better" — creates friction. Reviewers spend time on style instead of substance. Teammates wonder who changed the conventions. The goal is code that reads as if the user wrote it.

## Why Behavioral Enforcement via Hooks

Rules tell agents what to do. Hooks ensure they actually do it.

Rules are prompt-level instructions. They work most of the time but degrade under context pressure. PreToolUse hooks intercept tool calls before execution and reject violations mechanically. Rules cover judgment calls (when to dispatch vs. handle inline). Hooks cover bright lines (never chain commands, never use `git -C`).

## Why Scratch is Ephemeral

Agent output — designs, reviews, validation plans, handoffs — lives in `scratch/output/`. These are session artifacts, not permanent records. They're either promoted into the target repo (as code, tests, or commits) or they expire.

Treating scratch as permanent storage creates a secondary codebase that grows without bounds and drifts from the actual code. The code is the source of truth. Scratch is working memory.

## Why `local/` Directories

Framework content (agents, rules, protocols) is generic — it works in any codebase for any user. Deployment-specific content (your protocols, your rules, your scripts) lives in `local/` subdirectories.

This separation matters for two reasons. First, upstream updates to the framework don't conflict with your customizations — they live in different directories. Second, it makes the boundary explicit: if you're writing something that only applies to your workflow, it goes in `local/`. If it would be useful to any deployment, it goes in the framework.
