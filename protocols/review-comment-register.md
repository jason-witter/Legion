# Review the Code, Not the Implementer

A finding is about the code. Make the code the grammatical subject of the sentence and keep the author out of it.

This governs any finding written for someone else to read: external PR review, mob code review, design critique, and the paste-ready comments the user posts under their own name. That last case includes a comment or reply the orchestrator drafts inline, outside any review pipeline; read this before writing the first one.

## The test: what is the sentence's subject?

Not "does it contain the word you." A sentence can review the person with no second person in it: "the author chose to duplicate the enum here" and "this was done incorrectly" both put a human in the dock. So does "your description mentions," in a softer register.

Rewrite until the code, the file, or the change is the thing being described:

| Reviews the implementer | Reviews the code |
|---|---|
| You already hit this once | `test_discount_rounding.py` is the live example |
| Your description mentions #1290 | The description mentions #1290 |
| The author chose to duplicate the enum | The enum is defined twice |
| You should import this instead | This could join the existing import block |
| You didn't add a test for the refund path | The refund path has no test coverage |

## First person for the reviewer is fine

"I do not see a cycle in the way" and "my read is that this can wait for #1290" are correct. The rule constrains who the finding is *about*, not whether the reviewer appears in it.

## Questions to the author

A question is addressed to a person; keep the code as the subject anyway:

- Good: "Is this shape already changing in #1290?"
- Bad: "Did you plan to change this in #1290?"

## What this does not license

Not vagueness. Passive voice to avoid naming a subject ("it was decided that") is worse than either option. Name the file, the line, and the construct.

Not softening the finding. Severity, the tier, and the ask are unchanged by register. A Blocking finding stays Blocking.

## Enforcement

This rule governs who a finding is about. `protocols/review-reply-economy.md` governs how long a reply to one should be. Both are the author's to get right, and neither is a tone-pass verdict.

Authors own getting this right the first time, the same division `rules/code-comment-register.md` draws for code comments. `protocols/asimov-catalog.md` carries the pattern so the tone pass catches what survives.
