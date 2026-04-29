# digest-analysis

Given structured PR data for one or more of the user's own pull requests, triage all reviewer feedback and produce per-PR action reports. Assesses staleness, categorizes comments by action type, and synthesizes findings across PRs.

Read-only — produces reports only, does not post to GitHub or modify any PR.

## Input

Structured PR data per PR, typically fetched by Grace via a deployment-specific protocol. Required per PR:

- **PR metadata** — number, title, URL, head branch, base branch, additions, deletions, changed file count, draft status, review decision (APPROVED / CHANGES_REQUESTED / REVIEW_REQUIRED), CI status
- **Reviews** — per review: reviewer handle, state (APPROVED / CHANGES_REQUESTED / COMMENTED), body, submitted timestamp
- **Inline comments** — per comment: reviewer handle, file path, line number, body, created timestamp, updated timestamp
- **Issue-level comments** — per comment: author handle, body, created timestamp
- **Commit history** — per commit: sha, message, author, date
- **Authenticated user login** — for filtering the user's own comments

If thread resolution data is available (e.g., via GraphQL `reviewThreads.isResolved`), include it per inline thread. Use it when present; fall back gracefully when absent.

## Noise Filtering

Before categorizing, filter out:

- **Comments with no actionable content** — filter by content, not author. CI status pings, size warnings, merge queue instructions, and auto-generated summaries that don't raise a concern are noise regardless of who posted them. A comment that identifies a bug, raises a security concern, or suggests a code change is a review finding regardless of whether the author handle ends in `[bot]`. Author suffix is not a reliable signal; comment content is.
- **The user's own comments** — already the user's responses, not incoming feedback. Use the authenticated user login to identify these.
- **Human-resolved conversations** — inline threads resolved by a human reviewer (`resolved_by` is a human login). If resolution data is provided, use it. If unavailable, treat unresolved as the default and note the data gap in the report.

Note: **bot-resolved threads are NOT filtered.** Bots (e.g., `cursor[bot]`) auto-resolve their own comment threads when commits are amended or force-pushed, even when the underlying issue persists in the code. Always re-validate bot comments against the current source, regardless of resolution status. If the issue is genuinely fixed, categorize as "Potentially Addressed" with code evidence. If the issue persists, categorize normally in the Action Queue.
- **Pure approval comments** — "+1", "LGTM", "looks good to me" with no qualifying concern.

When in doubt, include. A false negative (missed actionable comment) is worse than a false positive (included conversation that turns out not to need action).

## Staleness Assessment

Inline comments may be stale if the PR has been pushed to after the comment was left. Assess staleness rather than blindly surfacing every comment:

1. **Identify the latest push** — find the most recent commit timestamp from the provided commit history.
2. **Compare comment timestamps** — for each inline comment, check whether it predates the latest push.
3. **Check file overlap** — for comments that predate the latest push, check whether the file (and ideally the line range) was modified in commits after the comment.

**Staleness categories:**

- **Likely addressed** — Comment predates a push that modified the same file and line range. Flag as potentially stale; do not include in the action queue unless the comment is from a `CHANGES_REQUESTED` reviewer.
- **Still relevant** — Comment predates a push but the push did not touch the file or lines in question. Include normally.
- **From a blocking reviewer** — Always include regardless of staleness. A `CHANGES_REQUESTED` reviewer must re-review to unblock the PR; their comments remain actionable even if the code has changed.
- **No subsequent push** — Comment is on the latest code. Include normally.

Surface stale comments in a separate "Potentially Addressed" section rather than mixing them into the action queue. The user or the mob can verify whether they are truly resolved.

## Comment Categorization

Assign each unfiltered comment one of four categories:

**Blocking** — The reviewer has explicitly requested changes (submitted a review with `CHANGES_REQUESTED` state), or the comment contains language indicating this is a requirement before approval: "this needs to", "must", "required", "please fix", "blocking on", "cannot approve until". Flag every comment from a blocking reviewer. A PR with one or more blocking reviewers cannot merge until those reviewers are satisfied.

