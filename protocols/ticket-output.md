# Ticket Output

Governs the artifact shape, required fields, and output convention for ticket writing.

## Parameters

- `ticket-slug` — kebab-case identifier derived from the ticket title (e.g., `rename-adjustment-field`). Caller-supplied or derived from the title: lowercase, hyphenated, 3–5 words.
- `date` — `YYYY-MM-DD` of the current session. Used to construct output paths.
- `origin` — What triggered this ticket. One of: `pipeline-overflow`, `backlog-enrichment`, or `design-capture`. Used to populate the Source field.

## Steps

1. **Determine the slug** — If not supplied, derive from the ticket title: lowercase, hyphenated, concise (3–5 words).

2. **Write the ticket file** to `scratch/output/<date>/tickets/<ticket-slug>.md`. See format below.

3. **Report the path** to the caller.

## Ticket Format

```markdown
**Source:** <origin context — see Origin Tracking below>

**Title:** <concise, imperative verb phrase>

**Description:** <what the problem is, why it matters, what context led to surfacing it>

**Acceptance criteria:**
- <concrete, verifiable condition>
- <concrete, verifiable condition>
```

Source, Title, Description, and Acceptance criteria are required. Additional fields (e.g., scope notes, affected files, migration impact) are included when the ticket writer judges them useful for dispatch — not mandated by this protocol.

## Origin Tracking

The **Source** field records where the ticket came from. Format varies by origin:

- **Pipeline overflow** — `Pipeline overflow: <task or PR name>. <One sentence on what was being worked on when this surfaced.>`
- **Backlog enrichment** — `Backlog enrichment: <original ticket identifier>. Original intent preserved; structure added.`
- **Design capture** — `Design capture: <agent> flagged this during <task name>.`

For backlog enrichment, the original ticket identifier appears in Source so the caller can match this output to the sparse input item.

## Edge Cases

- If the observation is too vague to produce a scoped ticket without guessing at intent, return a gap statement rather than speculating. Do not produce a ticket with fabricated scope.
- If multiple tickets surface from a single dispatch (e.g., a reviewer flags two distinct issues), write one file per ticket with distinct slugs.
- Resolve the Legion repo path from the additionalDirectory registration or context before writing. Use absolute paths for all file operations.
- If the output directory does not exist, create it before writing.
