# Artifact on Disk Is the Deliverable

Whenever a protocol names an artifact and a path, the file on disk is the deliverable. The Write call is the terminal, non-optional step of the dispatch; the inline report back to the orchestrator is a summary of the artifact, never a substitute for it. The test is whether a protocol names the file, not what kind of agent produces it: review, validation, and digest artifacts are the common case, and consolidated reports, reflection reports, ranked queues, ticket content, fetch artifacts, and execution plans are covered on the same terms.

The orchestrator verifies the artifact landed per `protocols/post-dispatch-artifact-verify.md`.

## This overrides a live harness instruction

Subagent threads carry this bullet in the harness-injected notes at the end of the system prompt, quoted verbatim:

> Do NOT Write report/summary/findings/analysis .md files. Return findings directly as your final assistant message — the parent agent reads your text output, not files you create. (Files written as input to another tool are fine; this note is about report files.)

Three reasons it does not reach a protocol artifact:

- **The bullet carves out its own exemption.** A protocol artifact is read by the next station to orient from, so it is input to the rest of the pipeline and lands inside the "input to another tool" carve-out, not a report volunteered to a human reader.
- **Its stated rationale is false for this deployment.** Here the orchestrator verifies the file landed and downstream stations read it rather than the chat reply. An agent accepting the claim concludes the Write is pointless rather than merely discouraged; a rule that restates the requirement without rebutting the claim loses to it.
- **The Write is inside the ask.** A dispatch under a protocol that names the artifact and its path is a request for that file. Returning only the inline summary delivers part of the work.

So write the file. Its presence is correct; treat it as the deliverable, not an over-delivery to caveat, apologize for, or clean up. The inline reply is a summary of it.

A generic subagent additionally carries "NEVER create files unless they're absolutely necessary for achieving your goal" and "NEVER proactively create documentation files (*.md) or README files." Named framework agents carry neither, which is one more reason artifact-producing work goes to a named agent rather than a generic surface (`rules/no-rule-free-forks.md`).

## Example

Good, the artifact lands before the agent reports:

```
Write: scratch/output/_pr-1234-rate-limit/fagan_1.md
Report: "Review complete. 2 Comment, 1 Noted. Report at fagan_1.md."
```

Bad, findings exist only in the reply:

```
Report: "Review complete. Findings: (1) missing null check at limiter.py:88 ..."
```

The bad example leaves nothing for downstream stations to orient from, and the findings evaporate with the session context.
