---
paths:
  - "**/*.py"
  - "**/*.pyi"
  - "**/*.rs"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.go"
  - "**/*.ex"
  - "**/*.exs"
  - "**/*.swift"
  - "**/*.kt"
  - "**/*.sh"
  - "**/*.sql"
  - "**/*.java"
  - "**/*.m"
  - "**/*.mm"
  - "**/*.c"
  - "**/*.cpp"
  - "**/*.h"
  - "**/*.rb"
  - "**/*.bzl"
  - "**/BUILD.bazel"
  - "**/*.proto"
  - "**/*.yaml"
  - "**/*.yml"
---

# Code Comment Register

Write comments to flag what the code cannot say for itself: an assumption being made, a non-obvious constraint, a gotcha that will bite a future editor.

## The test: would not knowing this let someone make a wrong edit?

That is the bar a comment has to clear.

A comment that explains why a value holds its value, or why an approach was chosen over another, fails the test even when every word is correct. Keep the decision only where a reader who does not know it would plausibly reach for the rejected alternative and break something.

Three classes that always fail the test:

- **Measurements and research findings.** Population counts, percentages, corpus sizes, "in 100.00% of cases". Their home is the feature directory or the ticket.
- **Justification that the code is correct.** Reviewers establish that.
- **Pending decisions.** A question someone else will resolve elsewhere. This is `protocols/reference-doc-authoring.md`'s evergreen rule applied to code. Track it on the ticket.

What survives is small and concrete: this must run before that, or slices overlap; these two encoders are not interchangeable; this baseline is zero, so any nonzero value is the alert.

Cut the narration and the ornament. If the code is self-evident, write no comment. If the note is load-bearing, make it plain and factual.

## Applies to

Any agent authoring or editing code comments and docstrings, and the orchestrator when it edits code directly. Write in this register from the start rather than leaning on a later tone pass to strip flourish. Asimov's catalog (`protocols/asimov-catalog.md`) also flags ornamental register, but the author owns getting it right first.

## Review history is not a comment

A comment answers a question the next reader will have. It does not rebut a claim raised during review, defend a choice a reviewer questioned, or record that an alternative was considered and rejected, unless a reader arriving cold would independently reach for that alternative. The tell is a paragraph that only makes sense to someone who watched the review happen.

Reasoning about the change belongs in the feature directory; reasoning a future editor needs belongs in the comment.

Watch also for a comment asserting a conclusion that a ticket or artifact later reframes.

## One fact, one home

Three shapes to watch for:

- A test docstring restating the comment on the symbol under test.
- A branch or dispatch site restating the enum member it returns.
- A helper docstring restating a module-level comment thirty lines above it.

**Pick the home closest to the definition and delete the rest.** The enum member owns a skip reason's meaning; the constant owns why it holds its value; the function owns its own contract; the test owns only what the test pins that its assertions do not show. A comment justifying a test's existence by re-deriving the production behavior is the copy to cut.

The corollary when cutting: check that the surviving home is actually complete. Deleting a call-site copy is only safe if the definition carries the fact; where the explanation lives solely at the call site, the definition has to gain it rather than the site simply losing it.

## Measure the result, do not sample it

`scripts/prose-lint.py <repo-path> [base-ref]` scans the comments and docstrings a branch added and prints file:line for every catalog tell and volume smell it finds. Run it before handing code to a reviewer.

Every hit is a prompt to look, not a verdict. Drive it to a residual you have adjudicated, not necessarily to zero.

## Proving a prose pass changed nothing else

Parse the committed and edited versions, strip docstring nodes from both, and compare the ASTs. Identical trees mean nothing but prose moved. Where the pass deliberately includes a rename, reverse the rename in the working copy first and compare again, so the diff that remains is exactly the intended one.

## Asimov cannot rule on whether a comment should exist

Do not route comment volume or necessity to the tone pass. The catalog governs register: ornament, cadence, inflation. Volume and necessity are the author's call, and the reviewer's; ask them, not Asimov.

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
