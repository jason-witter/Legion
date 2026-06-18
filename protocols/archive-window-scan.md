# archive-window-scan

Walk the local `scratch/output/archive/` tree and identify feature directories with any file mtime within a date window. Produces a structured inventory artifact per `cycle-inventory-output.md` (source = `archive`).

Self-mode only. The archive is local to the user and cannot reflect a peer's work.

Read-only — does not modify any archived content.

## Prerequisites

- Read access to the framework repo's `scratch/output/archive/` tree
- Resolve the framework repo absolute path from the additionalDirectory registration before walking the filesystem

## Parameters

| Parameter | Description |
|-----------|-------------|
| `window_start` | ISO date, inclusive. Required. |
| `window_end` | ISO date, inclusive. Required. |
| `feature_dir` | Absolute path to the cycle-review feature directory (where output is written). Required. |
| `archive_root` | Absolute path to the archive root. Default: `<framework_repo>/scratch/output/archive/`. |

## Why File mtime, Not Directory mtime

The archive script touches directories during its sweep, so directory mtimes are unreliable. File mtimes inside each feature directory are stable and reflect actual work. Use them.

## Execution Steps

### Step 1 — Enumerate feature directories

The archive tree is laid out as `<archive_root>/<YYYY-MM>/<YYYY-MM-DD>/<feature-slug>/`. Walk three levels:

```bash
find <archive_root> -mindepth 3 -maxdepth 3 -type d
```

Each result is a candidate feature directory. Exclude:
- Directories named `inbox` (general clipboard staging, not feature work)
- Directories named `reviews` (point-in-time review reports, not feature work)

### Step 2 — Find the most recent file mtime per directory

For each candidate directory, find the most recent file mtime among all files at any depth:

```bash
find <feature-dir> -type f -printf '%T@ %p\n' | sort -nr | head -1
```

The `%T@` format gives mtime as a Unix timestamp; convert to ISO 8601 for output.

Note: `find -printf` is GNU find. On macOS without GNU find, use `stat -f '%m %N' "$f"` per file or install GNU find. The orchestrator's environment is the framework repo, typically macOS — prefer a portable approach:

```bash
find <feature-dir> -type f -exec stat -f '%m %N' {} \; | sort -nr | head -1
```

### Step 3 — Filter by window

Keep feature directories whose most recent file mtime falls within `[window_start, window_end]` (inclusive, comparing dates only — convert the timestamp to its date in the local timezone).

Discard directories whose most recent mtime is outside the window. They are not in-scope for this cycle.

### Step 4 — Identify the summary doc per directory

For each in-window directory, pick the most relevant summary doc by preference order:

1. `findings.md`
2. `design.md`
3. `handoff_*.md` — highest numeric suffix wins (e.g., `handoff_3.md` over `handoff_1.md`)
4. `summary.md`
5. The largest top-level `*.md` file by byte count

If none of these exist, the directory has no summary doc — mark sparse.

### Step 5 — Collect per-directory data

For each in-window directory:

- `slug` — the directory's basename
- `path` — absolute path
- `most_recent_mtime` — ISO 8601
- `file_count` — total file count at any depth
- `top_level_files` — names of files directly under the feature directory (not nested)
- `summary_doc_excerpt` — first 1KB of the chosen summary doc (raw markdown, not rendered)

### Step 6 — Assemble the artifact

Write to `<feature_dir>/archive-inventory.md` per `cycle-inventory-output.md` format:

- Header block: source = `archive`, count = N directories
- One item block per directory, ordered reverse-chronologically by `most_recent_mtime`
- The summary doc excerpt is the body
- Summary block with sparse and error counts

Mark a directory as sparse if no summary doc was found.

## Output

Produces a single artifact at `<feature_dir>/archive-inventory.md` conforming to `cycle-inventory-output.md`.

## Edge Cases

- **Archive root does not exist**: Surface the path and stop. The pipeline expects the archive root to exist; absence is a config error, not a zero-result case.
- **Zero directories in window**: Emit the artifact with `Count: 0`, an empty Items section, and `Summary: 0 items. 0 sparse. 0 errors.`
- **Directory contains only the exclusion names (e.g., a stray `inbox`)**: Already excluded in Step 1.
- **Summary doc exceeds 1KB**: The 1KB cap is a deliberate excerpt size — readers scan for context, not full reading. Do not raise it.
- **Symlinks inside feature dirs**: Follow them for mtime purposes if they point to files; do not follow into other directory trees.
- **Empty feature directory** (zero files): Exclude. An empty directory has no mtime to compare and no content to inventory.
- **Hidden files** (dotfiles): Include in the mtime scan. Some pipelines write `.handoff`, `.manifest`, or similar; ignoring them would skew the recency check.
