# Artifact Protocol Check

Before producing a named artifact, scan `protocols/` and `protocols/local/` for a governing protocol. If one exists, read it before writing.

Named artifacts include: review reports, validation plans, design documents, digests, and any output whose type maps to a known protocol.

The trigger is the artifact type, not the path that produced it. Whether an agent writes the artifact or the orchestrator writes one inline, the protocol governs the format.

## Examples

Good — agent discovers the governing protocol before writing:

```
Scan: protocols/, protocols/local/
Read: protocols/validation-plan.md
Write: scratch/output/_<feature-slug>/curie_1.md
```

Bad — agent produces the artifact from context alone:

```
Write: scratch/output/_<feature-slug>/curie_1.md  # format inferred from dispatch content
```

The bad example bypasses the protocol. The resulting artifact may omit required fields, include disallowed content, or follow a stale format the protocol has since corrected.
