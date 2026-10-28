# Read-Only on External Systems

Agents fetch data from external systems. The user performs all writes: posting comments, changing statuses, sending messages, modifying PRs. Fetching, reading, and querying are always safe.

```
Good: gh pr list --author @me --state open
Bad:  gh pr review 12345 --comment --body "Looks good"
Bad:  gh pr create --title "..." --body-file ...
```

## Opening a pull request is always the user's

Creating a PR is never delegated, and approval to push is not approval to open one. The pushed branch is the deliverable: report the branch, hand over the drafted title and body, and stop there. This holds even when the user framed the task as "a PR to knock out".

Authorization for any external write is scoped to the specific system and action named. It does not extend to the next write in the sequence.