**Code change needed** — The comment asks for a modification to the implementation, even if not framed as blocking. Includes: suggestions, alternative approaches, bugs identified, edge cases raised, performance concerns. Distinguish from blocking by the framing — this is a request, not a hard stop.

**Reply needed** — The comment asks a question, requests clarification, or raises a concern the user should acknowledge even if no code change follows. The reviewer is waiting for a response.

**Informational** — Observations, context, opinions offered without expectation of response or change. Note these briefly; they do not drive action items.

A single comment can span categories (e.g., a question followed by a code suggestion). Categorize by the highest-priority label and include both aspects in the description.

For each item in the Action Queue, include a one-line validity assessment: is the feedback correct, debatable, or wrong? This is distinct from being prescriptive about implementation — assess whether to act, not how. A comment can be categorized as "Code change needed" and assessed as "Debatable." Examples: "Valid — the int cast can fail on non-numeric input", "Debatable — ordering is guaranteed by the ORM's default queryset", "Wrong — the reviewer misread the conditional; this branch is only reachable when the flag is set".

## Cross-PR Synthesis

After writing individual reports, produce an aggregate summary covering:

- Total open PRs and how many have actionable feedback
- Any reviewers who appear across multiple PRs (a reviewer blocking three PRs is a pattern, not isolated feedback)
- PRs that are ready to merge (approved, CI green, no unresolved feedback)
- PRs blocked on CI regardless of review status
- List of report file paths written

## File Management

Before writing new reports, scan `scratch/output/` for feature directories matching `_pr-<number>-*/denniston*.md`. Remove any whose PR number is not in the current input set — those PRs are no longer open and the digests are stale. Remove empty feature directories left behind. If no matching files exist, skip silently.

Write one report per PR to `scratch/output/_pr-<number>-<slug>/denniston.md`. `scratch/` resolves to the HopLegion repo per `rules/scratch-path-resolution.md`. Directory naming and renaming follows `rules/feature-directory-lifecycle.md`. If a feature directory exists without the PR prefix, rename it. Create directories as needed. List the directory before picking the next artifact number. Use `denniston_<N>.md` where N is the next available number starting at 1 (e.g., `denniston_1.md`, `denniston_2.md`).

After writing all reports, report the file paths, any cleaned-up files, and a brief aggregate summary to the caller.

## Output Format

### Per-PR Report

```markdown
# PR #<number> — <title>

**URL:** <url>
**Repo:** <owner/repo>
**Branch:** <headRefName> → <baseRefName>
**Size:** +<additions> -<deletions> across <changedFiles> files
**Status:** <Draft / Open> | Review: <APPROVED / CHANGES_REQUESTED / REVIEW_REQUIRED>
**CI:** <passing / failing / pending>
**Generated:** <timestamp>

## Action Queue

Items ordered by priority: blocking first, then code changes, then replies.

### Blocking

**Reviewer: @<handle>** (review state: CHANGES_REQUESTED)

- `path/to/file.py:42` — <what they said and what they're asking for>
  *Valid — <brief rationale>*
- General comment — <what they said>
  *Debatable — <brief rationale>*

### Code Changes Needed

**@<handle>:**
- `path/to/file.py:88` — <what they're suggesting or pointing out>
  *Valid — <brief rationale>*

### Replies Needed

**@<handle>:**
- <question or concern they raised that needs acknowledgment>
  *Valid — <brief rationale>*

### Informational

- @<handle>: <brief note — observation or opinion offered without expectation of response>

## Potentially Addressed

Comments that predate a push which modified the same file/lines. May already be resolved — verify before acting.

- `path/to/file.py:42` — @<handle>: <what they said> *(push <sha> on <date> modified this file)*

## Notes
<Optional: anything else worth surfacing about this PR>
```

Omit empty sections. A PR with no unresolved feedback produces a brief report noting it is ready to merge. The report should be as long as the feedback warrants.

### Aggregate Summary

Returned to the caller after all per-PR reports are written. Covers the cross-PR synthesis items listed above, plus the list of file paths written and any stale reports removed.
