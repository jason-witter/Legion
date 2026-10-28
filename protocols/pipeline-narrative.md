# Pipeline Narrative

The orchestrator maintains one append-only narrative per run, recording what the pipeline decided and why. It is the user's audit trail: written for a developer who needs to understand what was built without reading thirteen artifacts.

## Read-set position

The narrative is **record class** (`rules/feature-directory-lifecycle.md`). No agent reads it and no dispatch names it (`rules/dispatch-shape.md`, "The read set"; `protocols/mob-pipeline.md`). It is not a handoff, not a context brief, and not a place a spec can live: anything a later station must act on belongs in the design or review artifact that station is dispatched with, or it reaches nobody.

**Code claims in the narrative are historical.** A sentence describing the code was true when the station reported it and may not be true now. Never carry a code fact out of the narrative; re-derive it from the tree (`rules/code-facts-from-the-tree.md`).

## Log, not state

The record class holds two documents with different jobs. Writing to the wrong one is what produces a document nobody trusts.

| | Pipeline narrative | Feature `README.md` |
|---|---|---|
| Shape | append-only log, one section per station | current state, revised in place |
| Organized by | work phase, in pipeline order | subject |
| Cardinality | one per run | one per feature |
| Answers | what was decided, and why | what is true now, what is open, where to pick up |

A section already written is never revised. When a later station contradicts an earlier one, the later section records the correction and the earlier section stands as what was believed at the time. Superseding in place destroys the audit trail, which is the document's only purpose.

## Parameters

- **Feature slug** — the feature directory.
- **Run scope** — assigned by the orchestrator when the run opens (`rules/feature-directory-lifecycle.md`, "Runs and Currency").

## Path

- Single-run feature: `scratch/output/_<slug>/record/pipeline-narrative.md`
- Several runs: `scratch/output/_<slug>/record/pipeline-narrative-<run>.md`

A new run opens a new file. Appending a second run's stations to the first run's narrative interleaves two passes against different surfaces and leaves neither readable.

## Execution steps

1. **After the first station completes**, create the file with the task-name heading and that station's section. The summary is written last, so leave it out.
2. **After each subsequent station completes**, append one section — written from the station's report, not from its process.
3. **On a correction**, append the correcting station's section and leave prior sections as written.
4. **On a new run**, start a new file at the run-scoped path.
5. **At run close**, write the summary at the top and the unresolved section at the bottom.
6. **Route live items to the README.** The narrative's unresolved section is frozen at close and is not updated as items resolve.

## Document structure

```markdown
# {Task Name}

## Summary

{A short paragraph framing what this run built or changed, the core approach, and the outcome.
Written at close — this is the first thing a reader sees and should orient them before the
phase-by-phase detail.}

## {Work Phase}

{Distilled narrative for this phase — added after the station completes.}

## {Work Phase}

{Distilled narrative for this phase — added after the station completes.}

...

## Unresolved at close

{What could not be resolved in-run. Omit if nothing was. The live list lives in the README.}
```

**Headings name the work phase, not the agent** — Design, Design critique, Implementation and review, Validation. The document reads as an account of the work, so the machinery that produced it does not appear in the outline.

## Section content principles

Each station signals to the orchestrator what matters from its output. The orchestrator distills those signals into a section:

**Decision-focused.** Capture what was decided and why. The reasoning behind a decision is more valuable than the decision itself.

**Include rejected alternatives.** They carry the most explanatory value. A reader who knows what was ruled out, and why, understands the design more deeply than one who only knows what was chosen.

**No process commentary.** Do not describe the pipeline, reference other stations, or meta-narrate the coordination. The document should read as if the pipeline doesn't exist. Facts about the machinery rather than the work — artifact provenance, a backfilled report, a station re-dispatched — are the README's, not the narrative's.

**No restatement.** Each section picks up where the last left off. Do not re-describe decisions or context already captured in earlier sections.

**Nothing trivial.** Omit changes, findings, or decisions that were straightforward and leave no useful signal for a future reader.

## Tone

Technical and decision-focused, for a developer who needs to understand what was built and why.

- Past tense throughout
- No meta-commentary about coordination, agents, or pipeline mechanics
- No hedging ("this should work", "appears to be correct")
