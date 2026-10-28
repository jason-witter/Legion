# Triage Output

Governs the artifact shape, path, and file naming for a backlog triage queue.

## Parameters

- `date` — `YYYY-MM-DD` of the current session.
- `batch` — the section and priority slice this dispatch covers (`inbox`, `backlog-p1`, `backlog-unprioritized`, `on-deck`). Supplied by the dispatch.

## Steps

1. **Write the queue document** to `scratch/output/<date>/backlog-triage/assessment-<batch>.md`, using the `batch` value verbatim in the filename. Triage fans out one instance per batch, so a bare `assessment.md` is never a valid target: concurrent instances would write one filename and the last writer would destroy the earlier queues. `scratch/` resolves to the framework repo per `rules/scratch-path-resolution.md`. See format below.

2. **Report the path** to the caller.

## Reserved Names

Two siblings in `backlog-triage/` belong to other stations. Never write to either:

- `backlog-snapshot.md` — the Asana fetch artifact, which is triage input.
- `mob-queue.md` — the assembled handoff the orchestrator writes after design, per `protocols/local/backlog-triage-pipeline.md`.

## Queue Document Format

```
BACKLOG ASSESSMENT
Batch: <batch — the section and priority filter covered>
Tasks reviewed: <N in this batch>
Assessment date: <YYYY-MM-DD>

---

DISPATCH QUEUE (<N> items, ranked within this batch)

1. [<Asana task GID>] <Task name>
   Priority: <value from available signal>
   Category: <section or category>
   Rationale: <one sentence — why this ranks here and what makes it ready>
   Babbage context: <what to build, acceptance criteria, technical constraints, scope limits>

2. [<Asana task GID>] <Task name>
   ...

---

NEEDS HUMAN INPUT (<N> items)

[<Asana task GID>] <Task name>
  Gap: <one sentence — the specific missing piece that prevents autonomous dispatch>

[<Asana task GID>] <Task name>
  Gap: <one sentence>

---

NOTES
<Optional: patterns observed, systemic issues in this batch worth surfacing>
```

The identifier is the Asana task GID, verbatim. Downstream dispatches name this file plus a GID to locate an item, so a shortened or substituted identifier makes the item unreachable.

Counts and ranking are scoped to this batch. Rank within the batch only; the orchestrator re-ranks across batches when it merges.

Sections with zero items are emitted with count 0. The dispatch queue always comes first — it is the primary output. Notes are brief; do not editorialize.

## Edge Cases

- A second triage pass in the same session writes to a sibling directory, `backlog-triage-2/`, keeping the same per-batch filenames.
