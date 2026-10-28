# Finding Disposition

The single scale for review findings. A finding's tier names what happens to it, not how severe it feels. A verification pass additionally dispositions the findings of the report it is closing out.

Authority for Fagan, Friedman, Oppenheimer, and Winterbotham. Agent definitions and consuming protocols reference this file; they do not restate the tiers. One edit site, so a recalibration lands everywhere at once.

## Tiers

Three tiers. The tier is the action.

- **Blocking** — the change should not proceed as written.
- **Comment** — worth spending a review comment on; not a gate. The author may decline.
- **Noted** — recorded, no comment expected, no action implied.

What each tier means per context:

| Context | Blocking | Comment |
|---|---|---|
| External PR review (Fagan) | The user requests changes | The user leaves a comment; the author may decline |
| Mob code review (Friedman) | The station loops back to Lovelace | The implementer addresses it; no re-review gate |
| Design review (Oppenheimer) | The design returns to Babbage | The designer addresses it; no re-review gate |
| Consolidation (Winterbotham) | Inherited from the source report | Inherited from the source report |

Noted is identical in every context: it exists so the finding is on the record. The user may promote a Noted entry if they disagree with the call.

**Tier order for merges:** Blocking > Comment > Noted. When two passes flag the same finding at different tiers, the higher tier stands. Consolidation applies the order mechanically and does not re-adjudicate a tier; the one exception is the pre-recalibration straddle case below.

**Recommendation follows from the tiers.** Any Blocking finding means request changes. No Blocking and at least one Comment means approve with comments. Neither means approve. In the mob pipeline, "no Blocking findings" is the station's go condition; the pipeline's blocker binary is this tier and nothing else.

## The tier gate

Each tier requires the artifact that makes it actionable. A finding that cannot supply its tier's artifact **drops one tier**. Apply the gate to every finding before the report is written.

1. **Blocking requires a named consequence.** What breaks, on which path, under what conditions, verified directly per `rules/verify-before-clearing.md`. A possibility is not a consequence. Without one, the finding drops to Comment.
2. **Comment requires a specific ask.** The change the reviewer wants, or a question the author can answer in one reply. Without one, the finding drops to Noted.
3. **Noted requires only that it is true and cited.** A finding that is not cited is discarded, not filed.

This gate is the mechanism the scale runs on. A finding that is defensible but carries no ask lands in Noted by construction, rather than arriving as a mid-tier item the reader has to triage by hand.

**Design review instance.** In design review, a named consequence must be paired with a concrete alternative the designer can act on. An objection that blocks without directing fails the gate and drops to Comment. This is the general rule applied to designs, not a separate one.

**Test-quality mapping.** Findings from `protocols/test-quality.md`: a single refused-category test is a Comment, and a cluster as that protocol defines it is Blocking. Both still pass the gate, so a single refused test with no stated ask is Noted. A test that fails that protocol's removal check is not a refused-category finding and does not take this mapping; the instance below governs it.

**A test that cannot fail.** A test whose assertions cannot fail carries a named consequence on its own: a regression on the path it names ships undetected, and the suite reports coverage it does not have. That consequence clears step 1 without a behavioral defect anywhere else in the change, and no widening class applies to it. The removal check in `protocols/test-quality.md` is how the reviewer establishes it. Two positions:

- **A test that is dead as of this change is Blocking-eligible.** Name the test, the behavior it is named for, and why its assertion can no longer fail, verified directly per `rules/verify-before-clearing.md`: read the patch target, the fixture, or the assertion and say what makes it inert. "It may not be intercepting" is a possibility, not a consequence, and drops to Comment under step 1 like any other.
- **A change that installs the mechanism while every test on it still fails correctly is Comment.** Nothing is dead yet, so the consequence is owed by tests written against that surface later. The ask is the change that closes the trap.

