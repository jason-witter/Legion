# Asimov Catalog

Pattern catalog for the tone-scrub station. Asimov reads this file and applies each pattern to the diff and to `pr-description.md`. Patterns are organized by detection mode: mechanical first (high signal, low false-positive), taste-bounded second (where regex misses or fires too widely).

## Provenance

Created 2026-06-16. Manual updates only; no refresh cadence.

| Source | URL | SHA | License |
|--------|-----|-----|---------|
| stop-slop | https://github.com/hardikpandya/stop-slop | 8da1f030185bdfe8471220585162991eaeb970e9 | MIT |
| avoid-ai-writing | https://github.com/conorbronsdon/avoid-ai-writing | 0878950dd5165b7e7a85423fcd279c9ff3609549 | MIT |
| In-house | `scratch/output/_inbox/2026-06-16-tone-pass-exploration-response.md` | (local) | internal |
| Corpus pass | `scripts/local/prose-heatmap.py`, 1,351 artifacts / 1.7M words, 2026-08-28 | (local) | internal |
| General-usage lookup | https://mareksuppa.com/til/load-bearing/ | (n/a) | reference |

Both external sources are MIT-licensed. Attribution preserved per their LICENSE terms; the categories below mark which entries were adapted from which source.

## How Asimov uses this file

Asimov runs after Curie. His input is the worktree diff plus `pr-description.md`. He applies the catalog in this order:

1. Hard exclusions (next section). Anything inside an exclusion is not eligible for edit, regardless of pattern match.
2. Prose patterns. Regex-detectable, mechanical. Edit on sight.
3. Identifier patterns. Taste-bounded. New identifiers from the diff only.
4. Prose vocabulary. Frequency flags. Flag at the thresholds named per category.
5. Comment-structure patterns. Taste-bounded. Read the comment, decide if it earns the lines it takes.

Asimov edits in place. The version of each file after Asimov returns is the version that ships.

## Hard Exclusions

Patterns in this list are out of scope. Asimov does not touch them even if a catalog rule would otherwise match.

1. **Numbers, magic constants, file paths, error messages.** A function that returns `STALE_THRESHOLD_SECONDS = 900` keeps the constant name. Error message strings, log lines, and exception messages are matched by operators; do not rephrase them.
2. **Pre-existing identifiers.** Only new identifiers introduced by the diff are eligible for rename. A function or constant that existed before this branch stays untouched, even if its name is verbose.
3. **Test names that describe the failure mode being caught.** `test_reset_inactive_no_ops_when_worker_id_changed` is exactly the form `protocols/test-quality.md` rewards. Tone heuristics do not override the test-quality protocol.
4. **Comments where each line carries information a reader needs.** Length is not the trigger; content is. A 12-line block that enumerates four exception paths, each with different observable consequences for operators, is informative and stays. A 12-line block that restates the same idea three different ways is decoration and gets trimmed. The judgment is content-based: read every line, ask whether removing it would lose information someone debugging the code would want. Asimov does not add annotations or markers to mark a comment as exempt; the catalog's tone heuristics either match a tell or they do not.
5. **Quoted strings, code samples, and content under quotation marks.** Asimov edits prose, not data. A comment that quotes an error code or a prior commit message keeps the quoted content verbatim.
6. **Commented-out code.** Whatever was commented out stays as it was.

When in doubt, leave it. Asimov's job is to remove the AI fingerprint, not to rewrite the codebase. A finding Asimov cannot resolve mechanically goes into `asimov_<N>.md` and surfaces to the user; it does not loop back through the mob.

## Severity Tiers

Every pattern in this catalog carries a tier. The tier determines how Asimov treats a match.

Tier 1, always-fire. Every match gets edited. No frequency threshold. These are unambiguous LLM tells that humans rarely produce naturally. If the regex hits and the match is not inside a hard exclusion, the fix applies.

Tier 2, cluster. Fires only at a frequency threshold defined per pattern. Single occurrences are tolerated because the underlying construction is legitimate in isolation; the tell is the volume. A lone "harness" reads fine; three of them in one paragraph reads like a model.

Tier 3, judgment-per-match. Each match is read and decided individually based on content, not frequency. Length or shape is the prompt to look; the verdict depends on whether the match carries real information. These are the patterns where a regex over-fires and a frequency count under-fires.

Tier 1 and Tier 3 are two layers of the same coverage, not only two strictnesses. A move-based Tier 3 entry catches a novel instance at the cost of a judgment call; a word-pinned Tier 1 entry catches a known offender for free. Words earn promotion from the first layer to the second by recurring, which is why the pinned entries carry a user-feedback date in their provenance. A synonym of a pinned word is not itself pinned, and is decided by the move-based entry behind it.

The PR description bar in section 5 is calibration on top of this model, not a fourth tier. It tightens cluster thresholds, broadens always-fire word lists, and promotes named Tier 3 patterns to always-fix for paste-ready output.

## 1. Prose patterns (mechanical, regex-detectable)

Each pattern has a regex shape and a fix. Asimov greps the diff for each, then applies the fix in context. False-positive rate is low; when in doubt, leave it.

### 1.1 Em-dashes, en-dashes, spaced hyphens (Tier 1)

**Regex:** `[–—]|\s-\s`

