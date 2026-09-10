# Engineer-Facing Handoff Scrub

Engineer-facing prose that leaves the session runs the Asimov tone-and-identifier pass first. That pass is the scrub; there is no second mechanical gate behind it.

## Trigger

Destination plus prose volume governs, the same model as `rules/user-authorship.md`. The scrub fires when both hold:

1. **Destination is engineer-facing**: ticket, PR, or issue bodies; Slack or Notion messages; any prose written to `scratch/output/_inbox/` for the user to paste. The rule is generic to any external paste target.
2. **More than a couple of prose sentences**: a multi-sentence ticket description, PR summary, or message body carries enough surface for tone tells to land.

Below that volume, hand it over as written. Exempt regardless of volume: command snippets, code, identifiers, and quoted data. Asimov edits prose, not data (Asimov catalog Hard Exclusions).

## The pass is not on request, but it runs on settled content

The Asimov dispatch is a required step before engineer-facing prose leaves the session, and the user should not have to ask for it. What it must not do is run while the content is still moving.

**Settled** means the artifact's substance has stopped changing: the user has accepted the underlying analysis, or has asked for the paste-ready version, or the work behind the artifact has converged with no open question in the conversation that would rewrite the text. A draft handed over mid-way through a back-and-forth about fundamentals is not settled, however finished the prose looks.

The test: if the next user message could plausibly change what the artifact *says*, do not dispatch yet. Draft, hand over the path, and say the tone pass is still outstanding. Dispatch once the substance lands.

Why the timing is load-bearing: a pass is a full agent run, so it costs tokens and adds latency to the hand-off, and any substantive revision after it invalidates it. Dispatching early does not waste one run, it invites one run per iteration. Observed 2026-08-10: a drafted thread reply was scrubbed the moment it was written, then the user reframed the whole analysis and most of the reply had to be rewritten, so the pass bought nothing.

This still overrides a general instruction not to dispatch agents unprompted, including the harness-level "do not call the AgentTool unless the user requested it" that some sessions carry. A tone pass on settled paste-ready prose is part of delivering the artifact the user asked for, not separate work.

## There is no character-class substitute for the pass

The em-dash write gate was retired 2026-08-19 (`rules/no-em-dashes.md`). It was never the scrub: it caught one pattern, and every other catalog tell (significance inflation, requester-directed second person, colon-gloss cadence, status asides) passed straight through it while "gate clean" implied a checked artifact. Do not reinstate it, and do not report a mechanical check in place of the pass. When the pass has not run, say so plainly.

## Examples

Good: a multi-sentence ticket description bound for Asana, where the underlying fix is already agreed:

```
1. Asimov pass over scratch/output/_inbox/refund-sign-fix.md (catalog section 5 bar)
2. Hand to user (tell them the path)
```

Good: the same description drafted while the user is still arguing about the root cause:

```
1. Hand to user: the path, plus "tone pass is still outstanding"
2. Asimov pass once the analysis stops moving
```

Good: a one-line Slack status update goes over as written, no Asimov pass (below the volume threshold).

Bad: scrubbing a draft that sits on an analysis the user is actively reframing. The pass is invalidated by the next message and has to run again.

Bad: writing `scratch/output/_inbox/pr-body.md` and handing it over with no pass and no mention that the pass is outstanding. Silence reads as "this is clean," and AI tells ship in content the user posts under their own name.

## Fan the pass out by file

**One dispatch per file, in parallel.** This is `rules/dispatch-and-continue.md` applied to the scrub, and the scrub is the easiest place to forget it because the pass reads as one job rather than N. A tone pass carries no cross-file state, so a serial dispatch scales wall-clock with file count; fanned out, it costs one file's worth of latency.

1. Enumerate the files first: for a mob handoff, the diff of the feature commits against their merge base, restricted to files carrying prose. Skip pure data, generated output, and identifiers.
2. One dispatch per file, all in a single message so they run concurrently.
3. **Name each pass's artifact in its dispatch**, using the letter-suffix convention from `rules/feature-directory-lifecycle.md` (`asimov_3a.md`, `asimov_3b.md`, one letter per file). Do not leave the number to the agent.
4. Keep the drafted commit body and PR description together as **one** unit; they are one file and one voice.

The suffix is not cosmetic, and this is the one place the fan-out actively breaks the numbering rule. "List the directory before incrementing" assumes sequential dispatch; parallel agents all list at the same instant, all see the same highest number, and all write the same filename. The last writer wins silently and every earlier report is destroyed with no error. Observed 2026-08-28: two concurrent passes both wrote `asimov_3.md` and one was lost. The code edits survived because they were in different files, which is exactly why the loss is easy to miss.

Consistency is not a reason to serialize: the catalog is the shared standard, and per-file agents applying it reach the same verdicts. If two files need to agree on a phrasing the catalog does not settle, fix the catalog. When several dispatches report the same tell, that is a catalog candidate, not a re-run.
