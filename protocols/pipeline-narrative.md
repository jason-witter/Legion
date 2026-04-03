# Pipeline Narrative

The orchestrator maintains a single accumulating narrative document as a sequential pipeline progresses through its stations. Individual station artifacts are not written; the narrative is the output.

## Usage

Invoke this protocol when running a sequential pipeline where each station hands off to the next. After each station completes, the orchestrator distills that station's output into the narrative before advancing.

## Document Structure

The document opens with a brief summary and accumulates one section per station as the pipeline runs.

```markdown
# {Task Name}

## Summary

{A short paragraph framing what this pipeline built or changed, the core approach taken, and the outcome. Written after the pipeline completes — this is the first thing a reader sees and should orient them before the station-by-station detail.}

## {Station Name}

{Distilled narrative for this station — added after it completes.}

## {Station Name}

{Distilled narrative for this station — added after it completes.}

...

## Open Items

{Unresolved flags that could not be addressed in-pipeline and require human attention. If none, omit this section.}
```

## Section Content Principles

Each station is responsible for signaling to the orchestrator what matters from its output. The orchestrator distills those signals into a section according to these principles:

**Decision-focused.** Capture what was decided and why. The reasoning behind a decision is more valuable than the decision itself.

**Include rejected alternatives.** They carry the most explanatory value. A reader who knows what was ruled out — and why — understands the design more deeply than one who only knows what was chosen.

**No process commentary.** Do not describe the pipeline, reference other stations, or meta-narrate the coordination. The document should read as if the pipeline doesn't exist.

**No restatement.** Each section picks up where the last left off. Do not re-describe decisions or context already captured in earlier sections.

**Nothing trivial.** Omit changes, findings, or decisions that were straightforward and leave no useful signal for a future reader.

## Open Items

The final section captures anything that could not be resolved in-pipeline: ambiguities left open, findings accepted with reservations, gaps in coverage that matter, questions deferred to the human. If the pipeline resolved everything cleanly, omit the section.

## Orchestrator Responsibilities

The orchestrator owns this document. Stations report back; the orchestrator distills.

- Create the document after the first station completes
- Add each section immediately after the corresponding station completes
- Write from the station's output, not from the station's process
- The narrative should read coherently to a developer with no context on the pipeline's internal workings

## Tone and Scope

Technical and decision-focused. Written for a developer who needs to understand what was built and why — not how the pipeline ran.

- Past tense throughout
- No meta-commentary about coordination, agents, or pipeline mechanics
- No hedging ("this should work", "appears to be correct")
