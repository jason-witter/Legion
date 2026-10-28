# Ticket Output

Governs the artifact shape, required fields, and output convention for ticket writing.

## Parameters

- `ticket-slug` — kebab-case identifier derived from the ticket title (e.g., `rename-adjustment-field`). Caller-supplied or derived from the title: lowercase, hyphenated, 3–5 words.
- `feature-dir` — absolute path to the feature directory when invoked within a mob pipeline context (`scratch/output/_<slug>/` or `scratch/output/_pr-<number>-<slug>/`). Omitted for standalone invocations.

## Steps

1. **Determine the slug** — If not supplied, derive from the ticket title: lowercase, hyphenated, concise (3–5 words).

2. **Determine the output path.**
   - If `feature-dir` is supplied, write to `<feature-dir>/tickets/<ticket-slug>.md`. The feature directory already exists; create the `tickets/` subdirectory if needed. Use this path for tickets that belong to a specific task context: pipeline overflow captured during mob review, retroactive ticket writing from a Babbage design, design-capture items surfaced by Lovelace mid-implementation.
   - If `feature-dir` is not supplied, write to `scratch/output/_inbox/<ticket-slug>.md`. Use this path for standalone ticket writing unattached to a specific feature: backlog enrichment, design capture outside an active pipeline.

3. **Report the path** to the caller. The caller verifies the file landed per `protocols/post-dispatch-artifact-verify.md` before handing the path on.

## Ticket Format

```markdown
**Title:** <concise, imperative verb phrase>

**Description:** <what the problem is, why it matters, what context led to surfacing it>
```

Title and Description are required. A section is included only when it carries real content: omit it entirely rather than writing "none" or "n/a" (for example, no Dependencies section when there are no dependencies). Additional fields (scope notes, dependencies, migration impact) appear only when the ticket writer has genuine content for them.

The register expectation — intent-first, drift-prone technical detail excluded — lives in Penkovsky's definition (`## House Style`). This protocol governs which sections exist; the definition governs how the body is written.

Per `rules/user-authorship.md`, ticket content reads as the user's own work: no agent names, no internal scratch path references, no pipeline-stage vocabulary. Ticket files are staged in scratch but their destination is external. References inside the ticket body point at user-facing locations (code paths, PR numbers, Notion doc names), not internal scratch artifacts (review reports, design documents, and the like).

## Pasting Into Asana

Asana treats pasted raw markdown as preformatted text and wraps the entire content in a single code block. The paste workflow is: open the ticket file in a markdown preview (Cursor's preview is the reference), copy the rendered output, and paste that into Asana. The rendered text carries rich-text formatting that Asana accepts.

### Pre-Paste Scrub

Before the paste workflow below, run the engineer-facing scrub per `rules/engineer-facing-handoff-scrub.md`: the Asimov tone-and-identifier pass. A ticket description is multi-sentence engineer-facing prose, so it is above the pass threshold.

### Paragraph Separation

Separate paragraphs with ordinary blank lines. The current preview-and-paste tooling preserves those breaks into Asana, so no special separator is needed.

## Edge Cases

- If the observation is too vague to produce a scoped ticket without guessing at intent, return a gap statement rather than speculating. Do not produce a ticket with fabricated scope.
- If multiple tickets surface from a single dispatch (e.g., a reviewer flags two distinct issues), write one file per ticket with distinct slugs.
- If `feature-dir` is supplied but does not exist, surface the error and stop — do not silently create an incorrect parent directory. The caller owns feature-directory creation. (The `_inbox/` or `tickets/` leaf directory is different: create it if absent, per `rules/scratch-path-resolution.md`.)
