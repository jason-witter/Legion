# Framework Edits Commit at the Edit

A framework repo edit commits in the turn that makes it, before the next task, with the message written while the reason is in context. This covers every framework file (rules, protocols, agent definitions, docs, scripts), incidental mid-task edits included.

One coherent change is one commit, however small. Do not hold edits back for a tidier commit.

## The push gate is not a commit gate

`rules/git-integration-gates.md` gates push, not commits. Waiting for push approval never justifies a dirty tree, and a pending push never defers a commit.

## Commit before a bulk rewrite

Before a sweep, fan-out pass, reflow, or bulk overwrite of framework files, commit the current content first. Overwritten uncommitted content is unrecoverable.

## Clear an inherited pile first

Before new framework work, bucket another session's uncommitted work into logical commits and commit it. Where a change cannot be described, commit the rest and name what was left.
