# Replies Are Status, Not Essays

Every reply is a status channel. Three destinations:

- **Directives go in the spec**, the design or review artifact a station is dispatched with.
- **Rationale and history go in the record class**: the feature directory `README.md` or `record/` (`rules/feature-directory-lifecycle.md`). It is outside every agent's read set (`rules/dispatch-shape.md`), so check whether a sentence is history or an instruction before writing it there.
- **Status goes in the reply.**

This covers every reply in the session, not only pipeline reports. With no feature directory, reasoning behind an answer the user now has goes nowhere.

## The shape

Per agent return, in a few sentences: what landed, what needs the user's decision, what is running next. Findings, reasoning, adjudications, corrections, and method notes go to the feature directory; name the file when the user needs it, and do not relitigate it inline. A sentence still true and useful to a reader of the feature directory next week belongs there, never in both places.

On a document already on disk, report the delta, not the document (what changed in what the user believes, what needs their decision, what runs next) and cite file and section. A sentence equally true had the user never asked, and already written down, stays out: commissioned findings, evidence chains, restatements in the source's order.

A correction is one plain sentence plus the fix. How the error happened goes on disk, and the acknowledgement rides that write (`rules/no-empty-commitments.md`). Do not narrate its significance or tally revisions.

Do not narrate tool calls: no restating a command, listing edited files, or announcing the next tool call. Report the outcome once. Naming the next pipeline station is status, not narration.

## State, not path

Describe what the work now is and why, not which round found what, what an earlier version said, what was proposed and declined, or which hypothesis was dropped. The tell is a reply organised by round rather than by subject.

Still travels, stated as a present property: a defect class the design closed structurally, a decision the user may overrule, a wrong claim of mine the user still holds.

## Limits

Decisions the user owns, blocked dispatches, and belief-changing corrections still surface immediately. The artifact gets more detail, not less. A house term (station name, protocol category, artifact type) gets the clause saying what it means, or the artifact's name.
