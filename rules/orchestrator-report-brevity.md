# Replies Are Status, Not Essays

Everything written back to the user is a status channel, not the place rationale lives. Rationale
goes to disk, in the artifact or the feature directory README, where it survives the session and
where whoever picks up the work cold will actually find it.

## Scope: every reply, not just pipeline reports

This rule was written for the case where the user reads the session in the background while a
pipeline runs, and its examples are still pipeline-shaped. The constraint is not. It applies to
every reply in the session: answering a question, reporting on a document, thinking out loud about
a design, closing out a turn with no pipeline and no feature directory behind it.

Nothing in the harness sets a brevity floor. A reply is as long as the model makes it, so the only
thing holding the line is this rule, and reading it as pipeline-specific leaves ordinary turns
ungoverned. That is where the verbosity actually lands, because those turns feel too small to need
a rule.

Where there is no feature directory, the third destination is the right one more often than it
looks: not the reply, not disk, but nowhere. Reasoning that led to an answer the user now has does
not need to be preserved anywhere.

## The shape

Per agent return: what landed, what needs the user's decision, what is running next. A few
sentences. Findings, reasoning, adjudications, corrections, and method notes go into the feature
directory; the reply names the file when the user needs to read it, and otherwise does not
relitigate it inline.

The test: if a sentence would still be true and useful to someone reading the feature directory
next week, it belongs in the feature directory, not in the reply. Writing it in both places is
the failure mode, because the inline copy is what makes the report long and the on-disk copy is
the one that lasts.

## Reporting on a document already on disk

Reading an artifact and reporting on it is the same status channel, and it is the easiest place to
write an essay by accident: the material is sitting in context, restating it feels like diligence, and
the result is a summary the user could have read faster in the original.

The document is already durable. Nothing about it needs to be reproduced in the reply. Report the
delta: what changed in what the user believes, what needs their decision, what is running next. Cite
the file and the section for anything they should read themselves.

The test: a sentence that would be equally true if the user had never asked, and is already written
down where they can find it, does not go in the reply. That includes findings the user commissioned
and already expects, evidence chains, and any restatement organized in the source document's order
rather than by what the user has to do next.

## Corrections stay short too

A correction the user needs gets one plain sentence plus the fix. The analysis of how the error
happened goes on disk. Do not narrate the correction's significance, tally prior revisions in
prose, or explain the lesson inline; a paragraph of self-examination is the same verbosity
problem wearing a more diligent face. `rules/no-empty-commitments.md` still applies: the
acknowledgement rides a real persistence action, and that action is the write to disk.

## Do not narrate the tool calls

The user sees the tool calls. Restating what a command did, listing files just edited, or
announcing what is about to run next duplicates something already on their screen. Report the
outcome the calls add up to, once, and only where the outcome is not obvious from the calls
themselves.

## What this does not license

Brevity is not silence on things the user owns. A decision the user must make, a blocked
dispatch, and a correction that changes what they believe all still surface immediately. Cutting
those to save words is a different failure than the one this rule addresses.

Nor is it a reason to write less to disk. The artifact gets more detail, not less, precisely
because the reply gets less.

It is also not license to compress by relaying a label. Framework vocabulary (station names,
protocol category names, artifact types) is defined where the user has no reason to read, so a
term that means something to an agent can reach them meaning nothing. Compressing a table of
seventeen classified tests to "all feature-exercising" is shorter and carries less than saying
they run the production path against realistic inputs. Observed 2026-08-28: the user read exactly
that line and had to ask what it meant, and the term turned out to exist nowhere outside this
framework. When the short form is a house term, spend the extra clause on what it means, or name
the artifact and let them read the column.

## Example

Bad, the reasoning is delivered twice:

```
Numerics landed, 283 passing. The implementer overrode both the design and its critique on
the both-zero add scale rule. The design said the smaller scale, the critique confirmed it,
CPython does the opposite, so the case table would have pinned the wrong string. It dropped
the special case with 290,738 comparisons behind it. What makes this worth a pass is that the
design and critique agreeing reads as verification and is not, because both sat downstream of
the same premise... [six more paragraphs]
```

Good:

```
Numerics landed: 283 passing, verified. Dual review pass running.

One item flagged for a second read: the implementer overrode both the design and its critique
on the both-zero add scale rule. Rationale and the adjudication scope are in the README's
next-up section. Two findings routed out to other file owners, also recorded there.

Read-layer round four still needs your call.
```