An automated reviewer grades an assertion as present, so a dead test reads to it exactly as a live one does and a green suite looks the same either way. This class surfaces only for a reader who checks what the assertion would still catch.

**Absent coverage.** A missing test is tiered like any other finding and sectioned with the rest; it gets no section of its own. Its ask is the test to add, and its consequence is the regression the absence allows, named specifically. A missing test named without that regression carries no ask and is Noted. It reaches Comment through the fourth widening class below, and coverage absence alone does not reach Blocking; where the untested path also carries a defect, that defect is a separate finding at its own tier. A test that exists on the path and cannot fail is not absent coverage: absence is an honest gap, and a dead test is misleading about what the suite covers, so it is tiered by the instance above and not capped at Comment.

## Clearing or downgrading a finding

Clearing a finding, rating it down a tier, or dropping a reviewer comment as addressed requires a basis re-derived independently, never a correctness inherited from somewhere else. This applies in every context in the tier table, and to a digest clearing a reviewer's comment on the user's own PR.

### The four disciplines

**1. Audit the reference, not just the change.** When a finding is cleared because the fix mirrors an existing pattern, the reference pattern is in scope. Audit it for the same defect class the finding raised.

**2. Re-derive the invariant at the altitude the change introduces.** When a change adds fan-out, concurrency, or multiplicity, the invariant must hold at the new altitude, not the old one. Verify the aggregate property the multiplicity creates: counter and total accuracy, ordering, mutual exclusion, idempotency under retry.

**3. Trace the control through the real execution model.** When a finding is downgraded because a compensating control exists, follow that control through the execution model the code actually runs under, including concurrent and interleaved paths. Only tracing establishes that the control holds under that model.

**4. Enumerate the realizations of a risk class; one test does not discharge the class.** List the distinct ways the risk manifests and confirm each is covered. (Coverage is distinct from validity; `protocols/test-quality.md` governs validity.)

### Class or instance

A verification pass asks of each finding it discharges whether the fix closed the class or the instance it was found in; the discharge obligation below is the instrument.

Where a class exists, a fix round enumerates the class before choosing a remedy, and the pass that follows re-derives the enumeration rather than checking the list it was handed.

The discriminator is whether the defect is one instance of a rule that has other instances: a classification, a policy, a predicate shared across cases. There, enumerate. Where the defect is a single wrong value or one missing check on one path, there is no class and asking for an enumeration buys ceremony.

Where there is a default to invert, inverting it so the set fails safe is stronger than a better enumeration and is worth reaching for.

Good, the reference is audited before the clearance stands:

```
Finding: new writer omits the dedup guard.
Author: matches the existing writer in ingest.py, which also omits it.
Reviewer: pulled ingest.py. The existing writer omits the guard too and double-writes
under retry; the reference is defective. Finding stands for both sites.
```

Bad, the reference's correctness is inherited:

```
Finding: new writer omits the dedup guard.
Author: matches the existing writer in ingest.py.
Reviewer: confirmed it matches the existing pattern. Cleared.
```

## The discharge obligation

A **verification pass** is a re-review dispatched against a report whose findings the change was meant to close out: Friedman re-reviewing after Lovelace revises, Oppenheimer re-reviewing a revised design, any later pass over a change a prior report already examined. It receives exactly one prior report, the current artifact for its own `(agent, run)` pair at N-1 (`rules/feature-directory-lifecycle.md`), and it owes that report a disposition for every actionable finding in it.

**The obligation is additive. It is never a scope.** Re-review is a full pass, unnarrowed (`protocols/mob-pipeline.md`); the prior report adds a checklist to complete on top of that pass and takes nothing off it. A defect the prior report never raised is caught by this pass or by nobody, so a pass that reports only on prior findings has not run. Receiving the report licenses nothing about reading the change more narrowly than the opening review did.

A run's opening review has no predecessor and carries no discharge section. Nothing older than N-1 reaches the pass at all.

### Dispositions

