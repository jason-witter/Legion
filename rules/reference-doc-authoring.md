# Authoring Reference and Architecture Docs

Guidance for standalone reference docs (system overviews, lifecycle maps, architecture writeups) that get promoted to a shared destination such as a wiki or knowledge base. Complements the Asimov catalog (tone and identifier tells) and `rules/engineer-facing-handoff-scrub.md` (the scrub gate).

The through-line: a promoted doc is read by people who were not in the authoring session. Strip everything that assumes shared context or leans on session framing, and keep the structure lean.

## Evergreen: leave out pending decisions

An evergreen doc does not carry transient content: open questions, "TBD which is live" flags, in-flux figures, or a decision that someone else will resolve soon and elsewhere. Such a number dates the doc the moment it is locked, and the resolution will not land here anyway.

When a figure is disputed or not yet locked, state the stable fact without the number, or omit it. Do not embed a future decision in a doc meant to outlive it.

This does not mean swallow the open item. Surface it to the user in the session, and track it where open items live (the ticket, the working doc, the design plan), not in the reference. The reference describes what is settled; the tracker holds what is not.

## Structure and headers

- Plain topic headers. Drop "Part N:" numbering (the destination's table of contents carries ordering) and editorial parentheticals ("(this is the key to everything)", "(where the org is headed)"). Prefer "Grants, and why deferral differs by source" over "Part 1: The grant side (how a grant is recorded...)".
- Introduce internal codenames once, in the section that defines them. Do not leak phase names, project codenames, or in-house jargon into the one-paragraph summary or the diagram, where a reader has no definition yet. Use plain terms in those layers ("now / future phases" rather than an internal phase codename), and reserve the codename for its defining section.

## Diagrams

- Nodes carry structure, not numbers. Keep quantitative detail (month counts, percentages, rates) in the accompanying table or prose, not in the diagram nodes. Duplicating it bloats the visual and creates two places to maintain the same figure.
- Say it once. If a node already states a fact, the edge into it does not need to repeat it.

## Tables

- Drop columns that are mostly empty. A column that reads "n/a" for most rows is noise; fold the sparse signal into an adjacent cell.

## Linking referenced docs

- Link a referenced doc, do not name it in bare prose, whenever its URL is already in hand (it came back from a search or fetch earlier in the session). This applies everywhere the doc is named: inline in the body and in a source or appendix list. A reader expects to click through, not to search a quoted title.
- For Notion pages, prefer the native page-mention/link form; a plain `[Title](url)` link is the acceptable floor. Confirm the mention syntax against the Notion markdown spec (`notion://docs/enhanced-markdown-spec`) before relying on the richer form. Non-Notion references (code paths, GitHub PRs, external URLs) follow their own conventions.
- If a referenced doc was never located, name it plainly and look it up when the link would matter, rather than leaving a dead reference.

## Register

- Attribute to teams or roles, not named individuals. A shared doc outlives the staffing, and coworker names read as session gossip and date the doc. Write "the accounting team books this by hand", not "<person>'s process". This is distinct from `rules/user-authorship.md`, which governs agent names.
- The tone tells that most often survive from a session draft (significance inflation, narratorial status asides, requester-directed second person, provenance name-drops and inline ticket numbers) are owned by Asimov catalog patterns 1.12 through 1.14. Run the scrub before promoting; this rule is the structural complement to it. Where a doc reference is a chatty aside, recast it to a plain fact and let a linked citation carry it; where it is load-bearing in the sentence, keep it inline and link it.
