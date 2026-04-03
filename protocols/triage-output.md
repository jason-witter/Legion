# Triage Output

Governs the artifact shape and output convention for backlog triage work.

## Parameters

- `date` — `YYYY-MM-DD` of the current session. Used to construct the output path.

## Steps

1. **Write the triage document** to `scratch/output/<date>/backlog-triage/assessment.md`. See format below.

2. **Report the path** to the caller.

## Triage Document Format

```
BACKLOG ASSESSMENT
Tasks reviewed: <N>
Assessment date: <YYYY-MM-DD>

---

DISPATCH QUEUE (<N> items, ranked)

1. [<identifier>] <Task name>
   Priority: <value from available signal>
   Category: <section or category>
   Rationale: <one sentence — why this ranks here and what makes it ready>
   Babbage context: <what to build, acceptance criteria, technical constraints, scope limits>

2. [<identifier>] <Task name>
   ...

---

NEEDS HUMAN INPUT (<N> items)

[<identifier>] <Task name>
  Gap: <one sentence — the specific missing piece that prevents autonomous dispatch>

[<identifier>] <Task name>
  Gap: <one sentence>

---

NOTES
<Optional: patterns observed, systemic issues in the backlog worth surfacing>
```

Sections with zero items are emitted with count 0. The dispatch queue always comes first — it is the primary output. Notes are brief; do not editorialize.

## Edge Cases

- If the output directory does not exist, create it before writing.
- Resolve the Legion repo path from the additionalDirectory registration or context before writing. Use absolute paths for all file operations.
- A single triage run produces one file. If a session produces multiple triage passes, use a distinguishing suffix: `backlog-triage-2/assessment.md`.
