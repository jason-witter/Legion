#!/bin/bash
# artifact-volume.sh <feature-dir>
#
# Prints what the pipeline wrote about itself in one feature directory: bytes and
# lines per artifact, grouped by station, with a total. Counterpart to
# scripts/prose-lint.py, which measures comment volume in the product repo and
# has no equivalent for the framework's own output.
#
# A measurement, not a gate. There is no right size for a design document, and a
# hard cap would be wrong; what is worth seeing is growth nobody chose. In the
# session that prompted this, one design chain ran 19K, 29K, 40K, 48K, 43K, 27K,
# 24K across seven rounds, and the 48K round was not a deliberate decision by
# anyone.
#
# The number to watch is the per-station trend, not any single file. A later
# round larger than its predecessor usually means the artifact restated the one
# it was answering, which rules/dispatch-shape.md makes unnecessary: the next
# station is dispatched the current artifact by name and never sees the prior
# round.

set -u

if [ $# -ne 1 ]; then
    echo "usage: artifact-volume.sh <feature-dir>" >&2
    exit 2
fi

DIR="${1%/}"

if [ ! -d "$DIR" ]; then
    echo "error: ${DIR} is not a directory" >&2
    exit 2
fi

TOTAL_BYTES=0
TOTAL_FILES=0

# Station is the filename up to the first underscore or hyphen, so friedman_1.md
# and friedman_taxcorr_2.md group together and comms drafts group under their own
# name. Output follows glob order, which keeps each chain contiguous.
printf '%-44s %10s %8s\n' 'ARTIFACT' 'BYTES' 'LINES'
printf '%-44s %10s %8s\n' '--------' '-----' '-----'

for f in "$DIR"/*.md; do
    [ -e "$f" ] || continue
    base=$(basename "$f")
    bytes=$(wc -c < "$f" | tr -d ' ')
    lines=$(wc -l < "$f" | tr -d ' ')
    printf '%-44s %10s %8s\n' "$base" "$bytes" "$lines"
    TOTAL_BYTES=$((TOTAL_BYTES + bytes))
    TOTAL_FILES=$((TOTAL_FILES + 1))
done

for sub in record external; do
    [ -d "$DIR/$sub" ] || continue
    for f in "$DIR/$sub"/*.md; do
        [ -e "$f" ] || continue
        base=$(basename "$f")
        bytes=$(wc -c < "$f" | tr -d ' ')
        lines=$(wc -l < "$f" | tr -d ' ')
        printf '%-44s %10s %8s\n' "$sub/$base" "$bytes" "$lines"
        TOTAL_BYTES=$((TOTAL_BYTES + bytes))
        TOTAL_FILES=$((TOTAL_FILES + 1))
    done
done

printf '%-44s %10s %8s\n' '--------' '-----' '-----'
printf '%-44s %10s\n' "${TOTAL_FILES} files" "$TOTAL_BYTES"

# Roughly four bytes to a token, close enough to decide whether a number matters.
printf '\nabout %s tokens if a station read all of it\n' "$((TOTAL_BYTES / 4))"
