# Dispatch Shape

Every agent dispatch is exactly three fields.

```
<dispatch>
  <intent>The goal, stated as an outcome, not a procedure</intent>
  <inputs>File paths, identifiers, parameters. Raw data only.</inputs>
  <scope>What is in scope, what is excluded, any constraints.</scope>
</dispatch>
```

Good: `<intent>Fetch open PR review requests for acme/webapp</intent>`

Bad: `<intent>Run gh pr list --search "review-requested:@me" and return a manifest</intent>`

## Dispatch the Problem, Not Candidate Solutions

Raw task data (ticket descriptions, bug reports, error logs) belongs in inputs. Candidate solutions, teammate opinions, and proposed fixes do not.

## Enumerate Files, Characterize None

Name the specific files the station needs, whole and unedited, and say nothing about what is in them. Never summarize, characterize, or direct attention to a prior station's output.

Good:

```
<inputs>Design: scratch/output/_pr-1234-signup-flow-experiment/babbage_2.md
Worktree: /path/to/worktree</inputs>
<scope>Independent review.</scope>
```

Bad:

```
<inputs>Worktree: /path/to/worktree. The design renamed the experiment and fixed two call sites.</inputs>
<scope>Pay particular attention to variant rename correctness.</scope>
```

If a station is reading too much, narrow the address. Never fix over-reading by narrating: do not describe or summarize the artifact, tell the agent which parts matter, or trade a directory address for an orchestrator summary.

### The read set

What a dispatch names, plus the code:

- **Pipeline artifacts**, named individually: the current design, and for a verification pass the single report whose findings it must discharge.
- **External data**, named individually when a station needs it.
- **Never the record class**: the feature directory's `README.md`, `record/`, comms drafts, and the pipeline narrative.
- **Nothing superseded, and nothing from another run.** Currency is defined in `rules/feature-directory-lifecycle.md`.
- **No prior output as a verification baseline when the change is meant to move it**, in or out of a pipeline. Read `protocols/superseded-output-is-not-a-baseline.md` before composing any check that compares against an earlier run.

A verification pass receives the prior report as an **additional obligation, never as a scope**: it discharges those findings on top of a full pass (`protocols/mob-pipeline.md`).

Claims about the codebase inside any named artifact are pointers to verify, not facts to inherit; `rules/code-facts-from-the-tree.md` governs.
