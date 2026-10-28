# Artifact Protocol Check

Before producing a named artifact, scan `protocols/` and `protocols/local/` for a governing protocol. If one exists, read it before writing.

Named artifacts: review reports, validation plans, design documents, digests, and any output whose type maps to a known protocol. The trigger is the artifact type, not the path that produced it; the protocol governs the format whether an agent writes the artifact or the orchestrator writes one inline.

Good:

```
Read: protocols/validation-plan.md
Write: scratch/output/_<slug>/curie_1.md
```

Bad, format inferred from the dispatch:

```
Write: scratch/output/_<slug>/curie_1.md
```
