# session-orient

Orient the orchestrator at session start by reading a pre-generated briefing, presenting a summary, and auto-dispatching agents to close gaps. The briefing is produced by a hook script that runs in the background before the orchestrator loads; this protocol governs what the orchestrator does with the output.

The briefing cross-references external state (review queues, authored work with feedback) against on-disk agent artifacts to determine what needs action. The protocol is source-agnostic: the hook script and the deployment-specific protocol define which external systems to query, which agents to dispatch, and which artifact paths to scan.

## Prerequisites

- A SessionStart hook script produces a briefing and outputs it to stdout (injected into the orchestrator's context as a system reminder). The script also writes the briefing to a stable file path for archival.
- The briefing follows the structure defined in Briefing File Contract below
- Review and digest agents referenced in the DISPATCH section are available for dispatch

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `briefing_path` | Defined by deployment | Absolute path to the briefing file |
| `auto_dispatch` | `true` | Dispatch agents on items in the DISPATCH section without confirmation |

## Execution Steps

### Step 1 -- Locate the briefing

The briefing content arrives inline via the SessionStart hook's stdout (visible in the system reminder). If the inline content is present, use it directly. Do not re-read the file.

If the inline content is absent (hook did not run, or output was empty), fall back to reading the file at `briefing_path`. If the file does not exist or is empty, wait briefly and retry once. If still absent, report that briefing data is not available and stop.

If the briefing begins with an error line (e.g., auth failure, CLI unavailable), surface the error to the user and skip remaining steps.

### Step 2 -- Present the summary

Summarize the briefing in conversation. Three categories, each omitted if empty:

1. **Pending reviews**: items from the external review system assigned to the user. Sub-categories:
   - *Unreviewed* (no agent artifact on disk): count and titles
   - *Needs re-review* (artifact exists but source has new commits since the artifact was produced, detected by comparing the HEAD SHA recorded in the artifact against the current HEAD): count and titles
   - *Report ready* (artifact exists, current, user has not yet posted their review externally): count, titles, and the agent's recommendation from the existing artifact
   - *Reviewed* (user has posted review externally): count only
2. **Authored work with new feedback**: items the user authored that have received new external comments since the last digest artifact (detected by comparing the latest external comment timestamp against the artifact's modification time). One line per item with status.
3. **Stale artifacts**: agent artifacts on disk whose corresponding items are no longer in the queue (closed, merged, reassigned). Count only.

Drafts tagged for the user's review are presented separately from the main review queue. They are informational; they do not auto-dispatch.

Keep the presentation brief. The briefing file has the detail; the summary is a triage view.

### Step 3 -- Auto-dispatch on gaps

When `auto_dispatch` is `true`, parse the DISPATCH section and act on each line:

- **Review agent dispatch**: one instance per unreviewed or needs-re-review item. For re-review items, pass the previous artifact's HEAD SHA so the agent can scope its analysis to the delta. Follow `fan-out-dispatch` protocol for parallel dispatch.
- **Digest agent dispatch**: one instance per authored item with new feedback. The agent receives the item data and produces a digest artifact.

Dispatch without asking for confirmation. If the DISPATCH section is empty, note that all items have current artifacts and no new feedback exists.

Drafts are never auto-dispatched. Present them in the summary and wait for the user to issue a manual directive.

### Step 4 -- Report dispatch status

Confirm what was dispatched: "Dispatched [review agent] on N items (X new, Y re-review). Dispatched [digest agent] on M items with new feedback." Do not block on agent completion; the user can continue working while agents run in the background.

## Briefing File Contract

The hook script produces a markdown file with the following sections. The protocol depends on this structure. Deployment-specific protocols define the exact queries, field names, and artifact paths.

```
# Briefing -- <YYYY-MM-DD HH:MM>

## Review Queue

### Unreviewed
[Table: item identifier, author, title, URL]

### Needs Re-Review
[Table: item identifier, author, title, URL, previous HEAD, current HEAD]

### Report Ready
[Table: item identifier, author, title, recommendation from existing artifact, artifact path]

### Reviewed
[Table: item identifier, author, title]

### Drafts
[Table: item identifier, author, title, URL -- shown separately, no auto-dispatch]

## Authored Work
[Table: item identifier, title, status, feedback state (current / new feedback), URL]

## Stale Artifacts
[Table: artifact path, item identifier, reason (closed / merged / not in queue)]

## DISPATCH
<identifier-or-url>
<identifier-or-url> RE-REVIEW <previous-head-sha>
DIGEST <identifier-or-url>
```

Empty sections are omitted. The DISPATCH section is always last. Line formats:

- Bare identifier: review agent dispatch (new review)
- Identifier with `RE-REVIEW <sha>`: review agent dispatch (delta review against previous artifact)
- `DIGEST <identifier>`: digest agent dispatch (new feedback on authored work)

## Artifact Freshness Detection

The briefing script determines artifact freshness using two mechanisms:

1. **HEAD comparison** (review artifacts): the artifact records the HEAD SHA of the source at the time of analysis. The script compares this against the current HEAD. A mismatch means the source has changed since the artifact was produced; the item needs re-review.
2. **Timestamp comparison** (digest artifacts): the script compares the latest external comment timestamp against the artifact's file modification time. If external comments are newer, the item has undigested feedback.

These are the framework-level patterns. The deployment-specific hook script implements the actual comparison logic for its external system.

## Relationship to Other Protocols

- `fan-out-dispatch`: governs the parallel dispatch mechanics in Step 3
- `pr-queue-review-pipeline`: the full interactive pipeline for PR queue review. `session-orient` is a lighter-weight session-start pattern that dispatches from pre-fetched data rather than running a full pipeline. They complement, not replace: the pipeline is for explicit "review my queue" requests; session orientation runs automatically at session start.
- Deployment-specific protocols (e.g., `local/morning-briefing`) implement the concrete hook script, agent names, external system queries, and artifact paths for a given deployment.

## Error Handling

- **Briefing file absent**: wait briefly, retry once, then report unavailability and stop. Do not dispatch agents without briefing data.
- **Hook script error**: surface the error from the briefing file. Do not attempt to re-run the hook.
- **Individual agent failure during dispatch**: note the failure against the item. Continue collecting results from other agents. Surface failures in the dispatch status report.
- **Empty queue**: present "No pending reviews or feedback" and skip dispatch.

## Edge Cases

- **Script latency**: with inline delivery, the briefing is in context before the orchestrator's first turn. File-based fallback retries once for typical latency. If the script is consistently slow, the deployment should tune the script, not add retries to the protocol.
- **Partial briefing**: if some sections are present but the DISPATCH section is missing, present what exists and note the incomplete state. Do not infer dispatch actions from the summary sections.
- **Stale artifacts**: the briefing flags them for awareness. Cleanup is a separate concern handled by the deployment's archive process, not this protocol.
