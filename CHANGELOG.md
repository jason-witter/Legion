# Changelog

## [v0.8] - 2026-09-10

The theme of this release is what a review finding and a code comment are allowed to cost the person reading them. Findings get one scale whose tiers name an action, comments have to earn their place against a stated test, and both get measured rather than sampled.

### New
- `protocols/finding-disposition.md`: one three-tier scale (Blocking, Comment, Noted) for every review station, where the tier names what happens to the finding rather than how severe it feels. A tier gate drops any finding that cannot supply its tier's artifact: Blocking needs a named consequence, Comment needs a specific ask, Noted needs only to be true and cited. Fagan, Friedman, Oppenheimer, and Winterbotham reference the file instead of restating tiers, so a recalibration lands in one edit.
- `code-comment-register` rule: a comment earns its place by flagging an assumption, constraint, or gotcha whose absence would let the next reader make a wrong edit. Measurements and research findings, arguments that the code is correct, pending decisions, and review history all fail that test even when every word is true. A "one fact, one home" section covers the dominant source of unreviewable comment volume, which is the same fact written in two or three places.
- `scripts/prose-lint.py`: scans the comments and docstrings a branch added against its merge base and prints file:line for every catalog tell and volume smell. Written because the rule alone did not work: reading a few docstrings cannot tell you how many others are affected. Reports only added lines, so pre-existing prose in a file the branch merely touches never appears.
- `orchestrator-report-brevity` rule: every reply is a status channel, not the place rationale lives. Rationale goes to disk, where whoever picks the work up cold will find it.
- `review-comment-register` rule: a finding is about the code, so the code is the sentence's subject and the author stays out of it. Covers the cases with no second person in them, which are the ones that survive a tone pass.
- `reference-doc-authoring` rule: structure, diagram, table, and register guidance for a doc promoted to a shared destination, including the rule that an evergreen doc carries no pending decisions.
- `file-tools-over-shell-traversal` rule: locate with Glob, search with Grep, read with Read, and reserve Bash for programs. Carries the inverted guidance for sessions that ship no Grep tool.
- `no-inline-script-bodies` rule: script and commit-message bodies ride a file rather than a heredoc or a multi-line `-c` string, because a heredoc prompts regardless of the allow list and sits outside hook scanning.
- `ci-status-not-diagnosis` rule: record a failing check as a fact and move on. Diagnosis is a separate task the user initiates, not part of a review or digest pass.
- `protocols/test-quality.md`: promoted from a rule. The category cluster is defined once and each consuming station maps its own consequence.
- `commands/` directory and the `battle-mode` command: a throwaway-prototype posture for the session that drops subagents, artifacts, and capture ceremony for speed. `install.sh` symlinks `commands/` into `~/.claude/commands/` alongside agents and rules, and `commands/local/` holds deployment-specific commands.
- `docs/rule-history/`: four incident files carrying the stories behind rules whose constraints now stand on their own.

### Changed
- Review findings across Fagan, Friedman, Oppenheimer, Winterbotham, and the review protocols were recalibrated onto the disposition scale, replacing per-agent severity vocabulary.
- `engineer-facing-handoff-scrub`: the Asimov pass is the whole scrub, an unrun pass is reported as unrun rather than substituted with a mechanical check, and the pass fans out one dispatch per file with letter-suffixed artifacts. Parallel passes that all listed the directory before numbering silently overwrote each other.
- `artifact-on-disk` is scoped by whether a protocol names the artifact rather than by agent category, and it now rebuts the harness note that tells subagents not to write report files instead of merely restating the requirement.
- The rule set was condensed: roughly 176 lines removed across twelve rules, with incident detail relocated to `docs/rule-history/`.
- `orchestrator-report-brevity` covers every reply in the session rather than pipeline status reports alone, since nothing in the harness sets a brevity floor and the pipeline framing left ordinary turns ungoverned.
- `pr-data-fetch` preflights the target repo's permission deny rules and states a blocked fetch as a gap rather than an empty result. A blocked read and an absent record are different findings.
- `pr-queue-review-pipeline` absorbs draft handling, and the review model is scoped by posture.
- `discrete-operations` blocks unquoted shell globs, and git invocations start with the subcommand so allow-list prefixes match.
- Curie and Lovelace no longer run the suite: execution belongs to the remote validation pass, and the validation artifact gained a defined shape.
- Grace treats MCP reachability as a per-server fact established by attempting the fetch, rather than a blanket capability.
- Asimov's catalog gained coined-vocabulary detection, the promoted-doc tone patterns (requester-directed second person, narratorial status asides, significance inflation), and the `arm`/`leg` substitution guidance.
- Effort is pinned per station and the roster was re-tiered; `docs/models.md` carries the assignments.
- `feature-directory-lifecycle`: a feature that ships as several pull requests keeps one directory, anchored to the branch carrying its substance.
- `read-only-external-systems`: opening a pull request is explicitly the user's action, and approval to push is not approval to open one.
- Protocols and rules no longer use negated command blocks, which read as instructions to follow.
- Deployment-specific content moved out of the framework tree into `local/` siblings, extending the convention to `commands/local/` and `docs/local/`.

