# Rule History Notes

Incident detail moved out of `rules/` during the 2026-08-03 compression pass. The rules carry the constraints; this file carries the stories for maintainers auditing why a constraint exists.

## no-em-dashes: the -E vs -P silent failure

A twelve-file em-dash gate once passed without scanning a single byte. The check used `grep -P`; BSD grep (macOS `grep`) has no `-P` and exits 2 with `invalid option` instead of scanning, and the caller's `if grep ...` treated exit 2 the same as exit 1, reporting every file clean. This produced the rule's two requirements: `-E` with literal dash characters and a POSIX class, and explicit exit-code branching in any wrapper script (0 hit, 1 clean, anything else means the check never ran).

## engineer-facing-handoff-scrub: serial scrub wall time

Before the per-file fan-out instruction, a two-dozen-file diff scrubbed serially took tens of minutes with nothing to show for the wait; fanned out, the same pass costs one file's worth of latency. The user has confirmed the fan-out's wall-time value directly. Treat per-file parallel dispatch as settled behavior, not an optimization to revisit.

## engineer-facing-handoff-scrub: the clean-grep illusion

Orchestrators running only the em-dash grep on every artifact felt compliant because a mechanical gate ran and came back clean. The grep catches one pattern; significance inflation, requester-directed second person, colon-gloss cadence, and status asides all pass through it. That observation produced the rule's "pass is not on request" section.

## no-em-dashes: the gate retired, 2026-08-19

The write-time hook and the mandatory pre-paste grep were removed. Evidence came from a long investigation session that ran the grep about fifteen times over a large volume of prose: it never hit a true positive, and its two halves differed sharply in value. The `[–—]` character class is cheap and unambiguous. The `[[:space:]]-[[:space:]]` clause produced constant false positives on JavaScript arithmetic and markdown nested-list bullets, every one adjudicated by hand, so the spaced-hyphen clause was retired outright rather than kept.

The deciding argument was the clean-grep illusion in the section above, played out at cost. That session's real failures were structural and substantive: the verdict buried behind the evidence, a BigQuery staging dataset named as if it were the ERP, invented vocabulary for something the domain already names, and two CSS bugs in a published page. The dash gate was clean on every one of them, and "dash gate clean" was reported each time.

What replaced it: nothing mechanical. Asimov's catalog pass is the enforcement, and `rules/engineer-facing-handoff-scrub.md` now states that an unrun pass is reported as unrun rather than substituted with a character-class check. Known residual exposure: surfaces that do not inherit `rules/` (`rules/no-rule-free-forks.md`). The answer to that is routing prose through a ruled surface, not reinstating the hook.
