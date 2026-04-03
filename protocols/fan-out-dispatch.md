# Fan-Out Dispatch

Orchestrate a parallel multi-agent operation against a list of independent work items. A single fetch retrieves a structured list once; the orchestrator decomposes it into discrete items and dispatches one agent instance per item in parallel; results are collected and synthesized into a single consolidated output.

## Usage

Invoke when a task consists of N independent units of work that share a common agent type and can be processed concurrently. The canonical trigger is: "review all the PRs in my queue," "fetch feedback on all my open PRs," or any request where the natural answer is one agent run per item in a list.

This protocol does not apply to sequential pipelines where stations depend on each other's output — use `mob-pipeline` for those.

## Lifecycle

### Phase 1 — Fetch

The orchestrator selects the best-fit agent for retrieving the list data and invokes it with the appropriate fetch protocol. The fetch must return a list of discrete items, each containing enough identity and context to dispatch a consuming agent independently.

If the fetch result needs trimming, the orchestrator filters before dispatch — do not pass full API dumps as agent prompts.

**One fetch, shared across all agents.** Do not dispatch agents that perform their own redundant list fetch. The point of centralized fetching is to avoid N agents each retrieving the same list.

### Phase 2 — Decompose

Examine the fetch result and enumerate the discrete work items. For each item, determine:

1. **Which agent type handles it** — typically fixed per operation (all items go to the same agent type)
2. **What per-item context to include in the prompt** — extract the minimum necessary fields from the fetch result for that item
3. **Whether any items should be skipped** — apply any pre-filters before dispatch (draft PRs, already-reviewed items, items outside scope), and note skipped items in the synthesis

Decomposition is the orchestrator's decision. Do not dispatch first and filter inside agents.

### Phase 3 — Dispatch

Dispatch all N agent instances simultaneously as background tasks. Each instance receives:

- Its assigned work item's identity and metadata
- The task description scoped to that item only
- Any shared context that applies to all items (e.g., the repo slug, review criteria)

No agent instance receives the full list or awareness of the other instances. Each operates independently.

Agents that write output artifacts use a slug that includes the item identifier — for example, `pr-265473` where `265473` is the item identifier. This keeps artifacts identifiable and avoids collisions.

### Phase 4 — Synthesize

Collect results as agents complete. Do not wait for all agents before beginning synthesis — incorporate results as they arrive.

The consolidated summary covers:
- Total items dispatched, completed, and failed
- Key findings or outcomes per item, presented uniformly
- Any items that were skipped and why
- Any items that failed and what was recoverable from the partial result

Synthesis is a narrative, not a raw concatenation. Each item's result is distilled to what the user needs to act on — not the full agent output.

## Error Handling

Individual agent failures must not block the rest of the dispatch. When one instance fails:

1. Note the failure against the item identifier
2. Continue collecting results from the remaining instances
3. Include the failed item in synthesis with a clear failure note and the error message if available
4. Do not retry automatically — surface the failure and let the user decide

If the fetch itself fails, nothing is dispatched. Surface the fetch error and stop.

If all agents fail, the synthesis reports total failure. Do not attempt to re-run without user instruction.

## Prompt Construction

Per-item prompts follow this structure:

```
[Agent-specific task description, scoped to this item]

Item: [identifier — e.g., PR #265473 in owner/repo]
[Minimum metadata fields from the fetch result needed to begin work]

[Any shared context that applies to all items]
```

Keep prompts minimal. Do not include the full fetch result, the list of other items being processed, or any meta-commentary about the fan-out operation itself. The agent should have exactly what it needs to do its job and nothing more.

## Examples

**PR review fan-out**: Fetch agent retrieves the review queue. Orchestrator decomposes the result into individual PR identifiers with repo and title metadata. N review agent instances are dispatched in parallel, one per PR. Each produces a review report. Synthesis presents a triage table: PR number, title, recommendation, top finding.

**PR feedback fan-out**: Fetch agent retrieves authored PRs with review comments. Orchestrator filters to PRs with unresolved feedback. N digest agent instances are dispatched in parallel. Each produces an action digest. Synthesis presents a priority-ordered list of PRs requiring action.

## Constraints

- The fetch must produce a decomposable list. A fetch that returns a single blob requiring secondary fetches per item is not suitable for this pattern — extend the fetch protocol first.
- This pattern is for homogeneous workloads: same agent type, same task structure, independent items. Mixed-agent fan-outs (different agents for different item types) should be decomposed into separate fan-out operations.
- The orchestrator does not parallelize across different fetch sources in a single fan-out. One fetch, one agent type, N items.
- Background agents cannot write files in `acceptEdits` mode. If consuming agents produce file artifacts, verify the execution context supports background file writes — or have agents return output to the orchestrator for writing.