Em and en dashes used as parenthetical punctuation. Restructure with commas, periods, or parentheses. Asimov is the only enforcement now that the write-time gate is retired, so this pattern is checked on every pass rather than assumed clean. A spaced hyphen is not a violation. (Source: `rules/no-em-dashes.md`.)

### 1.2 Bolded prefix labels in prose (Tier 1)

**Regex:** `\*\*[A-Z][a-zA-Z]+:\*\*`

`**Why:**`, `**How to apply:**`, `**Verdict:**`, `**Blockers**` and the family. Legitimate inside framework files (rules, agent definitions, protocols), exempt there. In code comments and externally-visible content, strip the bold and either restructure the sentence so the label is the subject, or drop the label and write the point directly. (Source: in-house category 5.)

### 1.3 "Per `path/to/rule.md`" citations (Tier 1)

**Regex:** `[Pp]er \`[^\`]+\.md\``

Internal-vocabulary leak. Inside framework files it is the canonical citation form; in code comments and PR descriptions it reads as an agent left its fingerprint. Either restate the rule's content inline or drop the citation entirely. (Source: in-house, tone-pass response.)

### 1.4 Decorative "X, not Y" contrast (Tier 1)

**Regex shapes (mechanical form):** `not [A-Za-z ]+,?\s+(it'?s|but)\s+[A-Za-z]`, `isn'?t (the )?[A-Za-z]+,? (it'?s|but)\s`

Two forms of the same tell, both always-fire when decorative:

1. The mechanical form: "It's not X, it's Y" or "Not X, but Y". Direct negation-then-positive structure caught by the regex above.
2. The diffuse rhetorical form: a sentence-opener that pairs a real claim against an alternative the writer is not actually considering. Examples: "Design docs are decisional, not deliberative." "The change becomes a refinement of the already-stamped row rather than the only proof-of-life write." The shape is "X, not Y" or "X rather than Y" where Y is set up only to be dismissed.

The criterion is whether the contrast is decorative. Decorative means the alternative is not being seriously weighed as a real option; it exists to make X sound considered. Decorative contrasts always go. Rewrite as a direct positive: state X.

Genuine contrasts stay. "Use the primary, not the replica, for write-after-read consistency" weighs two real options a reader might pick between; the contrast carries information. The test: if a reader could plausibly have chosen Y, the contrast is genuine. If Y was never on the table, the contrast is decoration. At the PR-description bar the diffuse form is always-fix regardless of this test; see section 5.

(Source: stop-slop `references/structures.md`, "Binary Contrasts"; avoid-ai-writing, sentence-structure rules; in-house category 4.)

### 1.5 List-label periods, bolded labels ending in `.` (Tier 1)

**Regex:** `^\s*[-*]\s*\*\*[A-Z][^*]+\.\*\*\s`

`- **Intros.** Years of conferences and operator network.` Human writers use a colon: `- **Intros:** years of conferences and operator network.` Replace the period with a colon and lowercase the gloss, or drop the bolded label and write the bullet as a plain sentence. (Source: avoid-ai-writing, "List-label periods"; in-house category 5.)

### 1.6 Throat-clearing openers (Tier 1)

**Regex shapes:** `\bHere'?s (the thing|what|why|the problem|the real|the truth)\b`, `\b(It turns out|The (uncomfortable )?truth is|Let me be clear|I'?ll say it again|Make no mistake)\b`

State the point. Cut the announcement. (Source: stop-slop `references/phrases.md`, "Throat-Clearing Openers".)

### 1.7 Emphasis crutches (Tier 1)

**Regex shapes:** `\b(Full stop|Period|Let that sink in|Make no mistake|This matters because)\b\.?`

Delete. They carry no information. (Source: stop-slop, "Emphasis Crutches".)

### 1.8 Chatbot artifacts (Tier 1)

**Regex shapes:** `\b(I hope this helps|Certainly|Absolutely|Great question|Feel free to reach out|Let me know if you need anything)\b`

Remove entirely. These are chat-interface tics, not writing. They show up most often when a code comment or PR description was assembled from an exchange. (Source: avoid-ai-writing, "Chatbot artifacts".)

### 1.9 "Let's" transitions (Tier 1)

**Regex:** `\b[Ll]et'?s (explore|take a look|break this down|examine|dive in|consider)\b`

Cut and state the point. "Let's dive in" is the strongest signal; the broader pattern is any "let's + verb" that functions as a transition instead of a real invitation. (Source: avoid-ai-writing, "'Let's' constructions".)

### 1.10 Bolded labels inside list items repeating the label content (Tier 1)

**Regex shape:** `\*\*([A-Z][a-zA-Z]+):\*\*\s+\1`

`**Performance:** Performance improved by...` repeats the same word in the bold and the gloss. Strip the label and write the point. (Source: avoid-ai-writing, "Inline-header lists".)

### 1.11 Colon-gloss and semicolon-splice cadence (Tier 3; always-fix at the PR bar)

Two rhythm tells, both mid-sentence in running prose:

1. **Colon-gloss.** A colon mid-sentence appending an explanatory clause where a
   human writes a second sentence or uses a comma. "category 14 is
   DEFERRED_ITEM: credits spent on a third-party good." "The good news on needing
   to see when they start: we will, automatically." The colon sets up a punchy
   appositive; the construction reads as composed for cadence.
