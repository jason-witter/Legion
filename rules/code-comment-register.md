# Code Comment Register

Code comments are breadcrumbs for the next reader. Write them to flag what the code cannot say for itself: an assumption being made, a non-obvious constraint, a gotcha that will bite a future editor.

## The test: would not knowing this let someone make a wrong edit?

That is the bar a comment has to clear. It is narrower than "is this true and useful", and narrower than "does this explain something the code does not say", because both of those admit an unbounded amount of accurate writing.

A comment that explains why a value holds its value, or why an approach was chosen over another, fails the test even when every word is correct. Its cost is that the reader now believes they must understand the comment before they can touch the surrounding code. Observed 2026-09-04, in the user's words: "I can see why this is helpful, but now I feel like I have to understand this comment to understand the surrounding code. But do I need to?" The answer for that comment was no, and it was one of about eight hundred lines that went the same way.

**This corrects an earlier version of this rule**, which listed "a decision and the alternative it rejected" as a thing to write down. That is the largest single source of comment bloat on pipeline-produced code, and it is not rescued by being true. Keep the decision only where a reader who does not know it would plausibly reach for the rejected alternative and break something.

Three classes that always fail the test, called out because each one feels like diligence:

- **Measurements and research findings.** Population counts, percentages, corpus sizes, "in 100.00% of cases". These are the output of an investigation, and the investigation's home is the feature directory or the ticket. A field comment carrying a nine-digit row count is the clearest instance of the tell.
- **Justification that the code is correct.** Reviewers establish that; the comment inherits nothing from having argued it.
- **Pending decisions.** A question someone else will resolve elsewhere dates the comment the moment it resolves, and nobody comes back to update it. This is `rules/reference-doc-authoring.md`'s evergreen rule applied to code. Track it on the ticket.

What survives is small and concrete: this must run before that, or slices overlap; these two encoders are not interchangeable; this baseline is zero, so any nonzero value is the alert.

Cut the narration and the ornament. A comment that restates what the line plainly does earns nothing, and dressing a fact in decorative phrasing ("the reapable universe", "whose semantic context has moved past") costs the reader attention for no information. If the code is self-evident, write no comment. If the note is load-bearing, make it plain and factual.

This is about register, not line count. The test is not "is it short" but "does it call out an assumption, decision, or gotcha the reader needs and the code does not show". A three-line comment that captures a real concurrency race passes; a one-line flourish fails.

## Applies to

Any agent authoring or editing code comments and docstrings, and the orchestrator when it edits code directly. Write in this register from the start rather than leaning on a later tone pass to strip flourish. Asimov's catalog (`protocols/asimov-catalog.md`) also flags ornamental register, but the author owns getting it right first.

## Review history is not a comment

A comment answers a question the next reader will have. It does not rebut a claim raised during review, defend a choice a reviewer questioned, or record that an alternative was considered and rejected, unless a reader arriving cold would independently reach for that alternative. The tell is a paragraph that only makes sense to someone who watched the review happen.

This is where comment bloat actually comes from on a pipeline-produced change. Each station has reasoning it wants preserved, the field comment is the nearest durable home, and nothing in the pipeline owns saying no. Reasoning about the change belongs in the feature directory; reasoning a future editor needs belongs in the comment; the overlap is smaller than it looks. A one-line change with four paragraphs above it is the symptom.

Watch also for a comment asserting a conclusion that a ticket or artifact later reframes. The comment is the copy nobody re-reads, so it is the copy that goes stale and contradicts the tracker.

## One fact, one home

The dominant driver of unreviewable comment volume is not any single long comment. It is the same fact written in two or three places, and it is nearly invisible while writing because each copy is locally reasonable.

Three shapes, all observed on one branch 2026-09-04 by four agents working independently on different files:

- A test docstring restating the comment on the symbol under test.
- A branch or dispatch site restating the enum member it returns.
- A helper docstring restating a module-level comment thirty lines above it.

This reads worse to a reviewer than plain redundancy. No copy is wrong, so there is nothing to reject, and the reviewer instead meets the same explanation on page after page and concludes the change is dense. On the branch that prompted this rule, eleven of thirteen deleted docstrings in one test file restated prose that already sat beside the code under test, near enough point for point.

**Pick the home closest to the definition and delete the rest.** The enum member owns a skip reason's meaning; the constant owns why it holds its value; the function owns its own contract; the test owns only what the test pins that its assertions do not show. A comment justifying a test's existence by re-deriving the production behavior is the copy to cut.

The corollary when cutting: check that the surviving home is actually complete. Deleting a call-site copy is only safe if the definition carries the fact, and on that branch two skip reasons turned out to carry their explanation solely at the check site, so the enum had to gain one rather than the site simply losing one.

## Measure the result, do not sample it

`scripts/prose-lint.py <repo-path> [base-ref]` scans the comments and docstrings a branch added, against its merge base, and prints file:line for every catalog tell and volume smell it finds. Run it before handing code to a reviewer.

It exists because the rule alone did not work. On the branch that prompted this section, a full register pass ran, the author then read one docstring at random and found a catalog 1.4 violation in it, and asked the reasonable next question: how many others are there. Reading more docstrings cannot answer that. The scan put the number at 209 hits across 33 files, including the same "X, not Y" shape in 32 places and undefined house nouns in 33, which turned an open-ended worry into a list that could be driven down.

Two design points worth keeping if it is ever rewritten. It measures against the **merge base**, not the upstream tip, because upstream moves and diffing against its tip attributes upstream's own commits to the branch. And it reports only lines the branch **added**, so pre-existing prose in a shared file the branch merely touches never appears; that keeps the output actionable rather than a standing indictment of the repo.

Every hit is a prompt to look, not a verdict. Drive it to a residual you have adjudicated, not necessarily to zero.

## Proving a prose pass changed nothing else

A comment pass touches many files and is supposed to change no behavior, which makes "I was careful" the weakest possible assurance. Prove it: parse the committed and edited versions, strip docstring nodes from both, and compare the ASTs. Identical trees mean nothing but prose moved. Where the pass deliberately includes a rename, reverse the rename in the working copy first and compare again, so the diff that remains is exactly the intended one.

This is cheap, it runs without the test suite, and it converts the claim from a promise into a result. It matters most when the pass is fanned out, because no single agent has seen the whole diff.

## Asimov cannot rule on whether a comment should exist

Do not route comment volume or necessity to the tone pass. The catalog governs register: ornament, cadence, inflation. It has no instrument for "delete this block," so four paragraphs of clean, plain prose pass it, and the pass reads as a verdict on the comment when it was only a verdict on the writing. Volume and necessity are the author's call, and the reviewer's; ask them, not Asimov.

## Examples

Ornamental, cut it:

```
# Map membership is the reapable universe. Shadow mode observes every label here,
# and flipping a label's flag ON arms reaping for it.
```

Breadcrumb, keep it:

```
# One flag per label, never shared: a shared flag would arm more than one label on
# a single flip and defeat the per-label idempotency gate.
```

The second names the decision (one flag per label) and the failure it prevents. The first just narrates the data structure in a raised voice.
