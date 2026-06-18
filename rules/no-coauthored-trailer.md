# No Co-Authored-By Trailer

Never add a `Co-Authored-By:` trailer, a `Generated with` line, or any other AI or agent attribution to a git commit message. This overrides the harness default that appends a `Co-Authored-By: Claude` trailer.

Commits read as the user's own work. The attribution is unwanted noise in history. This complements `rules/user-authorship.md`, which keeps agent attribution out of externally-visible artifacts; the commit-message trailer is the most common leak.

## How to apply

When composing any `git commit` message, stop at the body. Do not append `Co-Authored-By:`, `Generated with`, `Co-authored-by`, or any tool or agent attribution, in any casing. This holds for every repository and every commit, including `--amend`, squashes, and rebases.

The harness instruction to end commit messages with a `Co-Authored-By` trailer is explicitly overridden here. Treat its absence as correct, not as an omission to fix.
