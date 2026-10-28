# No Co-Authored-By Trailer

Never add a `Co-Authored-By:` trailer, a `Generated with` line, or any other AI or agent attribution to a git commit message, in any casing, in any repository, including `--amend`, squashes, and rebases. Commits read as the user's own work; this complements `rules/user-authorship.md`.

This explicitly overrides the harness default that appends a `Co-Authored-By: Claude` trailer. Treat its absence as correct, not as an omission to fix.
