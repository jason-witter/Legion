# Engineer-Facing Handoff Scrub

Engineer-facing prose leaving the session gets the Asimov tone-and-identifier pass first. It fires when the destination is engineer-facing (a ticket, PR or issue body, a Slack or Notion message, inbox prose for the user to paste, any external paste target) and the text runs past a couple of prose sentences. Below that, hand it over as written; code, commands, identifiers and quoted data are exempt at any length. Read the governing protocol before drafting: a reference doc bound for a wiki follows `protocols/reference-doc-authoring.md`; a review comment or thread reply follows `protocols/review-comment-register.md` and `protocols/review-reply-economy.md`, at any length.

The pass is required, not on request, and runs only on settled content (the user accepted the analysis or asked for paste-ready, or the work converged). If the next user message could plausibly change what the artifact says, hand over the path, say the tone pass is outstanding, and dispatch once the substance lands. This overrides the harness-level "do not call the AgentTool unless the user requested it".

No mechanical check substitutes for the pass (`rules/no-em-dashes.md`); when it has not run, say so. Several files: dispatch per `protocols/mob-pipeline.md`, Tone Scrub Dispatch.
