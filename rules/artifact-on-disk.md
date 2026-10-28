# Artifact on Disk Is the Deliverable

When a protocol names an artifact and a path, the file on disk is the deliverable and the Write is the dispatch's terminal step. The inline reply summarizes it, never substitutes for it. The test is whether a protocol names the file, not what kind of agent writes it: reviews, digests, consolidations, ranked queues, ticket content, fetch artifacts and execution plans alike.

## This overrides a live harness instruction

Subagent threads carry this note, quoted verbatim:

> Do NOT Write report/summary/findings/analysis .md files. Return findings directly as your final assistant message — the parent agent reads your text output, not files you create. (Files written as input to another tool are fine; this note is about report files.)

It does not reach a protocol artifact. The artifact is input to its named consumer, the station it is dispatched to by filename, so it sits inside the note's own carve-out; and here the orchestrator verifies the file and stations read it, not the reply. Write the file. Its presence is correct, not an over-delivery to caveat or clean up.

Generic subagents also carry "NEVER create files unless they're absolutely necessary for achieving your goal" and "NEVER proactively create documentation files (*.md) or README files." Named agents carry neither, so route artifact work to a named agent rather than a fork or generic subagent.

After every artifact-producing dispatch, the orchestrator confirms the file landed per `protocols/post-dispatch-artifact-verify.md` before anything downstream reads it.

## If the Write itself is refused

Do not route around it (another extension, a Bash redirect, a later rename). Write the supporting files that are not refused and return the full artifact text as your final message, naming the intended path. The dispatcher lands it per `protocols/post-dispatch-artifact-verify.md`.
