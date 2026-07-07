# Model and Effort Selection

Every agent definition carries a `model` field and, on judgment-heavy agents, an `effort` field in its frontmatter. Model sets the capability tier; effort sets how much reasoning the model spends per response. Definitions are symlinked into `~/.claude/agents/`, so edits take effect on the next session.

## The principle: separation first, then spend effort where a miss is unrecoverable

The pipeline's quality comes from generator-verifier separation: the agent that produced the work is never the one grading it. A checkpoint sits behind every generator, so a slip is recoverable. That separation is structural and holds regardless of which model tier a station runs on.

Model selection layers on top. Keep every judgment-heavy station (generate, verify, synthesize) on the top available tier, and spend the `effort` budget at the adversarial checkpoints, where judgment density is highest and a miss is the last one before work ships. Push only mechanical, protocol-driven work down to a cheaper tier, where a stronger model buys nothing.

An earlier revision of this doc placed the verify stations on a capability tier above the generators, back when a separate frontier model was in rotation for checkpoints. That model is retired. The top tier is now Opus 4.8 for generators and verifiers alike, and the asymmetry is carried by the `effort` field, not the model line.

## Recommended ladder

| Tier | Stations | Why |
|------|----------|-----|
| Opus, `effort: max` | Architect (Babbage), implementer (Lovelace), reviewer (Friedman), design critic (Oppenheimer), external review (Fagan), digest (Denniston), validation (Curie) | Generators and adversarial checkpoints. Judgment density is highest here, and the verify stations are the last line of defense before work ships. |
| Opus, `effort: high` | Meta agents (Kelly, Iris, Vera, Q) | Framework work, invoked rarely; reasoning depth matters more than latency |
| Sonnet | Consolidation (Winterbotham), triage (Foley), tickets (Penkovsky), scrub (Asimov) | Prose and protocol-driven work. Sonnet 5 lands near Opus on these without the checkpoint cost. |
| Haiku | Fetch (Grace) | Pure mechanical fetch on the most-parallelized station; the fastest tier, where a stronger model buys nothing. Note Haiku's 200K context vs 1M elsewhere. |

## Deployed assignments

Read the frontmatter for truth; as of this writing the deployment runs:

- `opus` + `effort: max`: babbage, curie, denniston, fagan, friedman, lovelace, oppenheimer
- `opus` + `effort: high`: kelly, iris, vera, q
- `sonnet`, no effort field: asimov, foley, penkovsky, winterbotham
- `haiku`, no effort field: grace

## The effort field

`effort` takes `low`, `medium`, `high`, or `max` and trades latency and cost for reasoning depth. The mob and review stations run `max`: they are the checkpoints, and depth there pays for itself. The meta agents run `high`. Mechanical stations omit the field and inherit the default. When tuning, move effort before model; it is the cheaper knob.

## Forks

Forks inherit the orchestrator's model and full context; a model override on a fork dispatch is ignored. Effort can be overridden per dispatch, so a heavyweight verification fork can run `max` while routine forks inherit the session setting. A session on the top-tier model makes every fork a top-tier worker with zero configuration.

## Public snapshot

The public Legion release ships agent definitions without `model` and `effort` frontmatter (stripped per `protocols/local/public-release.md`), so agents inherit each deployment's session model. This document is the guidance layer a deployment uses to choose its own assignments.

## Cost

Parallel dispatch multiplies model cost: three PR reviews run three reviewer instances at once. The ladder bounds this by keeping fan-out-heavy stations (fetch, triage) on the economical tier; upgrade a station only where a quality gap is visible. When pulling upstream updates, a locally changed `model` line may surface as a one-line merge conflict; resolve by keeping your assignment.