Every finding in the prior report's actionable section (Blocking and Comment) takes exactly one:

- **Discharged** — the named consequence is no longer reachable, verified directly in the code as it now stands.
- **Standing** — the consequence is still reachable. The finding is written into this report's actionable section as a finding on the change, at whatever tier the gate now gives it; it does not inherit its former tier.
- **Declined** — Comment only. The finding was not acted on, and Comment was never a gate. A Blocking finding cannot be declined: it is Discharged or Standing.

Recorded (Noted) entries need no disposition, because Noted implied no action.

### What Discharged requires

A diff that touched the cited line is not a discharge. To write Discharged:

1. Read the code at the location the finding cited, as it now stands.
2. State what makes the named consequence unreachable.
3. Where the finding named a risk class rather than a single site, enumerate that class's realizations and confirm each one is closed.

Step 3 is the mechanism that makes the fourth clearing discipline above checkable: the prior report supplies the enumeration to hold the fix against, which is exactly what a pass lacking that report cannot do. Absent it, a finding that was closed and one that was relocated read identically, and a fix closing a subset of a class reads as a full clearance.

**A relocated defect is Standing, and is cited at its new location.** The fix moved the consequence instead of removing it, so the class it belongs to is still open.

## The comment bar

The default bar sits where an automated code-review bot running on the same change sits: post only for a defect with a concrete failure path in the changed code. **Every widening past that bar is named in the finding.**

A finding with no behavioral consequence reaches Comment only when it carries one of these, stated in the finding itself:

- The change sets a boundary or interface that a known stack of follow-on changes builds on, making this the cheapest point to correct it.
- The finding depends on cross-PR, cross-repo, or team context an automated reviewer structurally lacks.
- The finding is a convention or ownership matter the team enforces.
- The change leaves a behavior it introduces or alters uncovered by any test, so a later regression goes undetected.

Absent one of the four, a non-behavioral finding is Noted. These are the classes a human reviewer can see and a bot cannot, so naming one is what separates a structural comment that earns its place from a defensive one.

The fourth class is narrow on purpose: it covers a behavior of the change that no test covers at all, not a test that is merely thin. Widening it to cover weak coverage generally would readmit the defensive findings the bar exists to exclude. It does not cover a test that exists and cannot fail. That finding carries its own consequence, so it is not a widening at all, it is not capped at Comment, and it names no class here.

**Bot coverage never enters a tier.** An automated reviewer's silence is not evidence a finding is wrong, and a finding is never rated down because a bot was clean. That is the inherited clearance the clearing disciplines above forbid. The bot informs where the bar sits, never what an individual finding is worth.

## Report sectioning

Two top-level sections, and on a verification pass a third (below). The actionable one is subdivided by whether the finding gates the merge. The comment/no-comment line is structural, so no finding carries a verdict line and no flat list needs per-item triage.

External PR review:

```markdown
## Comment Candidates
### Blocking
### Comment
## Recorded (no comment expected)
```

Mob code review and design review:

```markdown
## Actionable
### Blocking
### Comment
## Recorded (no action expected)
```

The top-level header takes the context-appropriate name; the `Blocking` and `Comment` subsection names never vary. Omit an empty subsection. Do not omit the Recorded section merely because it is long: below-the-bar findings stay in the report, separated from the actionable ones rather than dropped.

**Every finding on the change is sectioned here.** A report gets no parallel top-level section for a category of finding about the change, missing tests included; a category-named section outside these two puts findings where the tier is invisible and the reader has to triage by hand. A section whose subject is something other than the change (surrounding code the reviewer read for context, CI state, calibration data) is not a finding on the change and is unaffected by this.

**The discharge section on a verification pass.** One top-level section, placed first, one line per actionable finding in the prior report:

