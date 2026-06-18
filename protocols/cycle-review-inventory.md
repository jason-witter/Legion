# cycle-review-inventory

Orchestrate a parameterized, read-only inventory of an engineer's work over a date window. Produces one consolidated artifact per source (PRs, Asana, Notion, archive) plus a manifest. Synthesis into a writeup is a separate, deferred concern.

Read-only — does not post, comment, or modify any external system.

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
| `identity` | resolved (self) / required (peer) | Identity object — see schema below. Self mode resolves at Step 0; peer mode requires caller-supplied object. |
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

**Peer mode hard requirement:** `github_login`, `asana_user_gid`, and `notion_user_id` must all be present. Refuse to proceed if any is missing. Name-only peer mode is a failure mode — reject it explicitly with a message listing the missing fields. Do not infer GIDs or user IDs from display names.

## Execution Steps

### Step 0 — Identity resolve (self mode only)

Skip in peer mode — the caller supplies the full identity object.

In self mode, resolve identity inline before dispatch:

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

Subagents cannot use MCP tools, so the Asana and Notion stages have their MCP-bound portions run inline in the orchestrator. The Grace-dispatched stages (PR, archive, and the Notion assembly step) run as background subagents.

The 2a (PR) and 2d (archive) dispatches launch concurrently with the start of 2b (Asana inline) and 2c (Notion inline). 2c's assembly step (a Grace dispatch) launches after the orchestrator finishes 2c's MCP-bound fetches.

**2a. PR inventory** — Dispatch Grace per `protocols/fan-out-dispatch.md` with the `authored-prs-window-fetch` integration protocol. Pass `github_login`, `window_start`, `window_end`. Output target: `<feature-dir>/prs-inventory.md`. Background.

**2b. Asana inventory** — Inline orchestrator work per `asana-window-fetch.md`. Pass `asana_user_gid`, `window_start`, `window_end`. The two `asana_search_tasks` calls land on disk (Step 1 typically auto-saves due to response size; Step 2 the orchestrator writes itself). Final assembly is a single `jq` invocation producing `<feature-dir>/asana-inventory.md`.

**2c. Notion inventory** — Mixed mode per `notion-window-fetch.md`.

1. Multi-query workspace search (orchestrator, MCP) with the `created_by_user_ids` and `created_date_range` filters under `content_search_mode: "workspace_search"`. Union by page ID.
2. Per-page fetch (orchestrator, MCP) writing each response to `<feature-dir>/.notion-pages/<page_id>.md` in batches of 4–8 to manage context.
3. Dispatch Grace to assemble the canonical `<feature-dir>/notion-inventory.md` from the persisted per-page artifacts. Background.

**2d. Archive scan** — Skip in peer mode. In self mode, dispatch Grace per `protocols/fan-out-dispatch.md` with the `archive-window-scan` protocol. Pass `window_start`, `window_end`. Output target: `<feature-dir>/archive-inventory.md`. Background.

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
- **One source fetch fails**: Record the failure in the manifest under Errors. Continue with the remaining sources.
- **All sources fail**: Emit the manifest with all errors recorded. Do not synthesize a partial inventory.
- **Window inverted (`window_end` before `window_start`)**: Surface and stop.

## Edge Cases

- **`sources` excludes all four**: Nothing to do — report and stop.
- **Peer mode + `sources` includes `archive`**: Silently drop `archive` from the active sources list. Note in the manifest's Skipped Sources section.
- **Feature directory already exists from a prior run**: Overwrite artifacts in place. Re-running is the supported re-fetch path. `identity.json` is overwritten too — if the caller wants to preserve a prior run, they should move the directory first.
- **Window spans a Notion or Asana account transition** (rare): The identity object is point-in-time. If the target changed their email or GID during the window, the fetch only sees activity under the current values. Surface this as a known limitation in the manifest if detectable.
