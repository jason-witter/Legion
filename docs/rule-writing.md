# Writing Effective Rules

Reference for anyone writing rules or constraints for Claude-based agents. Rules live in `rules/` and are loaded as system-level context. They compete for attention with every other instruction in the context window. A rule that the model skips is worse than no rule — it's wasted tokens.

## Core Techniques

### 1. Positive Framing

State what the model should do, not what it should avoid.

Attention-based architectures must activate a concept's representation to process it — including when told to suppress it. "Don't include CLI commands" increases the salience of CLI commands. This is documented in the academic literature as the pink elephant effect and confirmed by Anthropic's own prompting guidance: "Tell Claude what to do instead of what not to do."

When negation is genuinely clearer (hard safety boundaries, single-word prohibitions), pair it immediately with the positive alternative.

```
# Weak
Do not include tool-specific commands, output formats, or procedural steps in dispatches.

# Strong
Dispatches contain intent, inputs, and scope. Agents derive all operational details from their own definitions.
```

### 2. Contrast Examples

Few-shot examples are the single most reliable technique for constraining output. Anthropic recommends 3-5 examples wrapped in `<example>` tags. For rules, a good/bad pair is usually sufficient — the contrast teaches the boundary.

Examples should be concrete instances from the framework's actual usage, not abstract illustrations.

```
# Weak — abstract description only
The dispatch should focus on outcomes rather than procedures.

# Strong — concrete contrast
Good:
  <intent>Fetch open PR review requests for acme/webapp</intent>

Bad:
  <intent>Run `gh pr list --search "review-requested:@me" --json number,title`</intent>

The bad example embeds a CLI command. The agent already knows how to fetch PRs.
```

### 3. XML Structural Boundaries

Claude treats XML tags as semantic containers, not formatting. A rule that defines a template with named XML fields creates a stronger constraint than prose describing the same shape.

Use XML templates when a rule defines a repeatable structure (dispatch shape, output format, review report). Use prose when the rule is a simple behavioral constraint (one command per bash call).

```
# Prose is fine here — simple constraint, no structure to enforce
One command per Bash tool call. No `&&`, `||`, or `;`.

# XML template is better here — enforces a three-field structure
<dispatch>
  <intent>The goal — stated as an outcome</intent>
  <inputs>File paths, identifiers, parameters</inputs>
  <scope>Boundaries on the work</scope>
</dispatch>
```

### 4. Brevity

Rules compete for attention with thousands of other context tokens. Every unnecessary word dilutes signal. Target the minimum token count that carries the full constraint.

- Lead with the rule, then explain if needed — not the reverse.
- One rule per file. One concern per rule.
- Cut rationale that doesn't change behavior. If the model would comply identically without a sentence, remove it.

### 5. Context as Motivation

When the reason behind a rule would change how the model applies it, include the reason. Anthropic's guidance: "Claude is smart enough to generalize from the explanation."

```
# Without context — model may treat as arbitrary formatting preference
One command per Bash tool call.

# With context — model understands the security implication and generalizes
One command per Bash tool call. Chained commands bypass permission pattern matching —
Bash(git push*) won't match `cd /repo && git push`.
```

## Rule Structure

A well-formed rule has:

1. **Title** — short, descriptive
2. **Lead statement** — the constraint in one or two sentences
3. **Examples** (when the constraint has a shape) — good/bad contrast pair using real framework scenarios
4. **Rationale** (when it changes behavior) — why this constraint exists, kept to one or two sentences

Keep the total under 30 lines where possible.

## Anti-Patterns

**Laundry lists of prohibitions.** Each "don't" activates the thing it prohibits. A rule with five "never do X" clauses is actively working against itself. Rewrite as a positive specification of what the output should contain.

**Abstract principles without examples.** "Keep dispatches focused on outcomes" is philosophy. A good/bad contrast pair is a constraint.

**Duplicated rules.** If two rules cover the same behavior, the model may weight them differently in different contexts, creating inconsistent compliance. One rule, one location.

**Rules that describe the system to itself.** "You are an AI assistant that should..." is wasted context. State the constraint directly.

## Sources

- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) — official guidance on positive framing, examples, and XML structure
- [Anthropic XML Tags Guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/use-xml-tags) — XML as semantic containers
- [Negation: A Pink Elephant in the Large Language Models' Room?](https://arxiv.org/abs/2503.22395) — academic analysis of negation processing in attention architectures
- [Suppressing Pink Elephants with Direct Principle Feedback](https://arxiv.org/abs/2402.07896) — techniques for handling suppression failures
- [The Pink Elephant Problem](https://eval.16x.engineer/blog/the-pink-elephant-negative-instructions-llms-effectiveness-analysis) — practical analysis with Claude and GPT-family models