2. **Semicolon-splice.** A semicolon joining two independent clauses that each stand
   as a complete sentence, used for rhythm rather than to separate items in a complex
   list. "I'd park it; it doesn't need handling in this pass." A human writes two
   sentences or a comma-plus-conjunction.

**Regex shapes (the prompt to look, not the verdict):**
- Colon-gloss: `[a-z][a-zA-Z0-9_]*:\s+[a-z]` — a lowercase-led token, a colon, whitespace,
  then a lowercase word. The lowercase lead-in distinguishes a mid-sentence gloss from a
  capitalized label ("Sources:", "Note:") and a sentence-start.
- Semicolon-splice: `[a-z][^;.!?]*;\s+(I\b|[a-z])` — clause text, a semicolon, whitespace,
  then a lowercase word or the first-person "I" starting the next clause. ("I" is included
  because a splice whose second clause opens with "I" is the common first-person case; other
  capitalized leads are excluded to avoid firing on proper nouns.)

These regexes are wide. They locate candidates; the verdict is read per match against
the carve-outs below.

**Fix.** Colon-gloss: split into two sentences, or join with a comma if the gloss is
short and dependent. Semicolon-splice: split into two sentences, or replace the
semicolon with a comma and a conjunction.

**False-positive carve-outs (do not fire):**
- **Ratios and clock times.** `3:1`, `14:30`, `2:1 split`. Digits on both sides of the
  colon. The colon-gloss regex requires a lowercase letter after the colon, which already
  excludes pure-digit cases, but a "14:30 we" near-miss is data, not prose.
- **Code, identifiers, and dict/kwarg literals.** `stale_ok=True`, `{"key": value}`,
  `key: value` config pairs, type annotations (`x: int`), YAML/JSON fragments. Covered by
  Hard Exclusion 5 (quoted strings, code samples) and Exclusion 1 (identifiers), but the
  carve-out is restated here because the regex would otherwise see `key: value` as a colon-gloss.
- **List-item labels.** `- **Sources:** ...`, `- **Note:** ...`, and the bolded-label
  family are owned by patterns 1.2 and 1.5. The colon-gloss regex requires a lowercase
  lead-in, so a `**Bolded:**` label does not match; an unbolded `- sources: ...` list label
  at line start is still a label, not prose cadence, and does not fire.
- **Metadata labels at line start.** A line that is a `Label: value` metadata pair
  ("Repro: ...", "Branch: ...", "sources: ...") is structure, not a prose sentence. If the
  colon-introduced clause is the whole line and the lead-in is a single label token, leave it.
- **Colon introducing a genuine list or block.** "Three cases: A, B, and C" or a colon
  before a code block or a quote introduces structure, not a rhythmic gloss. The tell is a
  single appositive clause, not an enumerated list.

The verb-noun test for the carve-out vs. the tell: if the colon introduces a list, a quote,
a block, or a `Label: value` metadata pair, leave it. If it appends a single explanatory
clause to a complete sentence for punch, fix it.

(Source: in-house; AI rhythm fingerprint surfaced in standalone scrub, 2026-06-30.)

### 1.12 Requester-directed second person (Tier 3; always-fix at the PR bar)

**Regex:** `\b([Yy]ou|[Yy]our|[Yy]ours|[Yy]ou'?re|[Yy]ou'?ve|[Yy]ou'?ll)\b`

Second person that addresses the original requester as if mid-conversation: "Your instinct was right", "as you suspected", "you asked about X", "beyond your Y". This is a session-conversational leak. The content was drafted as an answer to one person and then promoted to a shared artifact (a Notion page, a doc, a ticket), where the reader is no longer that person and the address reads as a stray fragment of a chat.

Recast to impersonal or third person: "Recognition depends on both..." not "Your instinct was right. Recognition depends on both..."; "the credit-redemption schedule" not "your credit-redemption schedule".

Judgment-per-match. Genuine second person aimed at a generic future reader in a how-to or runbook ("run `make test` to check your changes") is legitimate and stays. The tell is address to the *requester* or to the *conversation*, not to a generic reader. At the PR / paste-ready bar, lean impersonal even for generic-reader second person unless the artifact is explicitly instructional.

(Source: in-house; requester-directed second person leaked through a standalone scrub into a published Notion doc, 2026-07-10.)

### 1.13 Narratorial status asides and shared-context references (Tier 3; always-fix at the PR bar)

Sibling to 1.12: both are session context leaking into a promoted artifact. Here the leak is asides that narrate the state of the work, or that lean on the author's just-finished investigation as shared context. Three forms:

1. Status-commentary register: "this is being addressed by X", "this is exactly the dependency the engineering plan lists as 'in flight'", "worth flagging, not resolving", "as noted above". The register is a narrator briefing the requester, not a doc describing a system.
2. Shared-context references to internal work dropped inline: bare PR numbers as asides ("(PR #NNNNN)"), "the engineering plan", "the forward plan", decision name-drops ("(per a named teammate)"). They assume the reader was in the room.
3. Undefined internal codenames and phase labels imported from a source doc: project phase names ("Crawl", "Walk", "Run"), initiative codenames, and in-house jargon carried into a ticket, PR, or issue where the reader has no definition. They are meaningful in the doc that defines them and noise everywhere else. This mirrors the reference-doc rule on introducing codenames only where defined (`rules/reference-doc-authoring.md`).

