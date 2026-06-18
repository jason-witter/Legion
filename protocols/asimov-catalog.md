# Asimov Catalog

Pattern catalog for the tone-scrub station. Asimov reads this file and applies each pattern to the diff and to `pr-description.md`. Patterns are organized by detection mode: mechanical first (high signal, low false-positive), taste-bounded second (where regex misses or fires too widely).

## Provenance

Created 2026-06-16. Manual updates only; no refresh cadence.

| Source | URL | SHA | License |
|--------|-----|-----|---------|
| stop-slop | https://github.com/hardikpandya/stop-slop | 8da1f030185bdfe8471220585162991eaeb970e9 | MIT |
| avoid-ai-writing | https://github.com/conorbronsdon/avoid-ai-writing | 0878950dd5165b7e7a85423fcd279c9ff3609549 | MIT |
| In-house | `scratch/output/_inbox/2026-06-16-tone-pass-exploration-response.md` | (local) | internal |

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

1. **Numbers, magic constants, file paths, error messages.** A function that returns `STALE_THRESHOLD_SECONDS = 900` keeps the constant name. Error message strings, log lines, and exception messages are load-bearing in observability; do not rephrase them.
2. **Pre-existing identifiers.** Only new identifiers introduced by the diff are eligible for rename. A function or constant that existed before this branch stays untouched, even if its name is verbose.
3. **Test names that describe the failure mode being caught.** `test_reset_inactive_no_ops_when_worker_id_changed` is exactly the form `rules/test-quality.md` rewards. Tone heuristics do not override the test-quality rule.
4. **Comments where each line carries information a reader needs.** Length is not the trigger; content is. A 12-line block that enumerates four exception paths, each with different observable consequences for operators, is informative and stays. A 12-line block that restates the same idea three different ways is decoration and gets trimmed. The judgment is content-based: read every line, ask whether removing it would lose information someone debugging the code would want. Asimov does not add annotations or markers to mark a comment as exempt; the catalog's tone heuristics either match a tell or they do not.
5. **Quoted strings, code samples, and content under quotation marks.** Asimov edits prose, not data. A comment that quotes an error code or a prior commit message keeps the quoted content verbatim.
6. **Commented-out code.** Whatever was commented out stays as it was.

When in doubt, leave it. Asimov's job is to remove the AI fingerprint, not to rewrite the codebase. A finding Asimov cannot resolve mechanically goes into `asimov_<N>.md` and surfaces to the user; it does not loop back through the mob.

## Severity Tiers

Every pattern in this catalog carries a tier. The tier determines how Asimov treats a match.

Tier 1, always-fire. Every match gets edited. No frequency threshold. These are unambiguous LLM tells that humans rarely produce naturally. If the regex hits and the match is not inside a hard exclusion, the fix applies.

Tier 2, cluster. Fires only at a frequency threshold defined per pattern. Single occurrences are tolerated because the underlying construction is legitimate in isolation; the tell is the volume. A lone "harness" reads fine; three of them in one paragraph reads like a model.

Tier 3, judgment-per-match. Each match is read and decided individually based on content, not frequency. Length or shape is the prompt to look; the verdict depends on whether the match carries real information. These are the patterns where a regex over-fires and a frequency count under-fires.

The PR description bar in section 5 is calibration on top of this model, not a fourth tier. It tightens cluster thresholds and broadens always-fire word lists for paste-ready output.

## 1. Prose patterns (mechanical, regex-detectable)

Each pattern has a regex shape and a fix. Asimov greps the diff for each, then applies the fix in context. False-positive rate is low; when in doubt, leave it.

### 1.1 Em-dashes, en-dashes, spaced hyphens (Tier 1)

**Regex:** `[–—]|\s-\s`

Already covered by `rules/no-em-dashes.md`. Asimov enforces it inside code comments and PR description as a baseline scrub. Restructure with commas, periods, or parentheses. (Source: `rules/no-em-dashes.md`.)

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

Genuine contrasts stay. "Use the primary, not the replica, for write-after-read consistency" weighs two real options a reader might pick between; the contrast carries information. The test: if a reader could plausibly have chosen Y, the contrast is genuine. If Y was never on the table, the contrast is decoration.

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

- `load-bearing`
- `stamp` as a verb (`stamp the row`, `stamps :now`)
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

**Fix.** Vary one bullet. If one bullet is longer because it carries more weight, let it be longer. If one item does not fit the parallel form because the underlying claim is shaped differently, let the shape diverge. The reader should be able to tell which bullet is the load-bearing one without bold or labels. (Source: in-house category 5; avoid-ai-writing "Rhythm and uniformity".)

### 4.3 Prose compound noun phrases used decoratively (Tier 3)

The prose form of the identifier tell in 2.2. Examples: "claim-to-first-ack race", "lifecycle write-site narrowing", "abandoned-PENDING hazard handling", "retry-time last-attempt-at stamp". Hyphenated multi-word noun phrases that pack three or four concepts into a single label.

Judgment-per-match. The phrase is often correct in content; the question is whether the prose needs the full stack. A reader who has the surrounding paragraph can usually follow "the race" or "the hazard" without the full compound. When the compound is the first reference and the paragraph has not established the concept, the full form earns its place; when the compound is the third reference in a comment that has already named the concept, it reads as ceremony.

**Fix.** On second and later references, replace the full compound with the shortest unambiguous label the surrounding context supports. On first reference, leave the compound if it actually disambiguates against other concepts in scope. (Source: in-house category 6.)

## 5. PR description bar

The PR description is paste-ready output, not an internal artifact. Asimov applies the catalog at a tighter threshold:

- Tier 2 frequency flags trigger at 2+ in the description, not 3+
- The full Tier 1 word list applies, not just the code-likely subset
- Compulsive rule of three, generic conclusions, and significance inflation all apply at full strength (these rarely show up inside code comments but are common in PR-description prose)
- "I hope this helps," "Let me know if," and other chatbot artifacts are P0; fix immediately

When in doubt on the PR description, lean toward cutting. The user copies this into GitHub as their own work; the bar is what a reviewer expects from a person.

## What this catalog does not cover

Asimov is not a stylometric detector. He does not measure type-token ratio, paragraph-reshuffle immunity, or sentence-length burstiness. Those signals exist in avoid-ai-writing's documentation and may inform a future iteration of this catalog, but the current pipeline operates on regex and reading. The patterns above were chosen because they earn their place at the threshold: high enough signal to fire reliably, low enough false-positive rate that the user does not have to override every finding.

The catalog is not closed. Patterns that surface in future reviews can be added here. The provenance table grows with each update.
