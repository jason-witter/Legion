# Authoring Reference and Architecture Docs

Governs standalone reference docs (system overviews, lifecycle maps, architecture writeups) that get promoted to a shared destination such as a wiki or knowledge base. Complements the Asimov catalog (tone and identifier tells) and `rules/engineer-facing-handoff-scrub.md` (the scrub gate).

## Evergreen: leave out pending decisions

An evergreen doc does not carry transient content: open questions, "TBD which is live" flags, in-flux figures, or a decision that someone else will resolve soon and elsewhere.

When a figure is disputed or not yet locked, state the stable fact without the number, or omit it. Do not embed a future decision in a doc meant to outlive it.

Surface the open item to the user in the session, and track it where open items live (the ticket, the working doc, the design plan), not in the reference.

## Structure and headers

- Plain topic headers. Drop "Part N:" numbering and editorial parentheticals ("(this is the key to everything)", "(where the org is headed)"). Prefer "Orders, and why fulfillment differs by channel" over "Part 1: The order side (how an order is recorded...)".
- Introduce internal codenames once, in the section that defines them. Do not leak phase names, project codenames, or in-house jargon into the one-paragraph summary or the diagram. Use plain terms in those layers ("now / future phases" rather than an internal phase codename), and reserve the codename for its defining section.

## Diagrams

- Nodes carry structure, not numbers. Keep quantitative detail (month counts, percentages, rates) in the accompanying table or prose, not in the diagram nodes.
- Say it once. If a node already states a fact, the edge into it does not need to repeat it.

## Tables

- Drop columns that are mostly empty. A column that reads "n/a" for most rows is noise; fold the sparse signal into an adjacent cell.

## Linking referenced docs

- Link a referenced doc, do not name it in bare prose, whenever its URL is already in hand (it came back from a search or fetch earlier in the session). This applies everywhere the doc is named: inline in the body and in a source or appendix list.
- For Notion pages, prefer the native page-mention/link form; a plain `[Title](url)` link is the acceptable floor. Confirm the mention syntax against the Notion markdown spec (`notion://docs/enhanced-markdown-spec`) before relying on the richer form. Non-Notion references (code paths, GitHub PRs, external URLs) follow their own conventions.
- If a referenced doc was never located, name it plainly and look it up when the link would matter, rather than leaving a dead reference.

## Describe, do not instruct, and do not reassure

**Say what a thing is, not what the reader should do about it.** Cut directives to the reader: "start here", "don't sum X without naming the basis", "worth raising", "don't chase this column", "do it before step 5". State the fact underneath instead: "a program-wide total spans two price bases" rather than "don't sum the program without saying which basis".

**Do not pre-empt objections by naming them.** No section headed "things that will look wrong and are not". State the fact positively and let it stand: "`TRIAL-B` is subscription free trials; earlier files used this label for reverse trials" rather than "this will look like explosive growth, but it did not move".

**Cut assurances that nothing is broken and nothing changed.** "No credit moved between months", "none of that is a defect", "not a duplicate", "not rounding". Where the fact matters, state it as a fact ("credit quantities and account codes are as they were"); where it exists only to forestall a worry, it goes.

## Hard wraps

`rules/no-hard-wrapped-markdown.md` governs. One paragraph is one line; tables, list items and fenced code keep their own lines.

## Register

- Attribute to teams or roles, not named individuals. Write "the accounting team books this by hand", not "<person>'s process". This is distinct from `rules/user-authorship.md`, which governs agent names.
- The tone tells that most often survive from a session draft (significance inflation, narratorial status asides, requester-directed second person, provenance name-drops and inline ticket numbers) are owned by Asimov catalog patterns 1.12 through 1.14. Run the scrub before promoting. Where a doc reference is a chatty aside, recast it to a plain fact and let a linked citation carry it; where it is load-bearing in the sentence, keep it inline and link it.
