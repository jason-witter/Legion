# Legion Cookbook

Concrete examples of how to use Legion in day-to-day work. Each example shows what you say to Friday and what happens behind the scenes.

## Implement a Feature

The full mob pipeline. You describe the task; the legion designs, implements, reviews, and validates it.

**You:**
> Add rate limiting to the /api/webhooks endpoint. Max 100 requests per minute per API key, return 429 when exceeded. Here's the ticket: [paste or link]

**What happens:**
1. Friday dispatches Babbage to explore the codebase and design the approach
2. Babbage reads the existing middleware, rate limiting patterns (if any), and test files — produces a design document
3. Friday dispatches Lovelace with the feature slug and worktree path. Lovelace finds the design in the feature directory and implements it.
4. Lovelace implements the code, writes tests, commits to the branch
5. Friday dispatches Friedman with the feature slug and worktree path. Friedman orients independently from the code.
6. If Friedman finds blockers, Friday routes them back to Lovelace — this loop repeats until the review is clean
7. Friday dispatches Curie to validate test coverage and produce a validation plan
8. Friday produces a handoff document and asks if you want to push the branch

**Tips:**
- Include as much context as you have — ticket descriptions, error logs, constraints. Friday passes raw context to Babbage as inputs.
- You can walk away while the pipeline runs. Friday will notify you when it's done or if it hits a decision point.
- If you disagree with Babbage's design, say so before Friday advances to Lovelace. It's cheaper to redesign than to re-implement.

## Review a Pull Request

Fagan reviews PRs you didn't write. He cold-starts from the diff and produces a structured findings report.

**You:**
> Review PR #1847

**What happens:**
1. Friday dispatches Fagan in the background
2. Fagan fetches the PR diff, metadata, CI status, and existing reviewer comments
3. Fagan applies his inspection sequence: intent assessment, correctness, security, code quality, test coverage, pattern consistency
4. Fagan integrates existing reviewer comments — acknowledging what's already been flagged, noting disagreements
5. Fagan writes a report to `scratch/output/` and Friday summarizes the findings

**Tips:**
- Fagan writes to disk, not to GitHub. You decide what to post.
- For re-reviews (the PR was updated since last review), Fagan reads his prior report, fetches the delta diff, and focuses on what changed.
- You can ask Friday to summarize just the blockers if the report is long.

## Review Multiple PRs

Independent work dispatches in parallel. Each PR gets its own Fagan instance.

**You:**
> Review PRs #1847, #1852, and #1860

**What happens:**
1. Friday dispatches three Fagan instances simultaneously — one per PR
2. Each Fagan works independently, fetching and reviewing its own PR
3. As each completes, Friday reports the findings
4. Friday can synthesize across all three if you ask ("any common patterns?")

**Tips:**
- This works for any independent task, not just reviews. Three features to implement? Three Babbage dispatches.
- Friday stays available while agents work in the background. You can ask questions, do other work, or dispatch more agents.

## Get a Digest of Feedback on Your PR

Denniston triages review feedback on PRs you authored.

**You:**
> What's the feedback on my PR #1823?

**What happens:**
1. Friday dispatches Denniston to fetch and categorize the feedback
2. Denniston reads all reviews and inline comments, categorizes each as: needs code change, is conversation, or is blocking
3. Denniston writes a digest to `scratch/output/` — Friday summarizes what needs attention

**Tips:**
- Useful when you come back to a PR after a few days and need to catch up on what happened.
- Denniston doesn't respond to comments — he just tells you what's there.

## Ask a Question About the Code

Not everything needs the pipeline. Simple questions get handled inline.

**You:**
> How does the payment retry logic work?

**What happens:**
- Friday reads the relevant code and explains it directly. No agents dispatched — the overhead would exceed the work.

**You:**
> What would break if I removed the `max_retries` parameter?

**What happens:**
- Friday searches for usages, reads the callers, and tells you the impact. Still inline — it's a research question, not a coding task.

**When Friday dispatches instead:**
> Refactor the retry logic to use exponential backoff instead of fixed intervals.

This is a coding task. Friday kicks off the mob pipeline.

## Triage a Backlog

Foley assesses whether tasks are ready for the mob pipeline.

**You:**
> Here are the tickets for this sprint. Which ones are ready to dispatch? [paste or link to task list]

**What happens:**
1. Friday dispatches Grace to fetch the task data (if from an external system)
2. Friday dispatches Foley with the fetched data
3. Foley assesses each task for dispatch readiness — does it have enough context? Are dependencies resolved? Is the scope clear?
4. Foley produces a ranked queue with readiness assessments

**Tips:**
- Tasks Foley flags as "too sparse" can be routed to Penkovsky for enrichment.
- The ranked queue feeds directly into mob pipeline dispatches for the ready items.

## Customize Your Deployment

Add a protocol specific to your workflow.

**Example: custom commit message format**

**You:**
> I want all commits in my repo to follow the format `[area] description`. Can you create a protocol for that?

**What happens:**
1. Friday dispatches Q to create the protocol
2. Q writes it to `protocols/local/commit-format.md`
3. Lovelace reads it on future mob pipeline runs and follows the format

**Example: custom review checklist**

**You:**
> When Friedman reviews code that touches the payments module, I want him to also check that all amount calculations use Decimal, not float.

**What happens:**
1. Friday dispatches Q to create a protocol or Vera to update Friedman's definition
2. The change goes in `protocols/local/` or is surfaced for your review before modifying the framework

**Tips:**
- `protocols/local/` is for your workflow. Framework protocols in `protocols/` are generic.
- Rules in `rules/local/` apply to every session. Protocols are read on demand by specific agents.

## Capture Out-of-Scope Issues

When the mob discovers something that doesn't belong in the current task, Penkovsky captures it.

**You** (during a pipeline run):
> That auth middleware issue Friedman flagged — it's out of scope for this PR but we should track it.

**What happens:**
1. Friday dispatches Penkovsky with the context from Friedman's review
2. Penkovsky writes a ticket to `scratch/output/` with the issue description, relevant code locations, and suggested priority
3. You decide whether to file it in your task tracker

## Modify Legion Itself

Kelly handles structural changes to the framework.

**You:**
> I want to add a new agent that handles database migration reviews.

**What happens:**
1. Friday dispatches Vera to design the agent definition
2. Vera writes the draft to `scratch/agents/` for your review
3. Once approved, the definition is promoted to `agents/`
4. The agent is available in your next Claude Code session

**Tips:**
- New agents require a session restart to appear in the agent registry.
- Iris can review agent definitions for scope clarity and overlap with existing agents.
