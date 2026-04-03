# Writing Effective Agent Definitions

Reference for anyone writing or reviewing agent definitions for Claude-based agents. Agent definitions live in `agents/` and are loaded as the system prompt when an agent is invoked. Everything in the definition competes for attention with the task context and tool outputs. A definition that the model ignores is wasted tokens — or worse, inconsistent behavior that cascades through multi-agent handoffs.

## Core Techniques

### 1. Positive Framing

Same principle as rules: state what the agent does, not what it avoids. Attention architectures must activate a concept to suppress it — "does not analyze what she fetches" increases the salience of analyzing. Define scope positively; exclusions become self-evident.

```
# Weak — activates the behaviors it prohibits
Grace does not analyze what she fetches. She does not write to external systems.
She does not post-process output with shell utilities.

# Strong — tight positive scope makes exclusions obvious
Grace executes fetch protocols and returns structured results. Interpretation and
transformation belong to the consuming agent.
```

When a hard boundary genuinely needs stating, pair it with the positive alternative in the same sentence: "Route protocol changes to Q" rather than "Do not modify protocols."

### 2. Primacy Bias

Instructions earlier in the prompt are followed more reliably than later ones. Compliance degrades measurably with position, with peak degradation around 150-200 instructions. Put the highest-signal content first: identity and core behavioral constraints before operational details and edge cases.

**Recommended section ordering:**

1. **Frontmatter** — name, description, model
2. **Identity** — 1-2 sentences: who this agent is and what metaphor anchors the role
3. **Core behavioral constraints** — the rules that matter most, positively framed
4. **Role and scope** — what the agent owns, stated as positive territory
5. **Anchoring examples** — 1-2 vignettes showing characteristic decisions
6. **Operational details** — modes, execution sequences, edge cases
7. **Output format** — templates, if applicable

This ordering front-loads what shapes behavior (identity, constraints, scope) and back-loads what shapes output (operational sequences, format templates).

### 3. Length and Context Rot

Every token in a definition competes for attention with every other token in the context window. Definitions that balloon with edge cases, caveats, and operational minutiae dilute the core behavioral signal. This is compounded in multi-agent systems where prompt sensitivity cascades — a degraded agent produces degraded output that degrades the next agent's input.

Target under 1,500 tokens for identity through scope (sections 2-4 above). Operational details that an agent needs only during execution — protocol sequences, format templates, error handling specifics — belong in protocols that load separately, not in the definition itself.

The test: if removing a sentence would not change the agent's behavior on 90% of tasks, remove it.

### 4. Anchoring Examples

Short vignette-style examples showing characteristic decisions improve behavioral compliance more than abstract personality descriptions. These anchor tone and judgment in a way that trait lists ("precise, efficient, forthright") cannot.

Anchoring examples are conversational exchanges, not input/output format pairs. They demonstrate the agent's voice and decision-making on a representative scenario.

```
## Example

**Caller:** "Fetch the task list from Asana project X."

**Grace:** "No installed protocol covers Asana. The deployment has an Asana MCP server
configured — I can use that. Alternatively, route to Q to build a fetch protocol.
Which approach?"
```

One or two vignettes is the sweet spot. Example bloat degrades the same signal the examples are meant to anchor.

### 5. XML Structural Boundaries

Use XML tags for structural separation between major sections — identity, behavioral rules, and operational context. Claude treats XML tags as semantic containers, which helps the model distinguish "who I am" from "what I do on this specific task."

Within sections, markdown headers work fine. Reserve XML for boundaries where semantic separation matters: dispatch templates, output contracts, structured handoff formats.

### 6. Frontmatter Description

The `description` field in YAML frontmatter is what Claude Code uses to decide whether to invoke the agent. Write it as a specific, action-oriented sentence: when to use this agent and what it produces.

Structure: `[What it does] + [When to use it] + [Key capabilities]`

```
# Weak — vague, doesn't help routing
description: Helps with code quality and reviews.

# Strong — specific trigger and output
description: External PR review agent. Produces a structured findings report
for a pull request you did not write.
```

### 7. Negative Triggers

Positive framing defines what an agent does. Negative triggers prevent misdispatch by stating what the agent does not handle and where to route instead. Both are needed — positive scope alone leaves ambiguous boundaries between adjacent agents.

Include negative triggers in the description field (for routing) and in the scope section (for behavioral constraint).

```
# Description with negative trigger
description: Code reviewer for mob programming tasks. Invoke after Lovelace
has implemented changes. For external PRs not produced by the mob, use Fagan.

# Scope section with routing
Friedman reviews mob-produced code. External PRs route to Fagan. PR discovery
routes to Grace.
```

Negative triggers are most valuable between agent pairs with adjacent scope: Friedman/Fagan (internal vs external review), Vera/Iris (act on findings vs surface findings), Kelly/Q (framework structure vs protocol content).

## Anti-Patterns

**Scope defined by exclusion.** A definition that lists what the agent does not do grows without bound and activates the excluded behaviors. Define positive territory; let exclusions be implicit.

**Personality as decoration.** Trait lists that don't connect to behavioral differences are wasted tokens. Every personality trait should predict a concrete decision the agent would make differently than a generic assistant.

**Operational details in the definition that belong in protocols.** Fetch sequences, CLI commands, and format templates change independently of identity. When they live in the definition, every protocol change requires editing the agent. Separate what changes together.

**History and naming rationale at the top.** The historical namesake paragraph is flavor, not signal. It belongs after identity and constraints, not before them. The model's first tokens of context should be the highest-value behavioral instructions.

## Sources

- [Anthropic: The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) — progressive disclosure (three-level system), description field best practices (WHAT + WHEN + negative triggers), definition size guidance (under 5,000 words)
- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) — positive framing, examples, XML structure
- [Lost in the Middle: How Language Models Use Long Contexts](https://arxiv.org/abs/2307.03172) — positional bias in instruction following
- [On the Positional Sensitivity of LLM-as-a-Judge](https://arxiv.org/abs/2505.21091) — compliance degradation by instruction position
- [Understanding Instruction Density in Long-Context LLMs](https://arxiv.org/abs/2507.11538) — peak degradation at 150-200 instructions
- [The Impact of Prompt Programming on Function-Level Code Generation](https://arxiv.org/abs/2502.02533) — vignette examples and behavioral compliance in multi-agent design
- [MAPRO: Multi-Agent Prompt Optimization](https://arxiv.org/abs/2510.07475) — cascading prompt sensitivity in multi-agent systems
- [Suppressing Pink Elephants with Direct Principle Feedback](https://arxiv.org/abs/2402.07896) — negation processing in attention architectures
- [Chroma: Context Rot in Retrieval-Augmented Generation](https://research.trychroma.com/context-rot) — token competition and context window dilution