```markdown
## Discharge of friedman_refund_2.md
- Blocking, unbatched writes in the retry path (payments/retry.py:88) — Discharged: the write now
  happens once outside the loop, and both other callers of `_flush` batch.
- Blocking, missing dedup guard on the replay path — Standing: the guard landed at the cited site,
  and the same consequence still reaches through `replay_async` (payments/replay.py:142), cited
  below.
- Comment, helper name misleading — Declined.
```

Name the prior artifact in the header, so the input the pass discharged is on the record. A third top-level section is permitted here on the terms the paragraph above already sets: this section's subject is the prior report, not the change. It is an audit checklist, not a second home for findings, so a Standing entry points to its own finding in the actionable section instead of restating it. A consolidation carries its sources' discharge sections forward merged, and re-adjudicates a disposition no more than it re-adjudicates a tier.

**Which variant a consolidated report takes.** A consolidation of two passes by the same agent keeps that agent's native variant. A cross-discipline consolidation whose sources bring different variants takes `Actionable` / `Recorded (no action expected)`, because its reader is the change's own author, who acts on the report rather than posting comments to anyone. `Comment Candidates` is reserved for a report whose findings are candidate comments on someone else's change.

Per-finding content (citations, line content, categories, alternatives) is owned by the consuming protocol or agent definition. This file owns only the tier and the sectioning.

**Register is owned by `protocols/review-comment-register.md`** (read it before writing findings; it does not load ambiently) and applies in every context in the table above: the code is the grammatical subject of a finding, and the author stays out of it. It is named here because it interacts with the tier and the answer is that it does not move one. A finding rewritten off the author is the same finding, so its tier, its named consequence, and its ask are unchanged; softening an ask is not a register fix, and a Blocking finding phrased about the code is still Blocking.

## Comment bar calibration

Open until resolved, following the precedent of the scoped-model experiment in `protocols/pr-queue-review-pipeline.md`. The bar above is a starting position derived from one PR, not a measurement.

External PR reviews already fetch automated-reviewer comments, so the delta is free. Record it in one short section:

```markdown
## Comment Bar Delta
- Automated reviewer posted: <count and one-line topics, or "nothing">
- This review's comment candidates: <count and one-line topics>
- Widening justifications invoked: <which class, per finding>
```

**Resolve after several reviews rather than leaving it open.** The user's own posting behavior is the ground-truth label: the findings they actually post are at or above the right bar. If the review's candidates track what the user posts, delete this section and keep the bar. If the review is consistently wider, tighten the widening list and delete this section.

## Reading a pre-recalibration report

Reports written before this scale keep their vocabulary. Dated review directories are historical records; rewriting them would falsify what the reader was told.

When reading or citing one:

- **Critical maps to Blocking.**
- **Minor maps to Comment or Noted**, decided by the tier gate.
- **Major does not map.** Re-adjudicate it under the gate. Major is precisely the tier that conflated the two things this scale separates, so a mechanical mapping would carry the conflation forward.

**Straddle case.** When a feature directory holds artifacts in both vocabularies, a later review pass and any consolidation re-adjudicate the old-vocabulary findings under these tiers rather than mapping them mechanically. This is the one place consolidation exercises judgment on a tier; everywhere else the tier order applies as written.

## Neighboring scales

Two other files carry severity-adjacent vocabulary measuring something else. Neither is governed by this protocol.

- `protocols/digest-analysis.md` (Blocking / Informational) triages incoming reviewer comments on the user's own PRs. Its "Blocking" means someone else blocks the user's merge; this scale's "Blocking" means the user would block someone else's. Symmetric subject, different axis.
- `protocols/validation-plan.md` (Priority: blocking / informational) rates whether a validation check gates the ship. Validation is not review and is out of scope here.

## Usage

Referenced, not invoked. Any agent or protocol assigning a tier to a review finding reads this file as the authority: the tiers, the gate, the clearing disciplines, the bar, the sectioning, and the discharge obligation a verification pass carries. Consuming protocols and agent definitions add only the per-context clause their station needs.
