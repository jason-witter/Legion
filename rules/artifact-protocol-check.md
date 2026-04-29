# Artifact Protocol Check

Before producing a named artifact, scan `protocols/` and `protocols/local/` for a governing protocol. If one exists, read it before writing.

Named artifacts include: handoff documents, review reports, validation plans, digests, and any output whose type maps to a known protocol.

The trigger is the artifact type, not the path that produced it. Whether an agent writes a handoff or the orchestrator writes one inline, the protocol governs the format.

## Examples

Good — agent discovers the governing protocol before writing:

```
Scan: protocols/, protocols/local/
Read: protocols/local/coder-handoff.md
Write: scratch/output/handoff.md
```

Bad — agent produces the artifact from context alone:

```
Write: scratch/output/handoff.md  # format inferred from dispatch content
```

The bad example bypasses the protocol. The resulting artifact may omit required fields, include disallowed content, or follow a stale format the protocol has since corrected.