### Removed
- `block-inbox-em-dashes` hook and the mandatory pre-paste grep. Fifteen runs over a large prose volume produced no true positive, the spaced-hyphen clause produced constant false positives on arithmetic and nested list bullets, and "dash gate clean" read as verification the check does not perform. The spaced-hyphen clause is retired outright; `no-em-dashes` is now a style preference enforced by Asimov's catalog pass. Detail in `docs/rule-history/prose-gates.md`.
- `rules/no-heredoc-commits.md`, folded into `no-inline-script-bodies`.
- `rules/test-quality.md`, promoted to `protocols/test-quality.md`.
- The commit-body judgment kernel: the commit body describes the branch, and judgment routes to the in-session report.

### Fixed
- `install.sh` never distributed `commands/`, so the `battle-mode` command shipped in v0.7 with no way for an installed deployment to invoke it.
- `deliver-watchdog-alerts.sh` shipped in v0.7 despite being scaffolding for two hooks the snapshot excludes. It is now excluded with them.
- Internal product vocabulary, an internal CLI name, and a real PR number had reached framework prose examples through the tone catalog and two register rules. Replaced with generic placeholders that preserve the point each example illustrates.
- The public README described a handoff document the pipeline stopped writing in v0.6 and a validator that runs the suite locally, and its structure diagram was missing `workflows/`.

## [v0.7] - 2026-07-07

### New
- Workflow pilot: `workflows/mob-iteration.workflow.js` encodes one mob iteration as deterministic control flow (station sequencing, artifact verification between stations, capped loops returning structured blockers), for comparison against prose execution on real coding tasks. Boundaries and a comparison checklist in `workflows/README.md`.
- `no-rule-free-forks` rule: rule-governed work (Bash execution, data fetching, dispatch composition, artifact writing) routes to a named agent, a fork, or stays in-agent. General-purpose and Explore subagents don't inherit `rules/` and generate command shapes that trip enforcement hooks.
- `verify-before-clearing` rule: a single check does not establish a failure or a clearance. Declaring failure requires an independent second check; clearing or downgrading a finding requires re-deriving its basis rather than inheriting a reference pattern's, a prior invariant's, or a control's correctness. Bound into review agents.
- `engineer-facing-handoff-scrub` rule and a standalone Asimov invocation context: engineer-facing prose leaving the session (ticket, PR/issue, Slack/Notion content) runs the tone-and-identifier scrub before the final em-dash check, for content Asimov hasn't already touched as part of a pipeline.
- `block-inbox-em-dashes` hook gates writes to the scratch inbox at tool-call time instead of relying on a post-hoc grep.
- `deliver-watchdog-alerts` hook provides exactly-once alert delivery for stuck-agent detection.
- New scripts make several previously-prose behaviors mechanically deterministic: `classify-review-posture`, `archive-window-scan`, `next-artifact`, `check-hook-wiring`, `check-template-drift`.
- `docs/models.md` documents the model-tier ladder (strongest model at adversarial-verify stations, generators one tier down, mechanical stations on the efficient tier) and effort as the first tuning knob.

