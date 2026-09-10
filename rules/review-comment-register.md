# Review the Code, Not the Implementer

A finding is about the code. Make the code the grammatical subject of the sentence and keep the
author out of it.

This governs any finding written for someone else to read: external PR review, mob code review,
design critique, and the paste-ready comments the user posts under their own name.

## The test: what is the sentence's subject?

Not "does it contain the word you." A sentence can review the person with no second person in it:
"the author chose to duplicate the enum here" and "this was done incorrectly" both put a human in
the dock. So does "your description mentions," in a softer register.

Rewrite until the code, the file, or the change is the thing being described:

| Reviews the implementer | Reviews the code |
|---|---|
| You already hit this once | `test_adjustment_calculation.py` is the live example |
| Your description mentions #1290 | The description mentions #1290 |
| The author chose to duplicate the enum | The enum is defined twice |
| You should import this instead | This could join the existing import block |
| You didn't add a test for the refund path | The refund path has no test coverage |

The finding is identical in every row. What changes is whether the reader has to absorb an
accusation before they can evaluate it.

## Why the framing is load-bearing and not politeness

A defensive author argues instead of fixing, so author-directed framing lowers the chance the
finding gets acted on. That cost lands hardest on the findings that need the most explanation,
which are the ones a human reviewer catches and automation does not.

A review comment also outlives the exchange. It is read by people who were not there, sometimes
months later on a blame trail, and a comment addressed at a named colleague reads worse cold than
it did in the moment.

## First person for the reviewer is fine

Owning an assessment is not the same as directing one. "I do not see a cycle in the way" and "my
read is that this can wait for #1290" are correct: they mark the claim as the reviewer's
judgment rather than a fact, which is honest about certainty. The rule constrains who the finding
is *about*, not whether the reviewer appears in it.

## Questions to the author

A question is legitimately addressed to a person, and there is no way to ask one without them. Keep
the code as the subject anyway:

- Good: "Is this shape already changing in #1290?"
- Bad: "Did you plan to change this in #1290?"

The first asks about the code and gets the same answer. The second asks the author to account for
a decision.

## What this does not license

Not vagueness. Passive voice to avoid naming a subject ("it was decided that") is worse than
either option, because the finding stops being locatable. Name the file, the line, and the
construct; that is what makes the code the subject rather than a way of dodging one.

Not softening the finding. Severity, the tier, and the ask are unchanged by register. A Blocking
finding stays Blocking; it just does not arrive as a personal failing.

## Enforcement

Authors own getting this right the first time, the same division `rules/code-comment-register.md`
draws for code comments. `protocols/asimov-catalog.md` carries the pattern so the tone pass catches
what survives, but a pass that has to rewrite every finding is a signal the authoring station is
wrong, not that the pass is working.

Observed 2026-09-10: a review comment framed as crediting the author for catching a trap
("You already hit this once") was read as an accusation that they had nearly shipped it. The tone
pass had explicitly considered the second person and cleared it, on the correct reasoning that the
addressee was the comment's genuine reader. Genuine address was never the question; direct address
carries a tone cost in a review comment regardless of who is reading.
