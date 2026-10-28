# Rule History: Artifacts and Scratch

Incident detail moved out of `rules/artifact-on-disk.md` and `rules/scratch-tmp.md` during the 2026-08-03 compression pass. The rules carry the constraints; this file carries the incidents behind them.

## artifact-on-disk.md

- The harness anti-report bullet quoted in the rule was confirmed present on 2026-07-30 in both a named framework agent and a generic subagent.
- Before the override callout existed, the silent version of the conflict was observed repeatedly: an agent produced full findings, reasoned that writing a report would violate the harness directive, returned the substance inline, and skipped the Write. Nothing in the reply signaled an overridden rule, so the orchestrator discovered it only when the expected path was empty and saved the content on the agent's behalf. The recovery worked, but the artifact carried no author and the next station got a file the agent never verified.
- An earlier revision named only review, validation, and digest artifacts; every other artifact-producing agent read the rule as somebody else's constraint. The current phrasing keys on "a protocol names the file" for that reason.

## scratch-tmp.md

- The `scratch/tmp/` sweep was originally unconditional at SessionStart. SessionStart also fires for concurrent sessions, so opening a second session deleted the first session's in-flight agent state; a long-running implementation agent lost its verification scripts mid-run. The 24-hour grace dates from that incident.
- The filter is on mtime rather than creation time deliberately: last-write is what indicates a file is still in use.
