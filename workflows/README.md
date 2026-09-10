# Workflows

Pilot scripts for the Claude Code Workflow tool. A workflow encodes pipeline control flow (station order, loop caps, artifact checks) as deterministic JavaScript instead of prose the orchestrator re-derives each run. The prose protocols remain the authority on judgment; the script is the authority on sequencing.

## mob-iteration.workflow.js

One full mob pipeline iteration: Babbage design, Oppenheimer critique with a block-back loop (cap 2 returns to the architect), Lovelace implementation, a Friedman review loop with Lovelace fixes (cap 3 iterations, single reviewer pass per current policy), Curie validation, Asimov tone scrub. Between stations the script verifies the expected artifact landed in the feature directory (protocols/post-dispatch-artifact-verify.md Step 1 as code) and halts with a structured failure rather than advancing on a missing artifact. Loop-cap exhaustion returns the blocker list instead of looping silently.

### Invocation

The orchestrator invokes the Workflow tool with:

```
scriptPath: <framework repo>/workflows/mob-iteration.workflow.js
args: {
  "featureSlug": "wallet-forfeiture-sku-fix",
  "taskDescription": "<raw task text, ticket body, error logs>",
  "workLocation": "<worktree path or repo root>",
  "branchName": "jrw/wallet_forfeiture_sku_fix",
  "mode": "fresh"            // or "fixup" for work stacking on a live PR
}
```

Station dispatches follow rules/dispatch-shape.md: intent, inputs (slug, work location, branch), scope. No prior-artifact summaries; stations orient from the feature directory. The one sanctioned relay is the iteration loop's terse blocker list (location plus one-sentence problem), matching the mob protocol's compression-without-interpretation rule.

Stations inherit model and effort from their agent definitions' frontmatter. Per-run overrides are possible by editing the `agent()` opts (`model`, `effort`) for a station, but the script deliberately ships without them.

### What the pilot deliberately does not do

- **Worktree lifecycle and branch transport.** The orchestrator prepares the worktree or WIP branch before invoking (fetch, stale-WIP cleanup, branch creation) and performs squash, kernel composition, and transport after the workflow returns, per rules/local/no-worktree-isolation.md and the deployment bridge protocol. The script's `mode` arg only selects the base-verification instruction each code-producing station runs first.
- **Scope-proportional station skipping.** rules/scope-proportional-pipeline.md remains an orchestrator pre-decision. If the task warrants a reduced pipeline, do not use this script yet; a later revision may gate stations via args.
- **PR description drafting and the commit-body kernel.** The orchestrator composes both from the returned knownRisks/openQuestions and the feature-directory artifacts.
- **Rule inheritance for the two helper checks.** The artifact-numbering and artifact-verify helpers run as plain workflow subagents (single ls / script invocations, rule-neutral). Named stations run as their full agent definitions via `agentType`.

### First-real-run comparison checklist

Run one real coding task through the script and compare against prose execution on:

1. **Wall clock** end to end, and per phase (the progress tree timestamps the stations).
2. **Artifact completeness**: every station artifact present, correctly numbered, no backfills needed.
3. **Loop behavior**: did blockers route with the terse list only; did caps hold; did a cap exhaustion return a usable blocker report.
4. **Dispatch fidelity**: station prompts stayed three-field; no anchoring content crept in.
5. **Failure legibility**: if anything halted, was the structured failure enough to resume by hand without archaeology.

If the pilot wins on 1 and 5 without losing on 2 through 4, promote the pattern: encode pre-ship review and the queue fan-outs the same way, and shrink the corresponding protocol prose to judgment plus a pointer at the script.
