# Design Output

Governs the artifact shape and output convention for technical design work.

## Parameters

- `task-slug` — kebab-case identifier for the task (e.g., `add-payment-validation`). Caller-supplied or derived from the task description.
- `date` — `YYYY-MM-DD` of the current session. Caller-supplied — the agent must not infer this from input paths or artifact names. If not supplied, ask the caller before proceeding.

## Steps

1. **Determine the slug** — If not supplied, derive from the task name: lowercase, hyphenated, concise (3–5 words).

2. **Write the design document** to `scratch/output/<date>/designs/<task-slug>.md`. See format below. This is the handoff to the implementer.

3. **Report the path** to the caller.

## Design Document Format

The design document is a handoff instrument for the implementer. It states the chosen approach and what to build.

```markdown
## Task: [Task name or brief description]

### Approach
[One paragraph. The chosen direction and the deciding reason.]

### Affected Files
- `path/to/file.py` — [what changes]
- `path/to/other.py` — [what changes]

### Interface Contracts
[Function signatures, class interfaces, data shapes — whatever is relevant]

### Data Flow
[How data moves through this change, if non-trivial]

### Test Strategy
[What to test: unit, integration, edge cases]

### Risks and Edge Cases
[Known failure modes and boundary conditions. Call out any that apply: security
implications, database or schema changes, customer-facing behavior changes,
performance impact. If none apply, say so briefly — the absence is worth stating.]

### Open Questions
[Anything that requires a decision before implementation can proceed]
```

For straightforward tasks, inline notes suffice — not every task needs all sections. Use judgment: if the implementer could build this correctly from three sentences, write three sentences. Even a brief design should be written to disk when it will be passed to an implementer by path.

## Edge Cases

- Resolve the Legion repo path from the additionalDirectory registration or context before writing. Use absolute paths for all file operations.
- If the output directory does not exist, create it before writing.
