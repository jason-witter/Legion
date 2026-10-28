# History cut from ambient rules, 2026-10-27 trim

The ambient rules were trimmed to cut the always-loaded instruction footprint. Constraints stayed in the rules; the history and rationale below were cut from them. Rewording-only cuts are not repeated here.

## orchestrator-report-brevity

Why state beats path: narrating a pipeline's history costs the user twice. They have to hold a sequence of superseded states in their head, and the present state, the only one that is true, arrives last and compressed. A reader who was not watching the pipeline cannot tell which of the descriptions they just read is the live one. "Round 1 summed the wrong grain, round 2 counted the wrong population, so round 3 restructured the expression" is a changelog. "The total is a sum over line items, each carrying its own order's rate, so no count can disagree with a rate" is the state, and it is shorter.

The section was added 2026-09-15, on the fourth such reply in one session, after two earlier corrections on the comparative habit (now `protocols/superseded-output-is-not-a-baseline.md`, which covers benchmarking a deliverable against its predecessor; this section covers narrating the pipeline's own internal history as if the sequence were the finding).

The rule's original worked example was a numerics report that ran six paragraphs on an implementer overriding both the design and its critique on a both-zero add scale rule, against a three-line version: "Numerics landed: 283 passing, verified. Dual review pass running. One item flagged for a second read ... Read-layer round four still needs your call."
## no-rule-free-forks

The rule's original premise was that general-purpose and Explore subagents do not inherit `rules/`, illustrated by a general-purpose agent handed PR-comment parsing that wrote a `python3 - <<'PYEOF'` heredoc and a `while true; do ... || echo 0; done` poll loop, both of which prompted mid-run. The published harness docs (sub-agents, "What loads at startup") say non-fork subagents receive the full CLAUDE.md hierarchy including project and user rules; only Explore, Plan and `omitClaudeMd` agents do not. The premise was corrected. The original incident's cause is not established.
