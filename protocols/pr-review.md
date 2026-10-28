# pr-review

Given a PR identifier (URL, number + repo, or branch name), fetch the PR diff and description, analyze the changes, and produce a structured review report with specific file:line references. The report is suitable for use as working notes when the user writes GitHub review comments.

Read-only. Produces a report only; does not post to GitHub.

## Review Posture

Every review runs in one of two postures. The posture sets how much of the PR the review covers.

- **HOLISTIC** (default): review the entire diff. The user came to be a reviewer deliberately (a human tagged them) or via round-robin from their home team, so the whole change is in their court. This is the behavior described throughout this protocol; no extra parameters.
- **SCOPED**: review only the files the gating teams own. The user was assigned by round-robin from one or more teams other than their home team, so the request is "does this look right from those teams' standpoint," not "review the whole PR." Requires two parameters (`gating_teams`, a list of one or more team slugs; and `owned_paths`, the union of those teams' owned globs); see Scoped Posture below. Findings outside the owned-path set are excluded by design; surfacing them would be noise on code the user does not own.

Posture is supplied by the caller (the morning-briefing DISPATCH line carries it). When no posture is supplied, default to HOLISTIC. The posture and its parameters are classified and resolved by the deployment's posture-signal protocol (`protocols/local/`); this protocol consumes the result.

## Review Effort

This section binds the caller, not the reviewing agent. Before dispatching a review under this protocol, the caller runs the deployment's effort classifier, whatever the entry point: the session-start queue, an interactive queue review, or a one-off request naming a single PR. A non-empty result is passed as the Agent tool's per-dispatch effort override; an empty result means the station's definition effort. The classifier and its contract are named in the deployment's posture-signal protocol (`protocols/local/`). A one-off request with no posture supplied still defaults to HOLISTIC; the effort check runs regardless.

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

Posture parameters (SCOPED only):
- `gating_teams`: one or more team slugs that requested the review via round-robin. Names the standpoint the sign-off is issued from. A single slug is the common case; multiple slugs mean the user was round-robined for several teams in the same batch.
- `owned_paths`: the glob set those teams own, taken as the union across all `gating_teams`. Defines the inspection surface.

Both posture parameters originate from the deployment's posture-signal protocol (`protocols/local/`), which classifies the posture, resolves the gating teams, and resolves the unioned owned-path globs. The caller (the morning-briefing DISPATCH line) supplies them; this protocol consumes them.

## Key Commands

### Core data fetch

Follow `protocols/pr-data-fetch.md` for the standard fetch: metadata, CI, reviews, inline comments, issue comments, commits, and thread resolution. All steps run in parallel.

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

# For line citations and for file content at any ref: see the File Content Fetch
# section of protocols/pr-data-fetch.md
```

When given a PR URL, extract `OWNER`, `REPO`, and `NUMBER` from the URL directly.

When given only a branch name, resolve it first:
```bash
gh pr list --repo OWNER/REPO --head BRANCH_NAME --json number,url
```

## Analysis Steps

Execute in order. Under SCOPED posture, the file-touching steps (2 through 6) operate only on files matching `owned_paths`; see Scoped Posture below for how each step narrows.

1. **Read the PR description.** Understand the stated intent. Note if it's missing or sparse; that's a review finding.

2. **Scan changed files.** Identify the scope: which layers are touched (API, business logic, data layer, tests, config). Flag if test files are absent when implementation files change.

3. **Fetch existing review comments.** Reviews, inline comments, and thread resolution are fetched via `protocols/pr-data-fetch.md`. Use the thread resolution data to annotate each inline comment: join on `first_comment_id` (GraphQL) matching `id` (REST). Thread resolution handling depends on who resolved the thread:

   - **Human-resolved threads** (`resolved_by` is a human login): excluded from findings. These belong in the "Already Resolved" section of the report (or omitted entirely if the section would add no context).
   - **Bot-resolved threads** (`resolved_by` is a bot, e.g., `cursor[bot]`): **do not trust the resolution.** Bots auto-resolve their own threads when commits are amended or force-pushed, even when the underlying issue persists. Re-validate these comments against the current code on the branch. If the issue is still present, include it as a finding. If genuinely addressed, note it briefly in "Already Resolved."
   - **Unresolved threads**: treated normally.
   - **Resolution data unavailable**: treat all threads as unresolved and note the data gap.

   Read what other reviewers (human and bot) have already said. Note any unresolved threads, requested changes that may or may not have been addressed, and any context that affects what this review should focus on. Do not repeat findings already raised and acknowledged; add only what is new or unresolved.

4. **Read the diff.** In re-review mode, use the delta diff as the primary surface and the full diff for context. In a first-pass review, use the full diff. Analyze each changed file for:
   - **Correctness**: Logic errors, off-by-one errors, incorrect conditionals, missing null/error handling
   - **Security**: Injection risks, unvalidated input, exposed credentials, auth bypass paths, insecure defaults
   - **Silent failures**: Empty catch blocks, overly broad exception catches (catching `Exception`/`Error` base types when specific types are catchable), fallback behavior that suppresses errors without logging, retry logic that exhausts silently, optional chaining used to skip operations that should surface errors
   - **Style/conventions**: Deviations from patterns visible in the surrounding context (naming, structure, idioms)
   - **Potential bugs**: Race conditions, resource leaks, unhandled exceptions, incorrect assumptions
   - **Design concerns**: Abstraction violations, tight coupling, premature optimization, scope creep

   **Moves, splits, and renames**: when the diff shows a file deleted and one or more files added carrying substantially the same content, review it as a move, not as new code. Fetch the deleted file at `baseRefOid` and the added files at `headRefOid` per `protocols/pr-data-fetch.md`, then compare content. What the diff hides is what changed *during* the move (a dropped guard, an altered default, a lost decorator), and reading the added files as new code buries that inside a re-review of logic that did not change.

   **Operator-run scripts**: when the diff adds or changes a batch, remediation, backfill or migration script an operator runs by hand over a large population, read `protocols/operator-script-design.md` and review the script against its progress-reporting and per-user sequencing requirements.

   **Line number discipline**: Every finding that cites `path:line` must be backed by a ref-pinned fetch of the file at the PR's `headRefOid`. The File Content Fetch section of `protocols/pr-data-fetch.md` is the only sanctioned way to obtain file content at any ref: fetch to the session scratchpad, then slice with the `Read` tool's `offset`/`limit`. Do not read the working tree, whose line numbers drift when it is on a different branch or carries uncommitted changes; do not materialize a ref locally with `git archive` or a second checkout; do not shell-slice the fetched content with `sed` or `awk`; and never derive line numbers from diff hunk headers, where the `+`/`-` prefixes and context lines make manual counting error-prone.

   **Line content citation**: Every finding citing `path:line` must include the exact content at that line in the report (see Output Format below). This is a verification contract: the content either matches what the reviewer sees on GitHub at that SHA, or the finding is wrong. Single-line citations are inline; multi-line spans use a fenced block.

5. **Assess test coverage.** Three questions, answered separately.

   - For each changed behavioral path lacking tests, identify specifically what regression the missing test would allow.
   - For each test that exists, evaluate whether it tests behavior and contracts rather than implementation details, per `protocols/test-quality.md`.
   - For each new or changed test, run that protocol's removal check: if the behavior the test names were removed, would the test fail? Answer per test and name what fails. Where the diff changes how tests reach production code (a moved call site, a new or dropped re-export, a renamed module) rather than changing the tests themselves, run the check on the tests that patch through that surface as well, within the review's inspection surface (under SCOPED posture, the owned subset).

   A test that would still pass is a finding in its own right, not an absent-coverage finding: `protocols/finding-disposition.md` names its consequence and sets its tier. Findings from this step are tiered and sectioned with every other finding per that protocol; the report carries no separate missing-tests section.

6. **Check CI status.** Note any failing checks. Don't block the review on them, but include status in the report. Report the check name and conclusion only; `rules/ci-status-not-diagnosis.md` governs.

7. **Assess overall quality.** Assign each finding a tier per `protocols/finding-disposition.md` and produce a recommendation.

## Scoped Posture

When `gating_teams` and `owned_paths` are supplied, the review answers a narrower question: *is this PR correct from the gating teams' standpoint, on the code those teams own?* The user is one of several round-robin reviewers; other teams own the rest of the diff. `owned_paths` is already the union of every team in `gating_teams`, so the review treats the gating teams as a single combined standpoint over their combined owned surface; it does not partition findings by individual team.

**How to execute:**

1. Compute the owned subset. From the changed-files list (Step 2), keep only paths matching any glob in `owned_paths` (the union across all `gating_teams`). This subset is the inspection surface for Steps 2 through 6.
2. Run Steps 3 through 6 against the owned subset only. Read the diff, assess tests, and cite findings exclusively within owned paths. Do not read or analyze files outside the subset, even when a change there looks suspicious; that is another team's review surface.
3. In re-review mode, intersect the delta with `owned_paths` as well: report only owned-path files that changed since the previous SHA.
4. If the owned subset is empty (the PR touches nothing the gating teams own), do not invent findings. Issue a clean sign-off noting that no owned paths are affected.

**What to report:**

- An affirmative sign-off scoped to the gating teams, phrased so the user can post it verbatim, e.g., "Approved from `<gating_teams>`'s standpoint" or "Requesting changes from `<gating_teams>`'s standpoint (see findings)." When there is more than one gating team, name them comma-joined (e.g., "from team-a, team-b's standpoint"). The sign-off speaks only to owned paths.
- Findings confined to owned paths. Exclude findings outside the owned-path set entirely; that exclusion is the point of the posture, not an omission.
- The owned-path globs and the matched files, so the user can see exactly what the sign-off covers.

Posture is independent of pass type: a scoped review can be a first-pass or a re-review. Apply the Scoped Posture narrowing on top of whichever pass type applies.

## Re-Review Mode

When a previous review SHA is provided, the review is scoped to what has changed since that point.

**How to execute:**

1. Fetch the commit list (Step 7) to orient yourself; identify which commits are new since the previous SHA.
2. Fetch the delta diff (Step 8) using the provided previous SHA as `OLD_SHA` and the current PR head SHA as `NEW_SHA`. The current head SHA is available from the commit list or from the PR metadata.
3. Fetch the full diff (Step 2) for broader context; use it to understand surrounding code but focus findings on the delta.
4. Fetch existing review comments (Steps 5 and 6) and check whether previously raised concerns have been addressed in the new commits.

**What to report:**

- Findings in the delta diff that are new or newly introduced
- Previously raised issues that appear unaddressed (note them; do not re-analyze the same code as if it's new)
- Any regressions introduced by the changes since the previous SHA

In re-review mode, include a header line in the report noting the previous SHA and the range being reviewed.

## Confidence Filter

Before including any finding in the report, apply this filter: is this a genuine problem introduced or present in this PR's code, or is it a pre-existing issue, a stylistic preference without codebase evidence, or a false positive from incomplete diff context? Only include findings you are confident are real. A shorter report with high-signal findings is more useful than a complete list with noise.

## Finding Disposition

The tiers, the tier gate, the comment bar, and the report sectioning are owned by `protocols/finding-disposition.md`. Read it before writing the report; this protocol does not restate the tiers.

External PR review is that protocol's Comment Candidates context: Blocking means the user requests changes, Comment means the user leaves a comment the author may decline, Noted means the finding is on the record with no comment expected. Apply the tier gate to every finding before writing, and name the widening class on any non-behavioral finding that reaches Comment.

Missing-test findings are tiered and placed in the tier sections like any other finding, per that protocol's absent-coverage rule. A test that exists and cannot fail is the separate class that protocol's tier-gate instance governs: it carries its own named consequence, so it takes no widening label, and whether it is Blocking or Comment turns on whether a test is dead as of this change or the change only installs the mechanism. Context Observations remains a top-level section of its own: its subject is surrounding code the reviewer read for context, not the change under review, so it carries no tier.

The recommendation follows from the tiers rather than from an independent read: any Blocking finding means request changes, no Blocking with at least one Comment means approve with comments, neither means approve.

Reports already in the dated reviews directory predate this scale and keep Critical/Major/Minor. When a re-review cites one, the "Reading a pre-recalibration report" section of `protocols/finding-disposition.md` governs; in particular, a prior Major is re-adjudicated under the gate rather than mapped.

## Finding Register

Write every finding with the code as the grammatical subject of the sentence. `protocols/review-comment-register.md` governs, and this report is one of its primary destinations: the comment candidates are phrased for the user to post verbatim on someone else's change. It does not load ambiently; read it before writing the first finding.

The trigger is the sentence's subject, not the word "you". "The author chose to duplicate the enum" and "this was done incorrectly" carry no second person and still review the person; both get rewritten until the code, the file, or the change is what is being described. A question to the author is legitimate and keeps the code as its subject ("Is this shape already changing in #1290?").

First person for the reviewer stays. The scoped sign-off is the user's own first-person statement by design, and marking a claim as the reviewer's read ("my read is that this can wait") is honest about certainty rather than a register problem.

Register never changes the tier or the ask. A Blocking finding stays Blocking with its named consequence intact. `protocols/asimov-catalog.md` pattern 1.16 carries this so the tone pass catches what survives, but the report is authored in this register; a pass that has to rewrite every finding means this step was skipped.

## Output Location

`scratch/` resolves to the framework repo per `rules/scratch-path-resolution.md`.

**External PR reviews (Fagan)** are one-shot artifacts written to a dated reviews directory:

```
scratch/output/YYYY-MM-DD/reviews/pr-<number>-<author-slug>-<title-slug>.md
```

### Filename Components

- `<number>`: PR number (digits only, no `#` prefix)
- `<author-slug>`: GitHub username in kebab-case (e.g., `jordan-lee`, `sam-rivera`)
- `<title-slug>`: 3-5 word kebab-case summary derived from the PR title (e.g., `settled-fee-dedup`, `report-cache-denominator`)

No datetime suffixes. The date-scoped directory (`YYYY-MM-DD/`) handles temporal separation.

### Scoped Naming

Scoped reviews append `-scoped-<gating-team-slugs>` before the extension, so a holistic and a scoped review of the same PR never collide and the filename states the standpoint:

```
pr-1234-alex-chen-stale-job-reaper-scoped-<gating-team-slugs>.md
```

The `<gating-team-slugs>` is the `gating_teams` value rendered for a filename: each slug in kebab-case, multiple slugs joined with `-and-` (e.g., `-scoped-team-a-and-team-b`). A single gating team is just the one slug. Scoped re-reviews combine both suffixes: `-scoped-<team-slugs>-rereview-N`.

### Re-Review Naming

Same-day re-reviews of the same PR append `-rereview-N` where N is an incrementing integer starting at 1:

```
pr-1234-sam-rivera-report-cache-denominator.md
pr-1234-sam-rivera-report-cache-denominator-rereview-1.md
pr-1234-sam-rivera-report-cache-denominator-rereview-2.md
```

The prior report remains in place as a historical record. The agent checks for existing reports matching the same PR number in the day's reviews directory and increments accordingly.

**Mob pipeline and pre-ship reviews** are feature artifacts; their location and naming are owned by `protocols/mob-review-output.md`, the authoritative source for feature-directory review naming.

## Output Format

### Initial Review

```markdown
# PR Review: #<number>, <title>

**URL:** <url>
**Repo:** <owner/repo>
**Author:** <author>
**Branch:** <headRefName> -> <baseRefName>
**Size:** +<additions> -<deletions> across <changedFiles> files
**HEAD:** <headRefOid>
**CI:** <status>

## Summary
<2-4 sentence assessment of what the PR does and overall quality signal>

## Recommendation
[ ] Approve (no Blocking or Comment findings)
[ ] Approve with comments (no Blocking, at least one Comment)
[ ] Request changes (at least one Blocking finding)
[ ] Cannot review (<reason>)

## Existing Review Context
<Summary of what other reviewers (human and bot) have already raised. Group by theme if there are multiple reviewers. Note which concerns appear resolved and which are still open.>

## Already Resolved
<Inline comments that belong to resolved threads. List briefly: author, file, topic. Omit this section if there are no resolved threads or if the resolved comments add no context.>
- `path/to/file.py:42` (@user): <one-line description of the resolved thread>

## Comment Candidates

Every finding citing `path:line` includes the exact line content. Single line: inline backticks after the path reference. Multi-line span: fenced block after the description. Truncate single-line content with ellipsis if over 80 chars.

### Blocking
- `path/to/file.py:42` `if user is None and not admin:`: <the named consequence: what breaks, on which path, under what conditions>

### Comment
- `path/to/file.py:88-92`: <the specific ask, plus the widening class if the finding has no behavioral consequence>:
  ```python
  <exact content of the cited range>
  ```

## Recorded (no comment expected)
- `path/to/file.py:15` `return cached_value  # not thread-safe`: <what is true and cited, with no ask attached>

## Context Observations
<Bugs or security issues noticed in surrounding code while reading for context. Not in the diff, not attributable to this PR. Only include items that are genuinely broken or dangerous, not style concerns, naming questions, or architectural musings. Line content citation applies here too.>
- `path/to/file.py:42` `<exact line content>`: <what is broken and what the impact is>

## CI Status
- <check name>: <status> (<any relevant detail>)

## Comment Bar Delta
- Automated reviewer posted: <count and one-line topics, or "nothing">
- This review's comment candidates: <count and one-line topics>
- Widening justifications invoked: <which class, per finding>
```

Comment Bar Delta is last so that removing it leaves the report body intact: it is a calibration instrument, live only until the bar resolves per the "Comment bar calibration" section of `protocols/finding-disposition.md`. When that section is deleted, delete this one too. It applies to external PR reviews, which already fetch automated-reviewer comments; the mob and pre-ship contexts have no automated reviewer to compare against.

### Scoped Review

A scoped review uses the Initial (or Re-Review) format with these modifications:

- Add a header line `**Posture:** SCOPED (<gating_teams>)` and a header line `**Owned paths:** <comma-separated globs>`. `<gating_teams>` is the comma-joined list of gating team slugs.
- Replace the Recommendation block with a single sign-off line phrased from the gating teams' standpoint:

```markdown
## Sign-off (<gating_teams> standpoint)
[ ] Approved from <gating_teams>'s standpoint (owned paths look good)
[ ] Approved with comments from <gating_teams>'s standpoint
[ ] Requesting changes from <gating_teams>'s standpoint (see Blocking findings)
[ ] No owned paths affected (clean sign-off)
```

The sign-off follows from the tiers on the same terms as the Recommendation block, computed over owned-path findings only.

- The Comment Candidates, Recorded, and Context Observations sections include only owned-path entries. Do not list findings outside `owned_paths`.
- Add a `## Coverage` section listing the owned globs (the union across `gating_teams`) and the changed files that matched, so the sign-off's surface is explicit.

### Re-Review

```markdown
# PR Re-Review: #<number>, <title>

**URL:** <url>
**Repo:** <owner/repo>
**Author:** <author>
**Branch:** <headRefName> -> <baseRefName>
**Size:** +<additions> -<deletions> across <changedFiles> files
**HEAD:** <headRefOid>
**Baseline:** <prior-headRefOid>
**CI:** <status>
**Re-reviewed:** <today's date>

## Summary
<2-4 sentence assessment of what changed since the last review and the current overall quality signal>

## Recommendation
[ ] Approve (no Blocking or Comment findings)
[ ] Approve with comments (no Blocking, at least one Comment)
[ ] Request changes (at least one Blocking finding)
[ ] Cannot review (<reason>)

## Prior Findings Status

| Finding | Location | Status |
|---------|----------|--------|
| <brief description> | `path/to/file.py:42` | Resolved / Still present / Partially addressed |

<Brief note on any findings that require elaboration, e.g., partially addressed findings that still warrant attention.>

## Existing Review Context
<Summary of reviewer comments, with attention to comments posted since the prior review. Note which concerns appear resolved and which remain open.>

## Already Resolved
<Inline comments that belong to resolved threads. List briefly: author, file, topic. Omit this section if there are no resolved threads or if the resolved comments add no context.>
- `path/to/file.py:42` (@user): <one-line description of the resolved thread>

## Comment Candidates (Delta)

Line content citation rules and per-tier content match the initial review format above.

### Blocking
- `path/to/file.py:42` `<exact line content>`: <the named consequence>

### Comment
- `path/to/file.py:88-92`: <the specific ask, plus the widening class where required>:
  ```python
  <exact content of the cited range>
  ```

## Recorded (no comment expected)
- `path/to/file.py:15` `<exact line content>`: <what is true and cited, with no ask attached>

## Context Observations
<Bugs or security issues noticed in surrounding code. Not in the delta diff, not attributable to this PR. Line content citation applies here too.>
- `path/to/file.py:42` `<exact line content>`: <what is broken and what the impact is>

## CI Status
- <check name>: <status> (<any relevant detail>)

## Comment Bar Delta
- Automated reviewer posted: <count and one-line topics, or "nothing">
- This review's comment candidates: <count and one-line topics>
- Widening justifications invoked: <which class, per finding>
```

Omit empty sections: with no Blocking findings, omit that subsection, and if CI is clean with no noteworthy detail, one line suffices. Two sections are not omitted on length. Keep Recorded even when it is long, per `protocols/finding-disposition.md`; below-the-bar findings stay in the report separated from the actionable ones rather than dropped. Keep Comment Bar Delta while the calibration is open, including when the automated reviewer posted nothing, which is the reading the calibration most needs.

## Edge Cases

- **PR not found**: Surface the `gh` error verbatim. Do not guess.
- **Massive diff (1000+ lines)**: Note the size prominently in the summary. Review what you can; flag that a diff this large warrants splitting into separate PRs.
- **Module split or large move**: the diff overstates the change. Establish which content moved unchanged by comparing the two refs (see Step 4, Moves, splits, and renames), then scope findings to the delta that comparison surfaces. Do not flag a diff this size as unreviewable before running the comparison.
- **Draft PR**: Include a `[DRAFT]` callout at the top. Review proceeds normally but note that the author has marked it not ready. Posture applies independently; a draft can be reviewed HOLISTIC or SCOPED.
- **No PR description**: Flag it as a finding and tier it under `protocols/finding-disposition.md` like any other. It has no behavioral consequence, so it reaches Comment only where the team enforces the convention (the third widening class) and is Recorded otherwise. Reviewers and future maintainers needing context is the reason to raise it, not a reason to exempt it from the gate.
- **Binary files or generated files in diff**: Note their presence but skip analysis. Flag if generated files appear to have manual edits.
- **Private repo without access**: Surface the permission error. Do not attempt workarounds.
- **PR against a non-main base branch**: Note the base branch prominently; findings about "missing tests" may be less relevant for a stack PR.
- **Re-review with invalid SHA**: If the provided previous SHA is not found in the PR's commit history, report the error and fall back to a full first-pass review. Note the fallback in the report header.
- **Bot-only prior reviews**: If all prior review comments are from automated bots (e.g., cursor[bot], codecov), note that briefly in Existing Review Activity and proceed as a first-pass review from a human perspective.
- **SCOPED requested without owned_paths**: If posture is SCOPED but `owned_paths` is missing or empty, do not silently fall back to a full review; the absence means the gating teams' ownership could not be resolved. Report the missing parameter and ask the caller to supply the owned-path globs (or resolve them via the deployment's posture-signal protocol).
- **SCOPED owned subset empty**: The PR touches nothing the gating teams own. Issue the clean "No owned paths affected" sign-off; do not analyze unowned files to manufacture findings.
