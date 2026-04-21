# pr-review

Given a PR identifier (URL, number + repo, or branch name), fetch the PR diff and description, analyze the changes, and produce a structured review report with specific file:line references. The report is suitable for use as working notes when the user writes GitHub review comments.

Read-only — produces a report only, does not post to GitHub.

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status` must succeed)
- The reviewer must have read access to the repo
- For branch checkout (optional, deeper analysis): local clone of the repo must exist or be fetchable

## Input Parameters

Required (one of):
- PR URL: `https://github.com/OWNER/REPO/pull/NUMBER`
- PR number + repo: `#NUMBER` in `OWNER/REPO`
- Branch name: `feature/some-branch` (will resolve to open PR if one exists)

Optional context:
- The codebase's primary language/framework (helps focus style analysis)
- Any known constraints or context from the task description
- Previous review SHA: a commit SHA from a prior review pass, used to scope a re-review to only new changes

## Key Commands

### Core data fetch

Follow `protocols/pr-data-fetch.md` for the standard seven-step fetch: metadata, CI, reviews, inline comments, issue comments, commits, and thread resolution. All seven steps run in parallel.

### Inspection-specific commands

```bash
# Fetch the full diff
gh pr diff <NUMBER> --repo OWNER/REPO

# List changed files with patch stats
gh pr view <NUMBER> --repo OWNER/REPO \
  --json files \
  --jq '.files[] | "\(.additions)+\(.deletions)-\t\(.path)"'

# Re-review only: diff between a previous SHA and current HEAD
gh api repos/OWNER/REPO/compare/OLD_SHA...NEW_SHA \
  --jq '.files[] | {filename: .filename, status: .status, patch: .patch}'

# For line citations: fetch file at the PR's headRefOid per protocols/pr-data-fetch.md
```

When given a PR URL, extract `OWNER`, `REPO`, and `NUMBER` from the URL directly.

When given only a branch name, resolve it first:
```bash
gh pr list --repo OWNER/REPO --head BRANCH_NAME --json number,url
```

## Analysis Steps

Execute in order:

1. **Read the PR description** — Understand the stated intent. Note if it's missing or sparse; that's a review finding.

2. **Scan changed files** — Identify the scope: which layers are touched (API, business logic, data layer, tests, config). Flag if test files are absent when implementation files change.

3. **Fetch existing review comments** — Reviews, inline comments, and thread resolution are fetched via `protocols/pr-data-fetch.md`. Use the thread resolution data to annotate each inline comment: join on `first_comment_id` (GraphQL) matching `id` (REST). Thread resolution handling depends on who resolved the thread:

   - **Human-resolved threads** (`resolved_by` is a human login): excluded from findings. These belong in the "Already Resolved" section of the report (or omitted entirely if the section would add no context).
   - **Bot-resolved threads** (`resolved_by` is a bot, e.g., `cursor[bot]`): **do not trust the resolution.** Bots auto-resolve their own threads when commits are amended or force-pushed, even when the underlying issue persists. Re-validate these comments against the current code on the branch. If the issue is still present, include it as a finding. If genuinely addressed, note it briefly in "Already Resolved."
   - **Unresolved threads**: treated normally.
   - **Resolution data unavailable**: treat all threads as unresolved and note the data gap.

   Read what other reviewers (human and bot) have already said. Note any unresolved threads, requested changes that may or may not have been addressed, and any context that affects what this review should focus on. Do not repeat findings already raised and acknowledged — add only what is new or unresolved.

4. **Read the diff** — In re-review mode, use the delta diff as the primary surface and the full diff for context. In a first-pass review, use the full diff. Analyze each changed file for:
   - **Correctness**: Logic errors, off-by-one errors, incorrect conditionals, missing null/error handling
   - **Security**: Injection risks, unvalidated input, exposed credentials, auth bypass paths, insecure defaults
   - **Silent failures**: Empty catch blocks, overly broad exception catches (catching `Exception`/`Error` base types when specific types are catchable), fallback behavior that suppresses errors without logging, retry logic that exhausts silently, optional chaining used to skip operations that should surface errors
   - **Style/conventions**: Deviations from patterns visible in the surrounding context (naming, structure, idioms)
   - **Potential bugs**: Race conditions, resource leaks, unhandled exceptions, incorrect assumptions
   - **Design concerns**: Abstraction violations, tight coupling, premature optimization, scope creep

   **Line number discipline**: Every finding that cites `path:line` must be backed by a ref-pinned fetch of the file at the PR's `headRefOid`, not a local `Read` against whatever branch is checked out. Local filesystem reads drift when the working tree is on a different branch or has uncommitted changes. Use the fetch command from `protocols/pr-data-fetch.md` with `ref=<headRefOid>`. Never derive line numbers from diff hunk headers — `+`/`-` prefixes and context lines make manual counting error-prone.

   **Line content citation**: Every finding citing `path:line` must include the exact content at that line in the report (see Output Format below). This is a verification contract: the content either matches what the reviewer sees on GitHub at that SHA, or the finding is wrong. Single-line citations are inline; multi-line spans use a fenced block.

