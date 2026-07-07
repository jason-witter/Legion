# Engineer-Facing Handoff Scrub

Engineer-facing prose that leaves the session runs the Asimov tone-and-identifier pass before the em-dash grep. The Asimov pass first, the em-dash grep last as the clean-gate on the post-Asimov text.

## Trigger

Destination plus prose volume governs, the same model as `rules/user-authorship.md`: what matters is where the content is headed and how much prose it carries, not where the file currently sits.

The scrub fires when both hold:

1. **Destination is engineer-facing** — ticket, PR, or issue bodies; Slack or Notion messages; any prose written to `scratch/output/_inbox/` for the user to paste. Deployment surfaces (Asana, Linear, GitHub) are examples; the rule is generic to any external paste target.
2. **More than a couple of prose sentences** — borrowing the proportionality model from `rules/scope-proportional-pipeline.md`. A multi-sentence ticket description, PR summary, or message body carries enough surface for tone tells to land, so it earns the full pass.

Below that volume, the em-dash grep alone suffices. A one-line paste does not need a tone pass; the dash scan is the only gate.

Exempt regardless of volume: command snippets, code, identifiers, and quoted data. Asimov edits prose, not data (Asimov catalog Hard Exclusions). A pasted SQL query, a CLI invocation, or a quoted error string is not prose and does not trigger the scrub.

## Check Order

1. **Asimov pass first.** Run the Asimov tone-and-identifier pass against the artifact, applying `protocols/asimov-catalog.md`. The PR-description bar (catalog section 5) is the paste-ready calibration; apply it to any engineer-facing prose, not just PR descriptions. Asimov edits in place.
2. **Em-dash grep last.** After Asimov returns, run the scan from `rules/no-em-dashes.md` on the post-Asimov text as the clean-gate. A clean grep is the bar before the content is handed over or copied to the clipboard. For files under `scratch/output/_inbox/`, `hooks/block-inbox-em-dashes.sh` already enforces this at write time; the manual grep matters for paste content living outside the inbox.

The order is load-bearing: the em-dash grep verifies the final text, so it runs on what Asimov produced, not on the pre-scrub draft. Asimov's own catalog covers dashes (pattern 1.1), but the standalone grep is mechanical verification that recall alone has failed to provide (`rules/no-em-dashes.md`).

## Examples

Good — a multi-sentence ticket description bound for Asana:

```
1. Asimov pass over scratch/output/_inbox/refund-sign-fix.md (catalog section 5 bar)
2. grep -nP '[–—]|\s-\s' scratch/output/_inbox/refund-sign-fix.md  → clean
3. Hand to user (tell them the path)
```

Good — a one-line status update to paste into Slack:

```
grep -nP '[–—]|\s-\s' <content>  → clean
(no Asimov pass: below the prose-volume threshold)
```

Bad — handing over a PR body without the pass:

```
Write: scratch/output/_inbox/pr-body.md
Hand pr-body.md to user   # skipped Asimov, skipped grep
```

The bad example ships AI tells into content the user pastes as their own work. The tone fingerprint and any stray dash reach GitHub unscrubbed.

## Who Runs the Pass

Asimov is the agent that runs the tone-and-identifier pass. He reads `protocols/asimov-catalog.md` as the authoritative pattern list and edits in place. The orchestrator runs the em-dash grep as the final clean-gate.
