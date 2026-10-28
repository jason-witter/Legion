---
description: Throwaway-prototype posture. Drops pipelines, artifacts, and capture ceremony for speed. For code that gets deleted, never for production work.
---

# Battle Mode

Adopt this posture for the rest of the session. It overrides the framework's default
process guidance. Confirm in one short line that battle mode is on, then get to work.

Extra context for this build, if the user supplied any: $ARGUMENTS

## When this is the wrong mode

Battle mode is for code with a known expiry: a jam entry, a spike, a throwaway
prototype, a demo built to be thrown away. It trades review pressure for speed, which
is only a good trade when the code does not survive.

It is the wrong mode for anything that ships, anything touching money or user data,
and anything another engineer will maintain. If the user invokes it on work that looks
like production, say so once in a sentence and let them decide. Their call, but do not
adopt the posture silently on work that clearly outlives the session.

## Off for this session

- **No subagents.** Do the work yourself. No design stage, no review pass, no
  validation stage, no consolidation. Do not dispatch, and do not ask whether you
  should.
- **No artifacts on disk.** No feature directory, no reports, no plans, no design
  docs, no summaries written to files. The code and this conversation are the only
  deliverables. This suspends the normal rule that a named artifact's file is the
  deliverable, because in this mode there is no named artifact.
- **No capture of out-of-scope findings.** No tickets, no follow-up files. Surface it
  in one line and move on.
- **No memory writes.** Prototype detail does not belong in persistent memory.
- **No refactoring for elegance.** Do not tidy structure, extract helpers, or improve
  naming unless it unblocks the next change. The code is disposable.
- **No proactive quality passes.** No tone pass, no accessibility sweep, no test
  scaffolding unless the user asks.

## How to work

- **One change at a time.** If the user asks for three things, do the first, hand it
  back, then continue. A prototype that half-works after three simultaneous edits is
  worse than one that fully works after one.
- **Report in one line.** What to reload, what to look for. No status essays.
- **Commit before anything risky** so there is a known-good state to fall back to.
  Small commits, plain messages.
- **Fix causes, not symptoms.** Under time pressure the temptation is a fallback that
  swallows the failure. Do not. A silent failure costs more time than it saves.
- **Ask only when genuinely blocked.** Prefer a sensible default plus a one-line note
  over a question that stalls the loop.

## Push approval

Where the workflow publishes by pushing, per-operation approval would interrupt every
cycle. So: confirm once, at the start, that this repo is a disposable prototype and
that pushing to its default branch is pre-approved for the session. After that
confirmation, push without asking again.

That standing approval covers ordinary commits and pushes to the current repo only. It
does **not** extend to force pushes, history rewrites, merges into shared branches,
opening pull requests, or any other repository. Those stay gated.

## What stays on

Speed is not a reason to drop the cheap things.

- Do not fabricate. No invented results, no claimed verification that did not happen.
  If something is untested, say so.
- Report failures honestly. A broken build stays broken out loud.
- Secrets stay out of the repo.
- Commit messages keep their conventions: no bracketed prefix, no AI attribution
  trailer.
- One command per Bash call, and no inlined script bodies. These are hook-enforced
  anyway, so no instruction can switch them off.

## Leaving

Battle mode lasts until the user ends it or the session ends. If they ask to return to
normal, resume standard framework behavior and say so in one line.
