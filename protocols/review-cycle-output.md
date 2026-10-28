# Review Cycle Output

Governs the artifact shape and output convention for agent definition review cycles.

## Parameters

- `agent-slug` — kebab-case name of the agent under review (e.g., `grace`, `kelly`). Caller-supplied or derived from the agent's name.
- `date` — `YYYY-MM-DD` of the current session. Used to construct the output path for a standalone cycle.
- `cross-referenced-agents` — list of agent names consulted during the roster overlap check. Used to populate the report header.
- `feature-slug` — optional. Supplied when the cycle belongs to a framework change that has a feature directory; it moves the report there.
- `run-scope` — optional lowercase token naming the surface under review (e.g. `readset`). Supplied by the dispatch alongside a feature slug when the feature holds more than one run; never invented by the station.

## Steps

1. **Determine the destination** — Two shapes, decided by whether the dispatch supplies a feature slug:

   ```
   scratch/output/_<feature-slug>/iris_<N>.md                 cycle inside a feature's run
   scratch/output/_<feature-slug>/iris_<run-scope>_<N>.md     feature with several runs
   scratch/output/<date>/iris-<agent-slug>/review.md          standalone cycle
   ```

   A cycle dispatched as a station of a framework change is a pipeline artifact of that change and belongs with the rest of the run, where the work it reviews is recorded. A cycle asked for on its own belongs in the dated directory. `scratch/` resolves to the framework repo per `rules/scratch-path-resolution.md`.

2. **Determine the filename** — In a feature directory, run `scripts/next-artifact.sh <feature-dir> iris [run-scope]` and use what it prints; N is counted inside the (agent, run) pair (`rules/feature-directory-lifecycle.md`). For a standalone cycle, the slug is `iris-<agent-slug>` for one agent (e.g. `iris-grace`), or a combined slug listing all agents reviewed, in review order, for a comparison (e.g. `iris-kelly-vera-overlap`).

3. **Write the report.** See format below.

4. **Report the full filename** to the caller, not the directory. What reaches Vera or the orchestrator is the file a dispatch names (`rules/dispatch-shape.md`).

## Report Format

```markdown
## Iris Review Cycle — [Agent Name]
Date: [date]
Reviewed against: [list of agents cross-referenced], VISION.md

### Scope Clarity
[Assessment]

### Roster Overlap
[Assessment — flag specific agents if overlap found]

### Personality-Role Alignment
[Assessment]

### VISION.md Drift
[Assessment]

### Recommended Actions
[Itemized list with routing: Vera / Kelly / No action]
```

All five sections are required. Assessments are grounded in the agent's definition text, the roster, and VISION.md — no generalities.

Routing options in Recommended Actions:
- **No action** — sharp, aligned, no drift
- **Hand to Vera** — scope or personality redesign required
- **Hand to Kelly** — definition text needs revision without structural redesign

## Directives and Reasoning

Vera acts on this report without the session that produced it, so what it asks for has to be separable from what it observed.

- **Directives bind.** Recommended Actions, each with its routing. That section is the report's actionable content in full.
- **Reasoning explains.** Scope Clarity, Roster Overlap, Personality-Role Alignment, and VISION.md Drift. They establish what the recommendations rest on.

A recommendation that appears only inside an assessment section is not actionable: the reader is looking at one list, and an ask left in the prose above it is an ask nobody is assigned. Every action lands in Recommended Actions, even when the assessment above it already made the case.

### Claims about a file carry `path:line`

Every statement about a definition, rule, or protocol carries its location: `agents/friedman.md:32`, not "Friedman's definition reads the feature directory." Definitions move under edit like any other file, so Vera follows the citation rather than inheriting the reading. An uncited claim about a file is unverified and is reported that way (`rules/code-facts-from-the-tree.md`).

This is also what makes a finding cheap to check. A quoted line plus its location either matches the file or the finding is wrong, in one step, for whoever picks the report up.

## Edge Cases

- Reports are always written to disk. Review findings are consumed by Vera and the orchestrator across session boundaries, not from chat history.
- A re-review of the same agent in a feature directory takes the next N in the run. A standalone re-review on the same date would overwrite `review.md`, so route a re-review through a feature directory, or hand-suffix the slug and say so in the report.
