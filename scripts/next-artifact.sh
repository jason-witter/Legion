#!/bin/bash
# next-artifact.sh <feature-dir> <agent> [stage-infix]
#
# Prints the next artifact filename for an agent in a feature directory per
# rules/feature-directory-lifecycle.md naming:
#   <agent>_<N>.md                       mob pipeline
#   <agent>_<infix>_<N>.md               stage-specific (e.g. fagan_preship_2.md)
# Parallel-pass letter suffixes (fagan_preship_1a.md) occupy their N; the next
# number continues past them. Deterministic replacement for "list the directory
# before choosing N" recall.
#
# Prints the bare filename on stdout. If the directory does not exist yet, the
# sequence starts at 1 and a note goes to stderr.

set -u

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "usage: next-artifact.sh <feature-dir> <agent> [stage-infix]" >&2
    exit 2
fi

DIR="$1"
AGENT="$2"
INFIX="${3:-}"

PREFIX="$AGENT"
if [ -n "$INFIX" ]; then
    PREFIX="${AGENT}_${INFIX}"
fi

MAX=0
if [ -d "$DIR" ]; then
    for f in "$DIR/${PREFIX}"_*.md; do
        [ -e "$f" ] || continue
        rest=$(basename "$f" .md)
        rest=${rest#"${PREFIX}"_}
        num=${rest%[a-z]}
        case "$num" in
            ''|*[!0-9]*) continue ;;
        esac
        if [ "$num" -gt "$MAX" ]; then MAX="$num"; fi
    done
else
    echo "note: ${DIR} does not exist yet; starting at 1" >&2
fi

echo "${PREFIX}_$((MAX + 1)).md"
