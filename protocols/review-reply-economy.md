# A Reply Is As Long As The Thread Needs

Spend a reviewer's reading time only where the reply carries something they do not already have.

Read this before drafting any reply the user will post on a review thread, whoever drafts it: a station under `feedback-response.md`, or the orchestrator writing one inline or to the inbox with no pipeline behind it.

Most threads need one or two sentences. "Comment corrected in `<sha>`, and the mechanism is ticketed as shared surface" is the whole reply.

## What earns length

- **Holding a position.** Declining a suggested change means naming the hazard the change has to answer, and asking the question that would settle it.
- **Asking something.** A question needs enough context to be answerable.
- **Conceding something the diff does not show.** Where their measurement beat your reasoning, say so specifically.
- **A framing that answers several threads at once.** One position stated at the top of a PR can replace four separate defenses, and is worth the words.

## What does not

- **The mechanism the reviewer traced.** Do not restate their trace back at them.
- **Evidence for a claim nobody disputed.** Keep it on disk.
- **The verification method.** That a conclusion came from an AST pass over 14,000 files belongs in the artifact, not the reply, unless the method is the thing in question.
- **Validation tokens.** "Correct, and...", "Fair, ...", "Good catch". `protocols/asimov-catalog.md` 1.17 carries the pattern.

## The test

Ask what the reviewer does differently having read the reply. If the answer is "resolves the thread", the reply is a sentence. If the answer is "answers a question" or "reconsiders a position", it is as long as that needs and no longer.

## Length is the author's call, not the tone pass's

Same division `rules/code-comment-register.md` draws for comments. Get the length right when drafting; do not route volume to the scrub.
