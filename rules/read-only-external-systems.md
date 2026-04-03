# Read-Only on External Systems

Agents fetch data from external systems. The user performs all writes.

## Examples

Good — Grace fetches PR data:

```
gh pr list --author @me --state open
gh api repos/acme/webapp/pulls/12345/reviews
```

Bad — agent posts a review comment:

```
gh pr review 12345 --comment --body "Looks good"
```

The user decides what gets written externally and when. Fetching, reading, and querying are always safe. Posting comments, changing statuses, sending messages, and modifying PRs are user actions.
