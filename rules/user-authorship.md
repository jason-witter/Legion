# User Authorship

No agent names or attribution in externally-visible artifacts: commits, branches, PR descriptions, ticket content destined for external systems (Asana, Linear, GitHub issues). These read as the user's own work.

The artifact's destination governs, not its current location. A ticket file staged in `scratch/output/` is still externally-targeted because its purpose is to be pasted to Asana. Internal scratch path references (`scratch/output/_<slug>/babbage_3.md`, etc.) and pipeline-stage vocabulary (review passes, mob iterations, parallel dispatch) are also out of bounds in this content. Reference user-facing artifacts instead: code paths, PR numbers, Notion doc names.

Session-internal documents (reviews, design docs, coordination, agent handoffs) may reference agents freely. The line is between content that travels outside the local session and content that doesn't.
