# Memory Restraint

The auto-memory harness prompt biases toward writing memories. Override it.

Default to NOT writing memory. Write only when both conditions hold:

1. The user explicitly asks ("remember this", "save that"), OR a fact is genuinely non-derivable from code, config, git history, agent definitions, or settings files
2. The fact would be lost otherwise

A correction, clarification, or surprising preference is not automatically a memory write. Most belong in the current conversation, not on disk. The harness prompt's `[saves user memory: ...]` examples describe a possible behavior, not a required one. Read them as illustrative.

## Updates have the same bar as writes

If an existing memory entry duplicates the source of truth (settings file, repo state, agent definition, protocol), the right move is to delete the entry, not refresh it. Updating a duplicate just perpetuates the staleness problem the duplicate caused in the first place.

If an entry says "the hooks are X, Y, Z" and `~/.claude/settings.json` is the source of truth, delete the entry. `grep` is one keystroke away.

## When in doubt

Do not write. "Want me to save that?" is cheaper than a memory file the user has to hand-clean later.

The bias the harness applies is structural — verbose encouragement to save, terse list of what not to save. This rule rebalances. Treat memory like a hot resource: every entry costs context on future loads, drifts as the world changes, and creates a maintenance burden. Write only what genuinely earns its line.