Do not over-fire. Implementation status is legitimate and often essential in an architecture doc. "The ledger export source is not yet built; targeted for Q3" stays. The tell is the chatty register and the assumed shared context, not the status fact itself.

Fix. State the status as a plain, self-contained fact ("This enrichment is not yet wired into the grant path", not "This is exactly the dependency the engineering plan lists as 'in flight'"). Move PR numbers and internal-doc references out of mid-prose asides into a citations or source appendix. Replace an undefined codename with the plain thing it names ("the current report", not "the Crawl report"); keep a phase index only where it carries a real description the reader can act on.

(Source: in-house; status asides and shared-context references read as session notes in a promoted Notion doc, 2026-07-10. Undefined phase codenames carried from an alignment doc into paste-ready tickets, 2026-07-13.)

### 1.14 Significance inflation and importance-editorializing (Tier 3; always-fix at the PR bar)

Prose or headers that announce how important or pivotal something is instead of stating the thing. Weight should come from the content, not from a label asserting the weight. Section 5 lists significance inflation as always-fix at the PR bar; this is its definition.

Sentence forms: "this is the key to everything", "the whole system turns on X", "the pairing matters", "that is precisely why Y", "this is the heart of it". Header forms: editorial parentheticals like "(this is the key to everything)" or "(where the org is headed)".

Fix. Cut the importance-claim and state the fact directly. "The whole system turns on two axes, X and Y" becomes "Two fields on every row drive this, X and Y". "That is precisely why Y." is deleted, or Y is stated plainly. For headers, drop the parenthetical and keep the plain topic.

Do not over-fire. An importance claim that names a real reason a reader needs in order to prioritize carries information and the claim stays. The word `load-bearing` is separately pinned in 3.7 and gets substituted rather than deleted, so the claim survives the swap intact. The tell is the bare importance-assertion with no added content.

