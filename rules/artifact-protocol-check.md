# Artifact Protocol Check

Before producing a named artifact, scan `protocols/` and `protocols/local/` for a governing protocol. If one exists, read it before writing.

Named artifacts: review reports, validation plans, design documents, digests, and any output whose type maps to a known protocol. The trigger is the artifact type, not the path that produced it; the protocol governs the format whether an agent writes the artifact or the orchestrator writes one inline.

## Examples

Good, the governing protocol is read before writing:

```
Scan: protocols/, protocols/local/
Read: protocols/validation-plan.md
Write: scratch/output/_<feature-slug>/curie_1.md
```

Bad, the artifact is produced from context alone:

```
Write: scratch/output/_<feature-slug>/curie_1.md  # format inferred from dispatch content
```

The bad example may omit required fields, include disallowed content, or follow a stale format the protocol has since corrected.
