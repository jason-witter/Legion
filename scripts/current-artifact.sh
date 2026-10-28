#!/bin/bash
# current-artifact.sh <feature-dir> <agent> [run-scope]
#
# Prints the CURRENT artifact filename for an (agent, run) pair per
# rules/feature-directory-lifecycle.md: the highest N within that run.
#   <agent>_<N>.md                       single-run feature
#   <agent>_<run>_<N>.md                 run-scoped (e.g. friedman_taxcorr_2.md)
#
# The counterpart to next-artifact.sh, which prints the next number to write.
# This prints the file a dispatch should name, so the orchestrator does not have
# to work out currency by listing the directory.
#
# Scope handling is deliberate: omitting the run scope reads the UNSCOPED run
# only, never all runs. A slip therefore degrades to "wrong run" rather than
# "every run mixed together," and a mistyped scope returns nothing at all.
#
# Exit 0 with the filename on stdout when an artifact exists. Exit 1 with a
# message on stderr when none does, because an empty result is the designated
# signal that a run scope was mistyped (a real run always has a file once its
# first station has written).
#
# Parallel-pass letter suffixes (friedman_taxcorr_1a.md) occupy their N. When the
# current N carries suffixes, every sibling at that N is printed, one per line:
# a consolidator reads all of them and they are current, not superseded.

set -u

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "usage: current-artifact.sh <feature-dir> <agent> [run-scope]" >&2
    exit 2
fi

DIR="$1"
AGENT="$2"
SCOPE="${3:-}"

PREFIX="$AGENT"
if [ -n "$SCOPE" ]; then
    PREFIX="${AGENT}_${SCOPE}"
fi

if [ ! -d "$DIR" ]; then
    echo "none: ${DIR} does not exist" >&2
    exit 1
fi

MAX=0
for f in "$DIR/${PREFIX}"_*.md; do
    [ -e "$f" ] || continue
    rest=$(basename "$f" .md)
    rest=${rest#"${PREFIX}"_}
    # Strip a trailing parallel-pass letter, then require the remainder to be
    # digits. This is what excludes another run's files from an unscoped read:
    # "taxcorr_1" keeps a non-digit and is skipped.
    num=${rest%[a-z]}
    case "$num" in
        ''|*[!0-9]*) continue ;;
    esac
    if [ "$num" -gt "$MAX" ]; then MAX="$num"; fi
done

if [ "$MAX" -eq 0 ]; then
    if [ -n "$SCOPE" ]; then
        echo "none: no ${AGENT} artifact in run '${SCOPE}' under ${DIR}" >&2
        echo "      (if that run should exist, check the scope for a typo)" >&2
    else
        echo "none: no unscoped ${AGENT} artifact under ${DIR}" >&2
        echo "      (run-scoped artifacts are not read without an explicit scope)" >&2
    fi
    exit 1
fi

FOUND=0
for f in "$DIR/${PREFIX}_${MAX}".md "$DIR/${PREFIX}_${MAX}"[a-z].md; do
    [ -e "$f" ] || continue
    basename "$f"
    FOUND=1
done

[ "$FOUND" -eq 1 ] || exit 1
