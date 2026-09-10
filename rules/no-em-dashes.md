# No Em Dashes

Do not use em dashes or en dashes as parenthetical punctuation. Restructure the sentence: use commas, parentheses, semicolons, or split into two sentences. The parenthetical dash pattern reads as LLM-generated.

This is a style preference, enforced by writing well rather than by a gate. Asimov owns the mechanical pass on prose that leaves the session (`rules/engineer-facing-handoff-scrub.md`), and the dash pattern is one entry in `protocols/asimov-catalog.md` alongside the tells that actually cost more: significance inflation, requester-directed second person, colon-gloss cadence, status asides.

## The gate was retired 2026-08-19

`hooks/block-inbox-em-dashes.sh` and the mandatory pre-paste grep are gone. Three reasons, from a session that ran the grep about fifteen times across a large volume of prose:

- **It never fired on a true positive.** The `[–—]` character class is cheap and unambiguous, and the model does not emit those characters at a rate that justifies a gate.
- **The spaced-hyphen clause was noise.** `[[:space:]]-[[:space:]]` matched JavaScript arithmetic and markdown nested-list bullets constantly, and every hit had to be adjudicated by hand. That clause is retired entirely; a spaced hyphen is no longer a violation.
- **It read as verification it did not perform.** "Dash gate clean" signals a checked artifact. In the session that retired it, the failures that actually cost time were structural and substantive (the verdict buried behind the evidence, a staging dataset named as if it were the ERP, invented vocabulary for something the domain already names), and the gate was clean on every one of them.

The residual exposure is surfaces that do not inherit `rules/` (`rules/no-rule-free-forks.md`). Asimov covers paste-bound prose, so route prose through a ruled surface rather than reinstating a character-class check.

Incident detail: `docs/rule-history/prose-gates.md`.
