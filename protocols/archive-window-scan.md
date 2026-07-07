# archive-window-scan

Walks the local `scratch/output/archive/` tree and inventories feature directories whose most recent file mtime falls inside a date window. Implemented by `scripts/local/archive-window-scan.sh`; this protocol is the invocation contract.

Self-mode only (the archive is local to the user and cannot reflect a peer's work). Read-only.

## Invocation

```bash
scripts/local/archive-window-scan.sh <window-start> <window-end> <out-file>
```

- Dates are ISO (`YYYY-MM-DD`), inclusive, compared in the local timezone.
- `out-file` is normally `<feature_dir>/archive-inventory.md`.
- `ARCHIVE_ROOT` (env) overrides the default `<framework_repo>/scratch/output/archive/`.

## Output

A single artifact conforming to `cycle-inventory-output.md` (source = `archive`): header block, reverse-chronological item blocks with first-1KB summary-doc excerpts, sparse markers, Summary block, Aggregates by archive month.

## Semantics

- File mtimes decide window membership, not directory mtimes: the archive sweep touches directories, so directory mtimes are unreliable.
- Summary-doc preference order: `findings.md` > `design.md` > `handoff_*.md` (highest N) > `summary.md` > largest top-level `.md`. None found marks the item sparse.
- Directories named `inbox`, `_inbox`, or `reviews` are excluded (staging and point-in-time reports, not feature work). Empty directories are excluded.
- A missing archive root is a config error (exit 1), not a zero-result case. Zero in-window directories still writes a `Count: 0` artifact, because a missing file is ambiguous with a fetch failure.
