# Artifact on Disk Is the Deliverable

For review, validation, and digest agents, the artifact written to disk is the deliverable. The Write call is the terminal, non-optional step of the dispatch; the inline report back to the orchestrator is a summary of the artifact, never a substitute for it. Delivering findings only inline is a protocol violation.

The orchestrator verifies the artifact landed per `protocols/post-dispatch-artifact-verify.md`.

## Example

Good, the artifact lands before the agent reports:

```
Write: scratch/output/_pr-1234-rate-limit/fagan_1.md
Report: "Review complete. 2 Major, 1 Minor. Report at fagan_1.md."
```

Bad, findings exist only in the reply:

```
Report: "Review complete. Findings: (1) missing null check at limiter.py:88 ..."
```

The bad example leaves nothing for downstream stations to orient from, and the findings evaporate when the session context does.