(Source: in-house; surfaced comparing an authored doc against the user's own edits, 2026-07-10.)

### 1.15 Coined terms of art (Tier 3; always-fix at the PR bar)

A word or hyphenated compound used as though it names an established concept, when the reader has no way to reach the referent. They take it for domain vocabulary, do not stop to look it up, and supply a meaning of their own. Examples: `refund-first`, `charge-first`, `feature-exercising`. The construction is fluent and confident, which is why it survives review.

Distinct from 2.2 and 4.3, which own compounds correct in content and merely overlong on a later reference. The failure here is not length. A two-word coinage fails it and a four-word domain term passes.

**Destination governs, and is settled before the checks run.** Framework files (`rules/`, `protocols/`, agent definitions) may carry house vocabulary; a term defined in one framework file and used across others is doing its job. Everything engineer-facing or user-facing is held to the reader in front of it: a PR description, a commit body, a ticket, a code comment, or a report the user reads. A term is not cleared by a definition the reader will never open.

**Regex shapes (the prompt to look, not the verdict):**
- `\b[a-z]+-(first|driven|aware|native|centric|led|oriented|shaped)\b` — templates that manufacture an opaque posture name from any noun. Transparent compositional forms (`-facing`, `-based`, `-only`, `-safe`) are excluded; they read on sight and generate volume without signal.
- Any hyphenated compound modifier the diff introduces, carrying a definite article on first appearance (`the X-Y path`, `the X-Y model`, `the X-Y ordering`).

**Test, three checks in order:**

1. **Used as established?** The term appears with no gloss, usually behind a definite article, as though the reader already holds it. A term the sentence explains as it goes is not this pattern.
2. **Does it resolve, and against what?** Three references, in widening order: the artifact's own source material (the ticket, the spec, the domain), the repo, and general technical usage. Resolution requires that the usages found name one consistent referent; a term appearing under two different meanings has failed, which is what `arm` did (3.6, traced 2026-08-12), and presence on the default branch is not ratification. Resolving *only* against the repo makes it a house coinage: legitimate in framework files, firing on anything leaving. A term carrying its own word-pinned entry in section 3 is decided by that entry and this check does not clear it.
3. **Defined where the reader is?** A coinage this artifact defines once, in plain words, before leaning on it is resolvable and stays. A definition living in another file does not travel with the artifact and does not count.

The search in check 2 is a read for resolvability. It does not expand the edit surface, which stays as the agent definition sets it. Where there is no repo to search, run the check against the source material named in the dispatch and against established usage, and treat a term that neither resolves nor carries a local definition as coined.

**Fix.** Replace the term with the thing it describes, or define it once on first use. Prefer replacement: a PR description or a ticket rarely runs long enough to earn a defined term. `refund-first` becomes the ordering it names (`refunds applied before the charge`). Do not substitute another generic for the generic, which is 3.6's named failure mode; the test on the replacement is whether a reader who does not already know would reach the right referent.

**False-positive carve-outs (do not fire):**
- **Established industry compounds.** `mobile-first`, `offline-first`, `copy-on-write`, `write-ahead`, `read-through`, `event-driven`. They resolve at check 2's third reference.
- **Domain vocabulary from the source material.** A term the ticket, the spec, or the accounting domain already uses belongs to the source material, not to the writer. A partner agreement has `tiers`. `leg` is not an example of this: it resolves against the accounting domain and against the repo, and it fires under 3.6 anyway, which asks for the full identifier.
- **Ordinary hyphenated adjectives that describe rather than name.** `read-only replica`, `two-column layout`, `per-invoice total`. The tell is a term standing in for a concept, not the hyphen.
- Hard Exclusions 1, 2, and 5 apply unchanged.

**Relationship to the word-pinned entries.** 3.6 is this pattern's promoted instance. `arm` recurred often enough to earn a Tier 1 pin, which is what makes it free to catch with no judgment spent. 1.15 catches a novel coinage on its first appearance at judgment cost; one that keeps recurring gets promoted into section 3 as its own always-fire entry. Do not read section 3 as a word list to extend by synonym, and do not fire 1.15 on a word merely because it resembles one pinned there.

(Source: in-house; `refund-first` and `charge-first` coined in paste-ready PR prose with no referent in the repo or the ticket, 2026-08-28. Destination scoping and the general-usage reference added the same day after a 1,351-artifact corpus pass found `feature-exercising` at 93 documents, resolving internally and nowhere else, and reaching the user undefined in a validation summary. Generalizes the unresolvable-referent half of 3.6.)

### 1.16 Author-directed review prose (Tier 3, determinate)

Prose in a review finding that makes the change's author the subject of the sentence instead of the code. `rules/review-comment-register.md` is the authority; this entry is what the pass fires on.

**Sibling to 1.12, not a replacement.** 1.12 fires on a leaked addressee: the requester is addressed in an artifact they no longer read, so the second person is a stray fragment of a chat. 1.16 fires even when the addressee is the finding's genuine reader, because direct address in a review comment carries a tone cost regardless of who reads it. Both can fire on one sentence, and 1.12 is unchanged; do not clear a 1.16 match on the grounds that 1.12's addressee test passed, which is the exact reasoning that let this through.

**Regex shapes (the prompt to look, not the verdict):**
- `\b([Yy]ou|[Yy]our|[Yy]ou'?re|[Yy]ou'?ve|[Yy]ou'?d|[Yy]ou'?ll)\b` — the same class as 1.12.
- `\bthe (author|implementer|submitter|committer)\b` — the author as a named third-person subject.
- `\b(was|were)\s+(done|chosen|written|implemented|handled)\b` — the agentless passive that puts a human in the dock without naming one, when a judgment rides on it ("this was done incorrectly").

**Test.** Read the finding and ask what the sentence is about, not whether it contains a match. A sentence can review the person with no match at all, and a match can be innocent. If the subject is the author, a decision the author made, or the author's own description, rewrite until the code, the file, or the change is the thing being described. Unlike the other Tier 3 entries, the judgment here is which noun the sentence is about, and it has one answer; there is no latitude to read a fired match and leave it.

**Fix.** The rule's table carries the full set; these three are the calibration:

| Fires | Fixed |
|---|---|
| You already hit this once | `test_adjustment_calculation.py` is the live example |
| The author chose to duplicate the enum | The enum is defined twice |
| This was done incorrectly | The ordering is inverted here |

The finding is identical across each pair. What changes is whether the reader absorbs an accusation before evaluating it.

**First person for the reviewer is not a tell.** "I do not see a cycle in the way" and "my read is that this can wait" mark the claim as the reviewer's judgment rather than a fact. Leave them: the rule permits them, and stripping them flattens calibrated certainty into false confidence. The same holds for the first-person sign-off the user posts under their own name (`protocols/pr-review.md`).

**False-positive carve-outs (do not fire):**
- **Questions about the code.** A question is legitimately addressed to a person and there is no way to ask one without them. The pattern fires only when the question asks the author to account for a decision: "Is this shape already changing in #1290?" stays, "Did you plan to change this in #1290?" is fixed.
- **Generic-reader instruction.** The carve-out 1.12 already carries: a runbook step or a repro instruction aimed at any future reader.
- **Report metadata.** The `(@user)` attributions in a report's Already Resolved and Existing Review Context sections record who said what. They are structure, not a finding's prose.
- Hard Exclusion 5 applies unchanged. A finding quoting a prior review comment keeps the quote verbatim.

**Destination.** Findings written for someone else to read: external PR review comment candidates, mob code review, design critique, and any review prose staged for the user to paste. Not the PR description or commit body, where the author is the user and no reviewed party exists; stray second person there is 1.12's.

**The fix is not vagueness.** Passive voice reached for to avoid naming a subject ("it was decided that") is worse than either version, because the finding stops being locatable. Name the file, the line, and the construct. Severity is untouched: a Blocking finding stays Blocking and keeps its ask, per `protocols/finding-disposition.md`.

(Source: in-house; a review comment written as credit to the author, "You already hit this once", was read as an accusation that they had nearly shipped the bug. The pass had considered the second person and cleared it under 1.12, correctly finding that the addressee was the comment's genuine reader. Genuine address was never the question, and no pattern covered the tone cost of direct address in a review comment, 2026-09-10.)

## 2. Identifier patterns (taste-bounded)

Asimov reviews **new** identifiers introduced by the diff. Pre-existing identifiers are out of scope per Hard Exclusions.

### 2.1 Over-announcement (Tier 3)

Function and constant names that pre-explain every reachable invariant. Examples: `_mark_delivery_failed_after_max_retries`, `_reset_to_pending_if_owned`, `_count_pending_deliveries_for_endpoint`, `FAILURE_REASON_MAX_RETRIES_EXCEEDED`. A human writer would settle for `_mark_failed`, `_reset_pending`, `_count_pending`, `FAILURE_MAX_RETRIES`.

Judgment-per-match. Read each candidate; verbose names sometimes carry real contract information that a shorter form loses.

**Heuristic.** Five or more underscores in a function or constant name is a flag, not a rule. Read the name in context. If the same identifier appears once at definition and once at the call site, the verbose name is doing real work; rename anyway if the shorter form is unambiguous. If the identifier appears across many call sites, the verbose name compounds the noise; rename is high-value.

**False-positive carve-out.** Domain identifiers that pre-exist in the codebase under the verbose form (database column names, gateway-supplied enum values, third-party API field names) are not eligible for rename. They are pre-existing identifiers per Hard Exclusion 2.

**Fix.** Propose a shorter rename. If no shorter form preserves meaning, leave the identifier and record the finding in `asimov_<N>.md` as a non-mechanical case. (Source: in-house category 1.)

### 2.2 Compound noun phrases used decoratively in identifiers (Tier 3)

Same impulse as 2.1, expressed in the noun-phrase shape: `claim_to_first_ack_race`, `retry_time_last_attempt_at_stamp`, `abandoned_pending_hazard_handling`. The phrase is correct; the question is whether the identifier needs to encode every member of the phrase.

Judgment-per-match. Apply the same fix and the same false-positive carve-out as 2.1. (Source: in-house category 6.)

## 3. Prose vocabulary (frequency flags)

Asimov flags these words and phrases as a frequency check. A single use is rarely the tell; clustering is. Each entry names the threshold.

### 3.1 In-house cluster (Tier 2)

These show up disproportionately in agent-generated prose. Cluster threshold: 3+ across the diff or 2+ in the PR description.

- `surface` as a verb (`surface the finding`, `surface to the user`)
- `encode` (when meaning "express" rather than "serialize")
- `invariant` (outside actual math contexts)
- `narrow` as a verb modifier (`narrow the scope`, `narrow UPDATE`)
- `ground truth`
- `adversarial`
- `gate` as a verb (`gate the action`, `gated push`)

**Fix.** Pick one occurrence to keep if it carries real meaning; rewrite the rest. A diff that uses `stamp` four times in one comment block: one occurrence anchors the metaphor, the rest are decoration. (Source: in-house category 3.)

### 3.2 Stop-slop Tier 1 vocabulary (Tier 1)

Adapted from avoid-ai-writing's Tier 1 vocabulary table (which itself draws from `brandonwise/humanizer`). Replace on sight when found in code comments or PR descriptions. Full list is long; these are the ones most likely to leak through into a code-context paste:

- `delve / delve into` to look at, dig into
- `leverage` (verb) to use
- `robust` to strong, reliable
- `comprehensive` to thorough, complete
- `seamless / seamlessly` to smooth, without friction
- `cutting-edge` to latest
- `meticulous` to careful, detailed
- `utilize` to use
- `actionable` to practical, useful
- `holistic` to complete, whole

(Source: avoid-ai-writing Tier 1, MIT.)

### 3.3 Stop-slop Tier 2 vocabulary (Tier 2)

Cluster threshold: 2+ in the same paragraph or same comment block.

- `harness` to use
- `navigate / navigating` to handle, work through
- `foster` to encourage, support
- `streamline` to simplify
- `facilitate` to enable, help
- `crucial` to important, key
- `nuanced` to specific, subtle (or name the actual nuance)

(Source: avoid-ai-writing Tier 2, MIT.)

### 3.4 Hollow intensifiers (Tier 1)

Single-use cut. These add no information.

- `genuine / genuinely`
- `truly`
- `really`
- `simply`
- `actually`
- `literally`
- `fundamentally`
- `inherently`
- `essentially`

(Source: stop-slop "Adverbs" and avoid-ai-writing "Hollow intensifiers".)

### 3.5 `stamp` as a verb (Tier 1)

Always-fire, no cluster threshold. `stamp the row`, `stamps :now`, `stamps the label on`. Rewrite with the plain verb the context wants: `set`, `write`, `record`, `mark`, `apply`. The noun forms (`timestamp`, a literal time-stamp column) are fine; only the verb use fires. The entry is word-pinned deliberately and does not generalize. The move behind it, a metaphor-verb standing in for a plain one, also covers `spin up`, `drop`, `wire`, `plumb`, and `bubble up`, and firing on the move would fire on ordinary technical English. A synonym of `stamp` is not covered here and does not become covered by resemblance. (Source: in-house; promoted from the 3.1 cluster to always-fire on user feedback, 2026-06-30.)

### 3.6 `arm` and `leg` for a named system, provider, or code path (Tier 1)

Always-fire, no cluster threshold. `the Apple arm`, `the web arm`, `both arms`, `three pricing arms`, and the
same constructions on `leg`. The word sounds like it names something and names nothing, so it survives review
while the reader supplies a different referent than the writer meant. Replace with the thing itself.

`leg` was added 2026-09-04 on user ruling. The two behave identically and appear together; the user's report is
that the pair is pervasive in recent Claude-family output, which is the same evidence that promoted 3.5 and 3.7.
Treat a `leg` instance exactly as an `arm` instance, including the substitution guidance below.

Two distinct substitutions, and picking the wrong one keeps the ambiguity:

- **A payment provider is a PSP or a payment gateway.** Apple, Google, Stripe and Adyen are payment service
  providers. `the Apple arm` becomes `Apple`, `the Apple gateway`, or `Apple pricing`, depending on whether the
  sentence is about the provider, the gateway constant, or the code that handles it.
- **A branch of a query or a pipeline is named for what it does.** `the aggregate arm` becomes `the aggregate
  pool`; `the per-invoice arm` becomes `the per-invoice path`; `four different things by arm` becomes `four
  different things depending on which path produced the row`.
- **A separate file, query, or script is named directly.** `the promotion arm` becomes `the promotion query`, or the
  filename where precision matters. Do not reach for `path` here: the referent is a whole artifact rather than
  a branch inside one, and `path` swaps one vague word for another, leaving the reader with a third term for
  the same thing. Substituting a generic for a generic is the failure mode to avoid; the test is whether the
  replacement would let a reader open the right file.

- **A real identifier in the codebase is named in full.** Where the referent is a model, field, or type that
  exists, write the identifier: `InvoicePaymentLeg`, or `payment_legs` for the collection. A live identifier
  makes the bare noun worse than it is elsewhere, not better, because the reader cannot tell whether `the
  wallet leg` means an `InvoicePaymentLeg` row or a gesture at part of the charge flow. Do not read the
  identifier's existence as a clearance for loose use; that inversion is what this bullet blocks. Pattern
  1.15's domain-vocabulary carve-out does not reach it either, per 1.15 check 2: a word pinned in section 3
  is decided by its own entry. (User ruling 2026-09-04, on a PR review draft that used a bare `leg` about
  thirty times on the strength of the model existing.)

Watch for the conflation specifically. Writing `the two arms disagree` when one clause means the providers and
the other means the query paths reads as one claim and is two. That is the failure this pattern exists to
catch, not the word's ugliness.

Note `arm` is established in-house terminology in some existing engineering plans for the report's three
pricing paths. Inside those documents it is consistent and understood; the pattern fires on new prose and on
anything leaving the team. (Source: in-house, user feedback 2026-07-31.)

It is also in checked-in code. Traced 2026-08-12: the word enters the material-rights scripts in a teammate's
original commit meaning one pricing branch, and a later decomposition generalises it to name two separate
query files. So a usage consistent with its own file is not evidence the term was ever ratified, and neither
is its presence on the default branch. Two consequences. Do not clear a fired instance on the grounds that
the surrounding code uses it, which is inheriting a correctness nobody derived. And do not open a rename of
working code to satisfy the pattern: fix the prose that is leaving, and leave the code's own vocabulary to
whoever owns the next change to it. (Source: provenance traced in the repo, user challenge 2026-08-12.)

**That restraint covers code the change does not own, and nothing else.** Identifiers the current change is
authoring are in scope and get the plain name from the start: a local named `in_arm_gateways` beside a constant
named `LEDGER_PRICED_GATEWAYS` is the pattern firing on new code, not inherited vocabulary. Observed 2026-09-04,
when a feature branch shipped `in_arm_gateways` locals in two files plus eight test names built on `arm`, and
the 2026-08-12 line above was the reason none of it was challenged while it was being written. Renaming it cost
one pass; the reviewers who hit it first read it as jargon. The distinction is authorship, not file age.

Pattern 1.15 is the general case behind this entry, covering a coined term that has not yet earned a pin of its own. `arm` keeps its own entry because a pinned word costs no judgment; 1.15 neither supersedes it nor clears an instance it fires on.

### 3.7 `load-bearing` (Tier 1)

Always-fire, no cluster threshold. Not a coinage; the software metaphor is older than the model era and it resolves fine. It is worn through. A corpus pass over 1,351 Legion artifacts found it in 337 of them across 531 uses, 1.7x the next-ranked compound and present in a quarter of everything the framework has written, and it is named outside this deployment as a marker of Claude-family prose.

It sat in the 3.1 cluster, where the threshold could not reach it: 531 uses across 337 documents averages 1.58 per document, against a threshold of 3+ in a diff or 2+ in a PR description. The modal document uses it once and never fired. Pervasiveness across documents is invisible to a within-document count, which is why the pin is the only form that works.

**Fix.** Substitute, do not delete. The claim being made is usually real; the word carrying it is the tell. Name what depends on the thing (`the retry count is what the dedup guard reads`), or use the plain adjective the sentence wants (`critical`, `required`, `the one that breaks if removed`). Pattern 1.14 still governs the surrounding shape: a bare importance-assertion with no added content goes entirely, and substitution does not rescue it.

(Source: in-house; promoted from the 3.1 cluster on corpus evidence and user ruling, 2026-08-28. Same promotion path as 3.5.)

## 4. Comment-structure patterns (taste-bounded)

Regex catches some structural tells; the rest require Asimov to read the comment and ask whether each line carries information.

### 4.1 Exhaustive enumeration (Tier 3)

Comment blocks that list every reachable case with bullet-shaped precision. Example:

```python
# Three exception sources to handle:
#   - DatabaseError on connection drop
#   - SerializationFailure on concurrent worker
#   - StaleRowException when the row vanished
#   - OperationalError for everything else
```

Each line is correct in isolation. In aggregate they signal a writer who cannot leave a case implicit. If the handler treats all four exceptions the same way, the comment can collapse to "Handle DB exceptions; let everything else propagate." If the cases diverge, the enumeration is doing real work, so keep it.

Judgment-per-match. Length is the prompt to look, not the verdict.

**Heuristic.** Comments longer than five lines that enumerate cases are candidates for inspection. Read each enumerated case; ask whether removing it loses information a reader needs. (Source: in-house category 2.)

### 4.2 Strict parallelism in bullets (Tier 2)

Every bullet in a sequence has the same grammatical shape, the same length, and the same opener style. Parallelism is a legitimate virtue; the tell is when every bullet matches, with no item carrying a different shape of information.

Cluster threshold: a bullet list of four or more items where every bullet matches the parallel form. Three matching bullets is normal prose; four or more with no shape variation is the cluster.

**Fix.** Vary one bullet. If one bullet is longer because it carries more weight, let it be longer. If one item does not fit the parallel form because the underlying claim is shaped differently, let the shape diverge. The reader should be able to tell which bullet carries the weight without bold or labels. (Source: in-house category 5; avoid-ai-writing "Rhythm and uniformity".)

### 4.3 Prose compound noun phrases used decoratively (Tier 3)

The prose form of the identifier tell in 2.2. Examples: "claim-to-first-ack race", "lifecycle write-site narrowing", "abandoned-PENDING hazard handling", "retry-time last-attempt-at stamp". Hyphenated multi-word noun phrases that pack three or four concepts into a single label.

Judgment-per-match. The phrase is often correct in content; the question is whether the prose needs the full stack. A reader who has the surrounding paragraph can usually follow "the race" or "the hazard" without the full compound. When the compound is the first reference and the paragraph has not established the concept, the full form earns its place; when the compound is the third reference in a comment that has already named the concept, it reads as ceremony.

**Fix.** On second and later references, replace the full compound with the shortest unambiguous label the surrounding context supports. On first reference, leave the compound if it actually disambiguates against other concepts in scope. (Source: in-house category 6.)

## 5. PR description bar

The PR description is paste-ready output, not an internal artifact. Asimov applies the catalog at a tighter threshold:

- Tier 2 frequency flags trigger at 2+ in the description, not 3+
- The full Tier 1 word list applies, not just the code-likely subset
- Compulsive rule of three, generic conclusions, and significance inflation (pattern 1.14) all apply at full strength (these rarely show up inside code comments but are common in PR-description prose)
- The diffuse "X, not Y" / "X rather than Y" sentence-opener (pattern 1.4 form 2) is always-fix here. The genuine-vs-decorative judgment that governs it in code comments does not survive at the paste-ready bar: recast to a positive declarative stating X. If a reader needs the alternative, state it in a following sentence; the opener does not carry the contrast. ("It's a hardcoded label, not a real SKU product line." -> "It's a hardcoded label." The "not a real SKU product line" gloss either drops or becomes its own sentence if it carries weight.)
- Colon-gloss and semicolon-splice cadence (pattern 1.11) is always-fix here. The judgment-per-match latitude in code comments does not apply; recast every colon-gloss and semicolon-splice in running prose, subject only to 1.11's data/code/label carve-outs.
- Requester-directed second person (pattern 1.12) is always-fix here. A standalone artifact bound for paste has no conversation partner; recast every "you"/"your" that addresses the requester to impersonal or third person, keeping only genuine generic-reader instruction.
- Narratorial status asides and shared-context references (pattern 1.13) is always-fix here. State statuses as plain, self-contained facts; relocate PR numbers and internal-doc references to a citations section.
- Coined terms of art (pattern 1.15) is always-fix here. A paste-ready artifact reaches a reader with no access to the framework, so a term resolving only against our own files is not resolved; replace it with the thing it describes rather than defining it, unless the artifact is long enough that a defined term earns its place.
- "I hope this helps," "Let me know if," and other chatbot artifacts are P0; fix immediately

When in doubt on the PR description, lean toward cutting. The user copies this into GitHub as their own work; the bar is what a reviewer expects from a person.

## What this catalog does not cover

Asimov is not a stylometric detector. He does not measure type-token ratio, paragraph-reshuffle immunity, or sentence-length burstiness. Those signals exist in avoid-ai-writing's documentation and may inform a future iteration of this catalog, but the current pipeline operates on regex and reading. The patterns above were chosen because they earn their place at the threshold: high enough signal to fire reliably, low enough false-positive rate that the user does not have to override every finding.

The catalog is not closed. Patterns that surface in future reviews can be added here. The provenance table grows with each update.