### Changed
- Planner routing narrowed: standard protocol-governed pipelines execute directly from their protocol. The planner is dispatched only for novel or multi-pipeline compositions, framework architecture, and sequencing trade-offs no protocol resolves. Removes a serialized planning round-trip from every standard pipeline.
- Review passes default to a single pass at the station's configured effort, for both design critique and implementation review. Dual passes are reserved for full-surface changes (an interface or return-shape change, a security surface) and carry split lenses rather than duplicate inspections.
- `discrete-operations` rule extended to block command substitution (`$(...)`, backticks), including inside double-quoted strings where it still executes.
- `block-chained-commands` hook rewritten with staged, quote-aware analysis: fixes a false positive on multi-line quoted messages, catches command substitution, and absorbs heredoc-commit enforcement.
- Model ladder: Grace and Asimov moved down a tier for speed.
- Scratch inbox swept per-file by date-slug instead of wholesale; feature-relevant output routes to the feature directory instead of the inbox; clipboard auto-copy dropped.
- Asimov catalog extended with cadence patterns and a "stamp" verb.

### Removed
- Dispatch-gate hook trio: enforced a rule that no longer existed, false-passed on background dispatch, produced reminder spam, and contradicted the minimal-dispatch design.
- Fable tier retired from the model ladder.
- `scratch/context`: domain-knowledge storage moved to indexed cold storage.

### Fixed
- Several protocol contradictions resolved: mob-pipeline and feedback-response station-skipping authority, post-dispatch-artifact-verify ownership of skipped-write recovery, sandbox-narrowing responsibility, and validation-plan example self-consistency.
- Commit-name hook previously scanned only the message argument with attribution-shape matching that missed short names.
- `.gitignore` scoped the scratch archive subtree out of the `.gitkeep` un-ignore, so relocated placeholders in the regenerated archive no longer surface as untracked.
- AI writing tells (em-dashes, throat-clearing openers, decorative contrasts) stripped from public-facing docs.
- Two doc examples cited a protocol file that had moved out of the public snapshot; repointed to `pr-data-fetch.md`. Missing `workflows/` entry in the README structure diagram added.

## [v0.6.1] - 2026-06-18

### Fixed
- Replaced deployment-specific examples in agent definitions and protocols (reviewer handles, PR numbers, feature names, production filenames) with generic placeholders.
- `rules/artifact-protocol-check.md`: refreshed its example onto a current validation-plan mapping, following the handoff-document retirement in v0.6.

## [v0.6] - 2026-06-18

### New
- Asimov agent and `asimov-catalog` protocol: a tone-and-identifier scrub station at the end of the mob pipeline. Removes AI writing tells (em-dashes, throat-clearing openers, decorative "X, not Y" contrasts, over-announced identifiers, exhaustive case enumerations) from code comments, the PR description, and the commit message body against a defined pattern catalog. Terminal and autonomous; never recycles to Lovelace or Friedman.
- Cycle-review inventory pipeline: the `cycle-review-inventory`, `cycle-inventory-output`, and `archive-window-scan` protocols survey a body of work across a time window (merged PRs, archived feature directories) and emit per-source aggregates that ground downstream synthesis. Grace gains a window-fetch capability for the enumeration step.
- `test-quality` rule: every test names a real failure mode in one sentence. Categories (feature-exercising, contract-shape, tautology, branching-only, library-semantics, restated-literals) carry explicit refuse criteria. Bound into Curie and Friedman.
- `scope-proportional-pipeline` rule: match mob station count to scope. Skip the architect when the dispatch already contains the fix; a single review pass for small localized changes; the full pipeline when an interface, return shape, or security surface changes.
- `no-coauthored-trailer` rule: never append a `Co-Authored-By` or `Generated with` trailer to a commit. Overrides the harness default that adds one.

### Changed
- Fagan and the PR-review protocols gain a SCOPED posture. When assigned as a gating-team reviewer on specific owned paths, Fagan confines the review to that slice and produces a scoped approval, distinct from a holistic whole-diff review.
- Lovelace runs pre-commit hooks by default. `--no-verify` is reserved for hooks that cannot run in the local environment, never to bypass a code defect, with each skipped check recorded for re-run downstream. A new test-writing section binds Lovelace to the `test-quality` rule.
- Mob, pre-ship, and feedback-response pipelines no longer write a separate handoff document. The non-diff-visible judgment (known risks, open questions, review notes) now rides the squash commit body, with the diff and PR description carrying the rest. Curie and Lovelace updated to match.

## [v0.5.1] - 2026-05-22

### Changed
- Operational files (agents, protocols, rules) now reference the install location as "the framework repo" instead of using "Legion" as a repo-name referent. Avoids confusion when the framework is cloned to a non-default path or forked under a different name.

## [v0.5] - 2026-05-22

