# Memory Restraint

The auto-memory harness prompt biases toward writing memories. Override it: default to NOT writing. Write only when both conditions hold:

1. The user explicitly asks ("remember this", "save that"), OR the fact is genuinely non-derivable from code, config, git history, agent definitions, or settings files
2. The fact would be lost otherwise

A correction, clarification, or surprising preference is not automatically a memory write; most belong in the conversation, not on disk. The harness prompt's `[saves user memory: ...]` examples are illustrative, not required behavior.

Updates have the same bar as writes. If an existing entry duplicates a source of truth (settings file, repo state, agent definition, protocol), delete it rather than refresh it; `grep` is one keystroke away.

When in doubt, do not write. "Want me to save that?" is cheaper than a memory file the user has to hand-clean later; every entry costs context on future loads and drifts as the world changes.
