# Review Cycle Output

Governs the artifact shape and output convention for agent definition review cycles.

## Parameters

- `agent-slug` — kebab-case name of the agent under review (e.g., `grace`, `kelly`). Caller-supplied or derived from the agent's name.
- `date` — `YYYY-MM-DD` of the current session. Used to construct the output path.
- `cross-referenced-agents` — list of agent names consulted during the roster overlap check. Used to populate the report header.

## Steps

1. **Determine the slug** — For a single-agent cycle, use `iris-<agent-slug>` (e.g., `iris-grace`). For a multi-agent comparison, use a combined slug listing all agents reviewed (e.g., `iris-kelly-vera-overlap`).

2. **Write the report** to `scratch/output/<date>/<slug>/review.md`. `scratch/` resolves to the HopLegion repo per `rules/scratch-path-resolution.md`. See format below.

3. **Report the path** to the caller.

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

## Edge Cases

- Reports are always written to disk. Review findings are consumed by Vera and the orchestrator across session boundaries, not from chat history.
- Resolve the Legion repo path from the additionalDirectory registration or context before writing. Use absolute paths for all file operations.
- If the output directory does not exist, create it before writing.
- For multi-agent comparison cycles, the combined slug should list agents in the order they were reviewed (e.g., `iris-kelly-vera-overlap`, not alphabetically forced).
