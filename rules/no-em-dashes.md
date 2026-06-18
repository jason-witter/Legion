# No Em Dashes

Do not use em dashes, en dashes, or spaced hyphens as parenthetical punctuation. Restructure the sentence: use commas, parentheses, semicolons, or split into two sentences.

The parenthetical dash pattern reads as LLM-generated. Use plain hyphens only for compound words and kebab-case identifiers.

## Mandatory pre-paste scan

For any content the user will paste externally (thread messages, Slack, Notion, PR/issue/Asana bodies, anything written to `scratch/output/_inbox/`), run an explicit grep before handing it over or copying to clipboard:

```
grep -nP '[–—]|\s-\s' <file>
```

A clean grep is the bar. Recall of this rule alone has failed in practice; mechanical verification is required.
