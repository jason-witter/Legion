# Model and Effort Selection

Every agent definition carries a `model` field and, on judgment-heavy agents, an `effort` field in its frontmatter. Model sets the capability tier; effort sets how much reasoning the model spends per response. Definitions are symlinked into `~/.claude/agents/`, so edits take effect on the next session.

## The principle: separation first, then spend effort where a miss is unrecoverable

The pipeline's quality comes from generator-verifier separation: the agent that produced the work is never the one grading it. A checkpoint sits behind every generator, so a slip is recoverable. That separation is structural and holds regardless of which model tier a station runs on.

Model selection layers on top. Keep every judgment-heavy station (generate, verify, synthesize) on the top available tier, and spend the `effort` budget at the adversarial checkpoints, where judgment density is highest and a miss is the last one before work ships. Push only mechanical, protocol-driven work down to a cheaper tier, where a stronger model buys nothing.

An earlier revision of this doc placed the verify stations on a capability tier above the generators, back when a separate frontier model was in rotation for checkpoints. That model is retired. The top tier is now Opus 5 for generators and verifiers alike, and the asymmetry is carried by the `effort` field, not the model line.

## Recommended ladder

| Tier | Stations | Why |
|------|----------|-----|
| Opus, `effort: xhigh` | Architect (Babbage), implementer (Lovelace), reviewer (Friedman), design critic (Oppenheimer), external review (Fagan), feedback triage (Denniston), validation (Curie) | Generators and adversarial checkpoints. Judgment density is highest here, and the verify stations are the last line of defense before work ships. Anthropic scopes `xhigh` to long-horizon agentic and coding work, which a mob run on a real diff is. On Opus 5 it is a deliberate step up from the default rather than the recommended start, so these seven are the stations to sweep first. |
| Opus, `effort: high` | Orchestrator session, meta agents (Kelly, Iris, Vera, Q) | The documented Opus 5 starting point and the knee of the cost/quality curve. The orchestrator routes and synthesizes rather than inspecting; the meta agents are invoked rarely. |
| Sonnet, `effort: low` (Asimov `medium`) | Consolidation (Winterbotham), triage (Foley), tickets (Penkovsky), fetch (Grace), scrub (Asimov) | Prose and protocol-driven work. Sonnet 5 lands near Opus on these without the checkpoint cost, and Anthropic names subagents as the canonical `low` case. Asimov runs `medium` because the tone pass makes editorial judgment calls rather than following a script. |

Denniston belongs on the checkpoint tier even though it reads like a triage station, and the reason is worth stating because it has been mis-derived once. Its mandate includes labelling a reviewer's comment wrong, so a false clearance dismisses valid feedback on the user's own pull request. The digest exists precisely so the user does not re-read every raw comment, which means a confident wrong call has nothing downstream to catch it: the compression is the station's purpose and also its exposure. It clears findings under `rules/verify-before-clearing.md` on the same terms as Fagan and uses the same ref-pinned line-content contract. On Opus 5 the risk compounds, because the model follows filtering instructions literally and lower effort scopes work more tightly to what was asked. Treat "it only dispositions what others already found" as a rejected argument, not a reason to step it down.

## Deployed assignments

Read the frontmatter for truth; as of this writing the deployment runs:

- `opus` + `effort: xhigh`: babbage, curie, denniston, fagan, friedman, lovelace, oppenheimer
- `opus` + `effort: high`: kelly, iris, vera, q
- `sonnet` + `effort: low`: foley, grace, penkovsky, winterbotham
- `sonnet` + `effort: medium`: asimov

The orchestrator session runs `high` via `effortLevel` in `~/.claude/settings.json`. Every station pins its own effort explicitly, so no agent inherits the session value; that is deliberate, because a session-level change would otherwise silently re-tier the whole roster.

## The effort field

`effort` takes `low`, `medium`, `high`, `xhigh`, or `max` and trades latency and cost for reasoning depth. Thinking tokens bill as output. The roster ceiling is `xhigh`; `max` is available on agent dispatches but unused, and the harness `effortLevel` setting does not accept it at all (its enum stops at `xhigh`). When tuning, move effort before model; it is the cheaper knob.

**`high` is the default, not `xhigh`.** The API default is `high`, and Claude Code follows it. An earlier revision of this doc claimed `xhigh` was the harness default and concluded that mechanical stations could safely omit the field; both halves were wrong. A station with no `effort` line inherits whatever `effortLevel` the session carries, so under a session-level `xhigh` the fetch and consolidation stations were running `xhigh` reasoning on scripted work. Every station now pins its level explicitly.

**Effort is not only a thinking-depth knob.** It shapes all output tokens, including how many tool calls the agent makes. Artificial Analysis measured Opus 5 on their agentic knowledge-work benchmark at 76, 91, and 103 turns per task for `high`, `xhigh`, and `max`, at $10.41, $14.26, and $17.79 per task. So raising effort raises turn count, and on a station that already pays a per-call tax (`rules/discrete-operations.md`) that compounds. Their Elo ordering across the same three levels was 1606, 1693, and 1720, with `medium` at 1470 and `low` at 1223: `high` sits at the knee, since stepping up costs 37% for 87 Elo while stepping down to `medium` gives up 136.

**Re-sweep effort on every model migration.** Anthropic's per-model guidance moves. Opus 4.7 and 4.8 both documented `xhigh` as the starting point for coding and agentic work; Opus 5 moved the recommended start back to `high` and says explicitly that settings carried over from an earlier model should be re-derived rather than reused. Treat an effort level inherited across a model change as stale until measured.

**Hold effort constant within a session.** The resolved effort value is rendered into the prompt, so changing it between requests invalidates cached prefixes. Vary effort across workloads and stations, never per turn inside one conversation.

To measure rather than guess, `usage.output_tokens_details.thinking_tokens` reports billed reasoning tokens directly.

## Forks

Forks inherit the orchestrator's model and full context; a model override on a fork dispatch is ignored. Effort can be overridden per dispatch, so a heavyweight verification fork can run `xhigh` while routine forks inherit the session setting; the roster's `xhigh` ceiling applies to fork overrides too. A session on the top-tier model makes every fork a top-tier worker with zero configuration.

## Public snapshot

The public Legion release ships agent definitions without `model` and `effort` frontmatter (stripped per `protocols/local/public-release.md`), so agents inherit each deployment's session model. This document is the guidance layer a deployment uses to choose its own assignments.

## Cost

Parallel dispatch multiplies model cost: three PR reviews run three reviewer instances at once. The ladder bounds this by keeping fan-out-heavy stations (fetch, triage) on the economical tier; upgrade a station only where a quality gap is visible. When pulling upstream updates, a locally changed `model` line may surface as a one-line merge conflict; resolve by keeping your assignment.
