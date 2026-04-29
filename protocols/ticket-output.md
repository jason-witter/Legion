# Ticket Output

Governs the artifact shape, required fields, and output convention for ticket writing.

## Parameters

- `ticket-slug` — kebab-case identifier derived from the ticket title (e.g., `rename-adjustment-field`). Caller-supplied or derived from the title: lowercase, hyphenated, 3–5 words.
- `feature-dir` — absolute path to the feature directory when invoked within a mob pipeline context (`scratch/output/_<slug>/` or `scratch/output/_pr-<number>-<slug>/`). Omitted for standalone invocations.
- `origin` — What triggered this ticket. One of: `pipeline-overflow`, `backlog-enrichment`, or `design-capture`. Used to populate the Source field.

## Steps

1. **Determine the slug** — If not supplied, derive from the ticket title: lowercase, hyphenated, concise (3–5 words).

2. **Determine the output path.**
   - If `feature-dir` is supplied, write to `<feature-dir>/tickets/<ticket-slug>.md`. The feature directory already exists; create the `tickets/` subdirectory if needed. Use this path for tickets that belong to a specific task context: pipeline overflow captured during mob review, retroactive ticket writing from a Babbage design, design-capture items surfaced by Lovelace mid-implementation.
   - If `feature-dir` is not supplied, write to `scratch/output/_inbox/<ticket-slug>.md`. Use this path for standalone ticket writing unattached to a specific feature: backlog enrichment, design capture outside an active pipeline.

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

## Pasting Into Asana

Asana treats pasted raw markdown as preformatted text and wraps the entire content in a single code block. The paste workflow is: open the ticket file in a markdown preview (Cursor's preview is the reference), copy the rendered output, and paste that into Asana. The rendered text carries rich-text formatting that Asana accepts.

### Paragraph Separation

Blank-line paragraph breaks in markdown source render correctly in preview but collapse to near-zero vertical space once pasted into Asana — consecutive paragraphs read as one block. The workaround that survives the paste is an `&nbsp;` line between paragraphs:

```
**Description:** First paragraph of the problem.

&nbsp;

Second paragraph of the problem.

&nbsp;

Third paragraph.
```

The `&nbsp;` renders in preview as an empty line containing a non-breaking space, which pastes into Asana as a visible empty paragraph. Use this between every pair of prose paragraphs in any multi-paragraph field (`Description` most commonly).

Top-level label blocks (`**Source:**`, `**Title:**`, `**Description:**`, `**Acceptance criteria:**`) still separate with a single blank line, not `&nbsp;`. The label's own line break provides enough visual separation on its own. `&nbsp;` is only needed between prose paragraphs inside a field.

Lists do not need `&nbsp;` between items — bullets and numbered items render with their own spacing.

## Origin Tracking

The **Source** field records where the ticket came from at a level the external reader (Asana, Linear) can parse without context. Per `rules/user-authorship.md`, the ticket content reads as the user's own work — no agent names, no internal scratch path references, no pipeline-stage vocabulary. Ticket files are staged in scratch but their destination is external.

Format varies by origin:

- **Pipeline overflow** — `Pipeline overflow: surfaced during <task or PR name>. <One sentence on what was being worked on when this surfaced.>`
- **Backlog enrichment** — `Backlog enrichment: <original ticket identifier>. Original intent preserved; structure added.`
- **Design capture** — `Design capture: surfaced during <task name>.`

For backlog enrichment, the original ticket identifier appears in Source so the caller can match this output to the sparse input item.

References to design or implementation context inside the ticket body should point at user-facing locations: code paths, PR numbers, Notion doc names. Internal scratch artifacts (`scratch/output/_<slug>/babbage_3.md`, review reports, etc.) are not appropriate references.

## Edge Cases

- If the observation is too vague to produce a scoped ticket without guessing at intent, return a gap statement rather than speculating. Do not produce a ticket with fabricated scope.
- If multiple tickets surface from a single dispatch (e.g., a reviewer flags two distinct issues), write one file per ticket with distinct slugs.
- If `feature-dir` is supplied but does not exist, surface the error and stop — do not silently create an incorrect parent directory. The caller owns feature-directory creation.
- Resolve the HopLegion repo path from the additionalDirectory registration or context before writing. Use absolute paths for all file operations.
- Create the `_inbox/` or `tickets/` target directory if it does not exist.
