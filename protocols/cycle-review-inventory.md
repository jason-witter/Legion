# cycle-review-inventory

Orchestrate a parameterized, read-only inventory of an engineer's work over a date window. Produces one consolidated artifact per source (PRs, Asana, Notion, archive) plus a manifest. Synthesis into a writeup is a separate, deferred concern.

Read-only. Does not post, comment, or modify any external system.

## Prerequisites

- Grace agent available for dispatch
- `gh` CLI authenticated for PR fetches
- Asana MCP server configured and authenticated
- Notion MCP server configured and authenticated
- Integration protocols installed: `authored-prs-window-fetch.md`, `asana-window-fetch.md`, `notion-window-fetch.md`, `archive-window-scan.md`
- Output contract protocol installed: `cycle-inventory-output.md`

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `target_mode` | `self` | `self` (authenticated user) or `peer` (other engineer). |
| `identity` | resolved (self) / required (peer) | Identity object, see schema below. Self mode resolves at Step 0; peer mode requires caller-supplied object. |
| `window_start` | required | ISO date, inclusive. No cycle-date defaulting. |
| `window_end` | required | ISO date, inclusive. |
| `window_display` | `<start>_<end>` | Short string used in the feature directory name (e.g., `2026h1`). |
| `sources` | `prs,asana,notion,archive` | Comma-separated subset. Archive is silently skipped in peer mode. |

## Identity Object Schema

```yaml
identity:
  github_login: <login>          # ground-truth attribution for PRs
  email: <primary email>         # ground-truth for Notion/Asana queries
  asana_user_gid: <gid>          # explicit GID, never name-matched
  notion_user_id: <uuid>         # explicit UUID, never name-matched
  display_name: <name>           # output framing only, never for filtering
```

**Peer mode hard requirement:** `github_login`, `asana_user_gid`, and `notion_user_id` must all be present. Refuse to proceed if any is missing. Name-only peer mode is a failure mode; reject it explicitly with a message listing the missing fields. Do not infer GIDs or user IDs from display names.

## Execution Steps

### Step 0 — Identity resolve (self mode only)

Skip in peer mode. The caller supplies the full identity object.

In self mode, resolve identity inline before dispatch. Inline is deliberate: this step gates every dispatch that follows, and it returns five short values rather than fetched content.

1. `gh api user --jq '.login'` → `github_login`
2. `git config user.email` → `email`
3. Asana MCP: `asana_typeahead_search` for the user by email, extract the `gid` → `asana_user_gid`
4. Notion MCP: search for the user by email, extract the user ID → `notion_user_id`
5. Use the GitHub `name` field or `git config user.name` for `display_name`

Cache the resolved object at `<feature-dir>/identity.json` so re-runs are deterministic.

If any field cannot be resolved, surface the gap and stop. Do not proceed with partial identity.

### Step 1 — Create feature directory

Determine `target-slug`:
- Self mode: `self`
- Peer mode: the peer's `github_login`

Create `scratch/output/_cycle-review-<target-slug>-<window_display>/`. `scratch/` resolves to the framework repo per `rules/scratch-path-resolution.md`.

Write `identity.json` to the feature directory.

### Step 2 — Parallel fan-out

All four stages are background Grace dispatches per `protocols/fan-out-dispatch.md`, launched concurrently. Each writes its own artifact; no stage feeds another, and no fetched content passes through the orchestrator's context.

**2a. PR inventory** — `authored-prs-window-fetch`. Pass `github_login`, `window_start`, `window_end`. Output target: `<feature-dir>/prs-inventory.md`.

**2b. Asana inventory** — `asana-window-fetch`. Pass `asana_user_gid`, `window_start`, `window_end`, `feature_dir`. Output target: `<feature-dir>/asana-inventory.md`.

**2c. Notion inventory** — `notion-window-fetch`. Pass `notion_user_id`, `display_name`, `window_start`, `window_end`, `feature_dir`. Output target: `<feature-dir>/notion-inventory.md`. Side artifacts land under `<feature-dir>/.notion-pages/`.

**2d. Archive scan** — Skip in peer mode. In self mode, `archive-window-scan`. Pass `window_start`, `window_end`. Output target: `<feature-dir>/archive-inventory.md`.

All four artifacts conform to the format contract in `cycle-inventory-output.md`.

Skip any source listed outside the `sources` parameter.

### Step 3 — Verify artifacts and emit manifest

Apply `protocols/post-dispatch-artifact-verify.md` to each Grace dispatch. Backfill from task notifications if any agent skipped the Write tool.

After all expected artifacts are on disk, write `<feature-dir>/manifest.md` summarizing what was produced. See Output Format below.

## Output Format

The manifest is the only top-level output emitted to the caller. Per-source artifacts are referenced by path.

```markdown
# Cycle Review Inventory Manifest

**Target:** <display_name> (@<github_login>)
**Mode:** <self | peer>
**Window:** <window_start> to <window_end>
**Feature directory:** <absolute path>
**Generated:** <ISO 8601>

## Artifacts

- `prs-inventory.md` — <N> PRs (<sparse_count> sparse)
- `asana-inventory.md` — <N> tasks (<sparse_count> sparse)
- `notion-inventory.md` — <N> pages (<sparse_count> sparse)
- `archive-inventory.md` — <N> feature directories  [self only]

## Skipped Sources

<source>: <reason>

[Omit section if nothing skipped]

## Errors

<source>: <error summary>

[Omit section if no errors]
```

Sparse counts come from each artifact's own Summary section.

## Error Handling

- **Identity resolve fails (self mode)**: Surface which field could not be resolved and stop. Do not proceed with partial identity.
- **Peer identity object missing required fields**: List the missing fields and stop. Do not attempt fallback resolution.
- **A dispatch hands back on an unreachable MCP server**: not a source failure. Run that source's protocol inline per its own fallback path and keep the remaining dispatches running. Record it in the manifest only if the inline run also fails.
- **One source fetch fails**: Record the failure in the manifest under Errors. Continue with the remaining sources.
- **All sources fail**: Emit the manifest with all errors recorded. Do not synthesize a partial inventory.
- **Window inverted (`window_end` before `window_start`)**: Surface and stop.

## Edge Cases

- **`sources` excludes all four**: Nothing to do. Report and stop.
- **Peer mode + `sources` includes `archive`**: Silently drop `archive` from the active sources list. Note in the manifest's Skipped Sources section.
- **Feature directory already exists from a prior run**: Overwrite artifacts in place. Re-running is the supported re-fetch path. `identity.json` is overwritten too; if the caller wants to preserve a prior run, they should move the directory first.
- **Window spans a Notion or Asana account transition** (rare): The identity object is point-in-time. If the target changed their email or GID during the window, the fetch only sees activity under the current values. Surface this as a known limitation in the manifest if detectable.