### New
- Behavioral enforcement hooks ship in the public snapshot for the first time: `block-chained-commands.sh`, `block-git-c-flag.sh`, `block-agent-names-in-commits.sh`, and `block-scratch-output-root.sh`. Prior releases wired these paths into settings.json but excluded the files from the snapshot; v0.5 closes that gap so the installer produces a working configuration end-to-end.
- `post-dispatch-artifact-verify` protocol. Review and digest agents must write findings to disk; the orchestrator verifies the artifact landed before claiming completion. Eliminates the failure mode where inline results never get persisted.
- New behavioral rules: `memory-restraint`, `no-date-fabrication`, `no-empty-commitments`, `verify-before-failure`, `verify-cwd-before-remote-git`. Each rebalances a harness default or codifies a recurring failure mode into explicit guidance.
- Friday template: two new core behavioral constraints. Pipeline execution is not exploratory (don't break protocol flows with mid-station questions), and root-cause investigations include the harness (surface system-prompt and tool-description content when those are the actual driver of behavior the user is pushing back on).

### Changed
- Denniston, Fagan, Friedman, Oppenheimer: Write tool to disk is the terminal step. Returning findings inline is a protocol violation. Pairs with the new `post-dispatch-artifact-verify` protocol.
- Babbage and Penkovsky: "blast radius" renamed to "scope and affected files" for clarity in design and ticket templates.
- Mob-pipeline and feedback-response protocols: test-plan section removed from PR description templates (validation belongs in the validator's artifact, not the PR body).
- No-em-dashes rule: mandatory grep pre-paste check for external-facing content.

### Fixed
- `install.sh` referenced `hooks/block-bash-search.sh`, which was removed in v0.4 and not shipped in any snapshot. The settings.json template now references only existing hooks.

## [v0.4] - 2026-04-29

### New
- Worktree harness invariant documented: `isolation: "worktree"` always grounds on `origin/main` HEAD regardless of orchestrator state. Pre-dispatch flow simplified to a single `git fetch origin`; the `git checkout main` and `git pull` steps from earlier guidance are no longer needed.
- Fix-up-on-live-PR variant for code-producing dispatches that need to stack on top of an existing PR's commits rather than on `origin/main`. Documents the no-isolation workaround and base verification for that case.
- End-to-end WIP transport flow documented: branch carries one iteration of mob output from local to Coder, then is discarded. Single-use, gated push, post-incorporation cleanup.
- Reader Invariants and Posture sections in the coder handoff protocol so the cold-starting validator inherits "no git, no agent attribution, verify before improvising" without each handoff restating it.

### Changed
- Lovelace and Curie: deletion surface is bounded by the design. Identifiers are removed only when the design names them or grants a category (with caller verification for category authorization). Adjacent identifiers stay untouched. If implementation removed something the design did not authorize, Curie surfaces it as a validation finding rather than silently widening test deletions.
- Lovelace and Curie: file operations anchor to the worktree root. Confirm CWD with `pwd` at start; design documents reference repo-relative paths but those resolve under the worktree, never against the main repo. Curie's validation report is the one exception, going to the feature directory.
- User-authorship rule expanded from git-visible artifacts to all externally-targeted artifacts (commits, branches, PR descriptions, ticket content destined for Asana/Linear/GitHub issues). Ticket files staged in scratch are still externally-targeted because their destination is external. Internal scratch path references and pipeline-stage vocabulary are explicitly out of bounds in this content.
- Penkovsky example refreshed and ticket-output Source format aligned with the broader user-authorship scope.
- Branch-create protocol scoped to orchestrator-driven branch creation. Worktree path setup is owned by the worktree rule, not duplicated here.
- Mob pipeline defers worktree lifecycle to the worktree rule rather than restating setup, base verification, and teardown inline.
- Coder handoff split into transport mechanism (worktree rule) vs document content (handoff protocol). Validation Commands section consolidates the canonical command list with a verified date for periodic refresh.
- Friday template refined: planning-engine split (Friday user-facing, Kelly planner) with explicit routing examples for inline vs dispatch decisions.
- Ticket output routing: feature-directory tickets land in the feature directory; one-off tickets land in `scratch/output/_inbox/`. Mob review and validation files are now treated as handoff artifacts.
- Scratch conventions split: `scratch/output/_inbox/` for orchestrator-written ephemera the user acts on (14-day inactivity policy); `scratch/tmp/` for agent and hook session-scoped state (wiped on session start).
- Roster source of truth moved from a standalone protocol to the `agents/` directory itself. List the directory and read each frontmatter description for current scope.

### Removed
- `protocols/agent-roster.md` standalone roster file (drifted from the directory in practice; directory is authoritative).
- Vera's embedded roster table (same reason).

### Fixed
- `install.sh` shipped broken in v0.3: the public-release protocol removed the entire `install/` directory, but `install.sh` references `install/friday-claude.md` to install Friday into the user's CLAUDE.md. Updated step 7 to remove only `install/LEGION_README.md` and leave the Friday template in place.

## [v0.3] - 2026-04-21

### New
- Winterbotham agent consolidates parallel review passes into canonical reports, with same-agent and cross-discipline modes
- Dispatch gate hooks block specialist agent dispatch until the orchestrator has read the target definition and referenced protocols
- Agent watchdog hooks detect stuck agents and surface them to the orchestrator
- Session-orient framework protocol for session-start briefing patterns
- Mob review output protocol extracted from agent definitions
- Feature directory lifecycle rule: `_<slug>/` before PR, `_pr-<number>-<slug>/` after, stage-specific artifact naming, read-before-increment for artifact numbers
- `scratch/tmp/` for ephemeral throwaway files, wiped on session start
- No-em-dashes rule (parenthetical dashes read as LLM-generated)
- No-heredoc-commits rule (heredocs bypass Bash permission pattern matching)

### Changed
- Replaced orchestrator-curated context briefs with feature directory communication. Agents orient from `scratch/output/_<slug>/` rather than receiving pre-digested summaries. Prevents the interpretation-anchoring failure mode where downstream stations inherit upstream scope errors.
- Babbage-Lovelace boundary shifted: designs set direction, implementation owns the details
- Agent effort tiers rebalanced for Opus 4.7
- Pre-ship review runs dual Fagan/Oppenheimer passes with Winterbotham cross-discipline consolidation
- Fagan: explicit protocol discovery section, no dispatcher path dependency
- PR review protocol: inline line-content citation, ref-pinned fetches, bot-resolved thread handling
- Worktree base verification enforced in code-producing dispatches
- Oppenheimer re-review required after blockers are addressed
- README rewritten for public audience, VISION.md tightened

### Fixed
- Watchdog hooks corrected after initial rollout
- scratch/tmp wipe preserves .gitkeep

### Removed
- Orchestrator-curated context briefs (replaced by feature directory communication)
- Scratch-path-resolution hooks (agent/protocol guarantees cover it)

## [v0.2.1] - 2026-04-03

### Fixed
- README now reflects v0.2 changes: Oppenheimer in pipeline, Kelly as operations planner, pre-ship review in usage examples
- VISION.md pipeline diagram updated to include Oppenheimer design critique station

## [v0.2] - 2026-04-03

### New
- Pre-ship review protocol for parallel code inspection and design critique against your own PRs before shipping
- Oppenheimer agent: architectural design critic that stress-tests designs for structural flaws before implementation
- Scratch output conventions protocol: single source of truth for output directory structure
- Archive protocol and daily script to keep scratch/output/ clean (current work week at top level, older content archived)
- PR data fetch protocol extracted as shared resource for Fagan, Denniston, and queue pipelines
- Agent-name commit hook prevents agent references from leaking into git-visible artifacts

### Changed
- Kelly refactored from framework architect to operations planner: returns structured execution plans, does not dispatch agents directly
- Agents no longer contain output path knowledge; they describe what they produce, the orchestrator resolves where it goes
- Mob pipeline design critique station is now mandatory (previously could be skipped)
- Friedman applies adversarial investigation lens and verifies coverage preservation on restructured code
- Fagan verifies line numbers against actual branch files and skips resolved threads entirely
- PR review protocol includes thread resolution filtering
- Mob pipeline produces a single squashed commit with orchestrator-written message
- Worktree isolation is the default for code-producing agents via the Agent tool's isolation parameter
- Repo freshness rule requires checkout before branching, not just pull

### Fixed
- Agent-name commit hook now checks git toplevel instead of CLAUDE_PROJECT_DIR (works correctly in additional directories)
- Deployment-specific branch prefixes removed from framework agent examples

## [v0.1] - 2026-03-24

Initial release. Full agent roster, mob pipeline, PR review pipeline, support agents, documentation, and install script.
