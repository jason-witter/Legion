# Writing Effective Protocols

Reference for anyone writing operational protocols for Claude-based agents. Protocols live in `protocols/` and define multi-step procedures that agents execute sequentially. A protocol that the model improvises around is worse than no protocol — it's unreliable behavior wearing a procedural mask.

## Core Techniques

### 1. Numbered Steps Over Prose

Sequential work must be numbered steps with action verbs and expected outputs. Prose gets treated as general context — the model absorbs the gist but skips or reorders individual actions. The ROUTINE framework found numbered steps with per-step examples significantly outperformed prose instructions for sequential execution.

```
# Weak — prose
Fetch the user's teams, then build a search query that excludes team-based
review requests, and run it to get individually-requested PRs.

# Strong — numbered steps
Step 1: Fetch user's teams — `gh api user/teams --jq '.[].slug'`
Step 2: Build query with `-team-review-requested:org/<slug>` per team
Step 3: Run `gh pr list` with the assembled exclusion filters
```

### 2. Step Cap and Decomposition

7-10 top-level steps before step-skipping becomes a measurable risk. If more steps are needed, decompose into sub-protocols that load per-phase rather than a single monolithic document. Anthropic's own agent harness guidance uses specialized prompts per phase for this reason.

`pr-review.md` has 7 analysis steps. `authored-prs-fetch.md` has 4 execution steps with sub-commands grouped logically under each. Both stay under the threshold.

### 3. Brief Rationale Per Step

A one-line "why" for non-obvious steps gives the model a reasoning anchor for edge cases. Omit for self-evident steps — rationale on every step becomes noise.

```
# Good — rationale where it changes behavior
Step 1: Fetch user's teams -- used to build the exclusion filter dynamically

# Bad — rationale on a self-evident step
Step 3: Run the PR query -- this retrieves the PRs we need
```

### 4. Primacy Bias

The model is more likely to follow instructions at the start of a protocol than at the end. Put critical steps and failure-mode handling early. Edge cases and optional enhancements go after the main flow.

`pr-review.md` places the confidence filter — its most important behavioral constraint — before the output format, not buried at the end. Edge cases are last.

### 5. Context Rot and Length

Every token competes for attention. Protocols should be as tight as possible while remaining unambiguous. Cut rationale that doesn't change behavior. Replace verbose edge case paragraphs with single conditional lines.

```
# Verbose
If the user provides specific PR numbers via the pr_numbers parameter,
those numbers should be used directly as the working set and the list
fetch step should be skipped entirely, since we already know which PRs
to operate on.

# Tight
When `pr_numbers` is provided, use those numbers directly. Skip the list fetch.
```

### 6. Step-Level Examples

Show expected output at the step where it's produced, not in a separate examples section. This anchors the model's generation to the right shape at the right moment.

`authored-prs-fetch.md` includes the exact `gh` command and `--jq` filter at each step, making the expected output shape unambiguous. `pr-review.md` includes the full output template inline with the output step.

## Recommended Protocol Structure

1. **Title and purpose** — one line stating what the protocol does and what it produces
2. **Prerequisites** — what must be true before execution (tools, auth, directory)
3. **Parameters** — inputs the caller can supply, with defaults
4. **Execution steps** — numbered, action verbs, expected output per step
5. **Output format** — the artifact shape, with a concrete template
6. **Edge cases** — brief, after the main flow, one line per case

Keep the total tight. If a protocol needs more than ~200 lines, it likely needs decomposition.

## Anti-Patterns

**Prose procedures.** Narrative descriptions of sequential work invite improvisation. Number the steps.

**Monolithic protocols.** 15+ steps in a single document. The model will skip or merge steps past the attention threshold. Decompose into phases.

**Rationale essays.** Paragraph-length justifications inline with steps. One line or cut it.

**End-loaded critical constraints.** Putting the most important behavioral rule in the last section. Move it up — primacy bias is real.

**Examples only at the end.** A single end-to-end example teaches less than step-level examples at each decision point.

## Sources

- [Anthropic: The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) — protocols as the knowledge layer on top of tool access, scripted validation over language instructions for critical gates
- [Anthropic: Prompt Engineering - Be Direct and Clear](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/be-clear-and-direct) — context as motivation, right altitude for instructions
- [Anthropic: Build Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) — phase-specialized prompts over monolithic instructions
- [ROUTINE: Robust Optimization of LLM Workflows](https://arxiv.org/abs/2507.14447) — numbered steps with per-step examples outperform prose; step-level examples beat end-to-end examples
- [Conversation Routines for Autonomous AI Agents](https://arxiv.org/abs/2501.11613) — 7-10 step cap, action verbs, expected outputs per step
- [Pre-Act: Aligning LLM Agents by Prepending Future Actions](https://arxiv.org/abs/2505.09970) — action-oriented step framing improves execution fidelity
- [Positional Bias in Long-Context LLMs](https://arxiv.org/abs/2505.21091) — primacy bias in instruction following
- [Chroma: Context Rot](https://research.trychroma.com/context-rot) — token competition and attention degradation in long contexts