5. **Assess test coverage** — For each changed behavioral path lacking tests, identify specifically what regression the missing test would allow. If tests exist, evaluate whether they test behavior and contracts rather than implementation details.

6. **Check CI status** — Note any failing checks. Don't block the review on them, but include status in the report.

7. **Assess overall quality** — Categorize findings by severity and produce a recommendation.

## Re-Review Mode

When a previous review SHA is provided, the review is scoped to what has changed since that point.

**How to execute:**

1. Fetch the commit list (Step 7) to orient yourself — identify which commits are new since the previous SHA.
2. Fetch the delta diff (Step 8) using the provided previous SHA as `OLD_SHA` and the current PR head SHA as `NEW_SHA`. The current head SHA is available from the commit list or from the PR metadata.
3. Fetch the full diff (Step 2) for broader context — use it to understand surrounding code but focus findings on the delta.
4. Fetch existing review comments (Steps 5 and 6) and check whether previously raised concerns have been addressed in the new commits.

**What to report:**

- Findings in the delta diff that are new or newly introduced
- Previously raised issues that appear unaddressed (note them; do not re-analyze the same code as if it's new)
- Any regressions introduced by the changes since the previous SHA

In re-review mode, include a header line in the report noting the previous SHA and the range being reviewed.

## Confidence Filter

Before including any finding in the report, apply this filter: is this a genuine problem introduced or present in this PR's code, or is it a pre-existing issue, a stylistic preference without codebase evidence, or a false positive from incomplete diff context? Only include findings you are confident are real. A shorter report with high-signal findings is more useful than a complete list with noise.

## Finding Severity

Assign each finding one of three severities:

- **Critical** — Likely to cause incorrect behavior, data loss, security vulnerability, or failure in production. Must be addressed before merge.
- **Major** — Significant quality or correctness concern. Should be addressed; warrants blocking if not discussed.
- **Minor** — Style, naming, small inconsistency. Worth noting; does not warrant blocking.

## Output Location

`scratch/` resolves to the HopLegion repo per `rules/scratch-path-resolution.md`.

**External PR reviews (Fagan)** are one-shot artifacts written to a dated reviews directory:

```
scratch/output/YYYY-MM-DD/reviews/pr-<number>-<author-slug>-<title-slug>.md
```

### Filename Components

- `<number>`: PR number (digits only, no `#` prefix)
- `<author-slug>`: GitHub username in kebab-case (e.g., `femi-olukoya`, `cody-s-lee`)
- `<title-slug>`: 3-5 word kebab-case summary derived from the PR title (e.g., `adyen-settled-fee-dedup`, `tax-cache-rate-denominator`)

No datetime suffixes. The date-scoped directory (`YYYY-MM-DD/`) handles temporal separation.

### Re-Review Naming

Same-day re-reviews of the same PR append `-rereview-N` where N is an incrementing integer starting at 1:

```
pr-269775-cody-s-lee-tax-cache-rate-denominator.md
pr-269775-cody-s-lee-tax-cache-rate-denominator-rereview-1.md
pr-269775-cody-s-lee-tax-cache-rate-denominator-rereview-2.md
```

The prior report remains in place as a historical record. The agent checks for existing reports matching the same PR number in the day's reviews directory and increments accordingly.

**Mob pipeline reviews (Friedman)** are feature artifacts written to the feature directory:

```
scratch/output/_<feature-slug>/friedman_1.md    (canonical, written by Winterbotham after parallel consolidation)
scratch/output/_<feature-slug>/friedman_1a.md   (parallel pass A)
scratch/output/_<feature-slug>/friedman_1b.md   (parallel pass B)
```

Use `friedman_<N>.md` where N is the next available number starting at 1 (e.g., `friedman_1.md`, `friedman_2.md`). When dispatched as parallel instances, each pass writes a suffixed report (`_<N>a.md`, `_<N>b.md`). Winterbotham consolidates both into the canonical `_<N>.md`. The suffixed reports remain on disk as the raw record.

## Output Format

### Initial Review

```markdown
# PR Review: #<number> — <title>

**URL:** <url>
**Repo:** <owner/repo>
**Author:** <author>
**Branch:** <headRefName> → <baseRefName>
**Size:** +<additions> -<deletions> across <changedFiles> files
**HEAD:** <headRefOid>
**CI:** <status>

## Summary
<2-4 sentence assessment of what the PR does and overall quality signal>

## Recommendation
[ ] Approve — changes look good
[ ] Approve with minor comments
[ ] Request changes — see Critical/Major findings
[ ] Cannot review — <reason>

## Existing Review Context
<Summary of what other reviewers (human and bot) have already raised. Group by theme if there are multiple reviewers. Note which concerns appear resolved and which are still open.>

## Already Resolved
<Inline comments that belong to resolved threads. List briefly — author, file, topic. Omit this section if there are no resolved threads or if the resolved comments add no context.>
- `path/to/file.py:42` (@user) — <one-line description of the resolved thread>

## Findings

Every finding citing `path:line` includes the exact line content. Single line: inline backticks after the path reference. Multi-line span: fenced block after the description. Truncate single-line content with ellipsis if over 80 chars.

### Critical
- `path/to/file.py:42` `if user is None and not admin:` — <specific description of the issue and why it matters>

### Major
- `path/to/file.py:88-92` — <specific description>:
  ```python
  <exact content of the cited range>
  ```

### Minor
- `path/to/file.py:15` `return cached_value  # not thread-safe` — <specific description>

## Missing Tests
- <specific behavior or path that lacks test coverage — state what regression the missing test allows>

## Context Observations
<Bugs or security issues noticed in surrounding code while reading for context. Not in the diff, not attributable to this PR. Only include items that are genuinely broken or dangerous — not style concerns, naming questions, or architectural musings. Line content citation applies here too.>
- `path/to/file.py:42` `<exact line content>` — <what is broken and what the impact is>

## CI Status
- <check name>: <status> — <any relevant detail>
```

### Re-Review

```markdown
# PR Re-Review: #<number> — <title>

**URL:** <url>
**Repo:** <owner/repo>
**Author:** <author>
**Branch:** <headRefName> → <baseRefName>
**Size:** +<additions> -<deletions> across <changedFiles> files
**HEAD:** <headRefOid>
**Baseline:** <prior-headRefOid>
**CI:** <status>
**Re-reviewed:** <today's date>

## Summary
<2-4 sentence assessment of what changed since the last review and the current overall quality signal>

## Recommendation
[ ] Approve — changes look good
[ ] Approve with minor comments
[ ] Request changes — see Critical/Major findings
[ ] Cannot review — <reason>

## Prior Findings Status

| Finding | Location | Status |
|---------|----------|--------|
| <brief description> | `path/to/file.py:42` | Resolved / Still present / Partially addressed |

<Brief note on any findings that require elaboration — e.g., partially addressed findings that still warrant attention.>

## Existing Review Context
<Summary of reviewer comments, with attention to comments posted since the prior review. Note which concerns appear resolved and which remain open.>

## Already Resolved
<Inline comments that belong to resolved threads. List briefly — author, file, topic. Omit this section if there are no resolved threads or if the resolved comments add no context.>
- `path/to/file.py:42` (@user) — <one-line description of the resolved thread>

## Findings (Delta)

Line content citation rules match the initial review format above.

### Critical
- `path/to/file.py:42` `<exact line content>` — <specific description>

### Major
- `path/to/file.py:88-92` — <specific description>:
  ```python
  <exact content of the cited range>
  ```

### Minor
- `path/to/file.py:15` `<exact line content>` — <specific description>

## Missing Tests
- <specific behavior or path that lacks test coverage>

## Context Observations
<Bugs or security issues noticed in surrounding code. Not in the delta diff, not attributable to this PR. Line content citation applies here too.>
- `path/to/file.py:42` `<exact line content>` — <what is broken and what the impact is>

## CI Status
- <check name>: <status> — <any relevant detail>
```

Omit empty sections. If there are no Critical findings, omit that subsection. If CI is clean with no noteworthy detail, one line suffices. The report should be as long as it needs to be and no longer.

## Edge Cases

- **PR not found**: Surface the `gh` error verbatim. Do not guess.
- **Massive diff (1000+ lines)**: Note the size prominently in the summary. Review what you can; flag that a diff this large warrants splitting into separate PRs.
- **Draft PR**: Include a `[DRAFT]` callout at the top. Review proceeds normally but note that the author has marked it not ready.
- **No PR description**: Flag as a finding under Major — reviewers and future maintainers need context.
- **Binary files or generated files in diff**: Note their presence but skip analysis. Flag if generated files appear to have manual edits.
- **Private repo without access**: Surface the permission error. Do not attempt workarounds.
- **PR against a non-main base branch**: Note the base branch prominently — findings about "missing tests" may be less relevant for a stack PR.
- **Re-review with invalid SHA**: If the provided previous SHA is not found in the PR's commit history, report the error and fall back to a full first-pass review. Note the fallback in the report header.
- **Bot-only prior reviews**: If all prior review comments are from automated bots (e.g., cursor[bot], codecov), note that briefly in Existing Review Activity and proceed as a first-pass review from a human perspective.
