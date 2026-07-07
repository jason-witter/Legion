# No Em Dashes

Do not use em dashes, en dashes, or spaced hyphens as parenthetical punctuation. Restructure the sentence: use commas, parentheses, semicolons, or split into two sentences.

The parenthetical dash pattern reads as LLM-generated. Use plain hyphens only for compound words and kebab-case identifiers.

## Mandatory pre-paste scan

Writes and edits under `scratch/output/_inbox/` are gated mechanically: `hooks/block-inbox-em-dashes.sh` rejects the tool call when the content carries a dash pattern, so inbox files cannot acquire one in the first place.

For paste-ready content that lives anywhere else (thread messages composed inline, feature-directory paste artifacts, PR/issue/Asana bodies), run the explicit grep before handing it over or copying to clipboard:

```
grep -nP '[–—]|\s-\s' <file>
```

A clean grep is the bar. Recall of this rule alone has failed in practice; mechanical verification is required.
