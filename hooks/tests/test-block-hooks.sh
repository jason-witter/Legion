#!/bin/bash
# Test harness for block-chained-commands.sh and block-inbox-em-dashes.sh.
# Feeds JSON payloads to the hooks and asserts block/pass decisions.
#
# Usage: bash hooks/tests/test-block-hooks.sh
# Exit 0 with "ALL PASS" when every case behaves; exit 1 listing failures.

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$(cd "$TESTS_DIR/.." && pwd)"

CHAIN_HOOK="$HOOKS_DIR/block-chained-commands.sh"
DASH_HOOK="$HOOKS_DIR/block-inbox-em-dashes.sh"

FAILURES=0
COUNT=0

# run_bash_case <expect: block|pass> <name> <command>
run_bash_case() {
    local expect="$1"
    local name="$2"
    local cmd="$3"
    COUNT=$((COUNT + 1))
    local payload out
    payload=$(jq -n --arg cmd "$cmd" '{tool_name:"Bash", tool_input:{command:$cmd}}')
    out=$(printf '%s' "$payload" | "$CHAIN_HOOK")
    check_result "$expect" "$name" "$out"
}

# run_write_case <expect> <name> <tool> <file_path> <content>
run_write_case() {
    local expect="$1"
    local name="$2"
    local tool="$3"
    local path="$4"
    local content="$5"
    COUNT=$((COUNT + 1))
    local payload out field
    field="content"
    [ "$tool" = "Edit" ] && field="new_string"
    payload=$(jq -n --arg t "$tool" --arg p "$path" --arg c "$content" --arg f "$field" \
        '{tool_name:$t, tool_input:({file_path:$p} + {($f):$c})}')
    out=$(printf '%s' "$payload" | "$DASH_HOOK")
    check_result "$expect" "$name" "$out"
}

check_result() {
    local expect="$1"
    local name="$2"
    local out="$3"
    local got="pass"
    printf '%s' "$out" | grep -q '"decision":"block"' && got="block"
    if [ "$got" = "$expect" ]; then
        echo "  ok: $name"
    else
        echo "  FAIL: $name (expected $expect, got $got)"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "block-chained-commands.sh:"

run_bash_case pass "plain command" 'ls -la /tmp'

run_bash_case pass "multi-line quoted -m message with semicolons" 'git commit -m "Fix the sweeper

Line one has a clause; and a second clause.
Line two also carries a semicolon; like so."'

run_bash_case block "real && chain" 'git add -A && git commit -m "x"'

run_bash_case block "|| fallback chain" 'grep foo file.txt || echo missing'

run_bash_case block "bare semicolon chain" 'cd /tmp; ls'

run_bash_case block "command substitution" 'echo $(date)'

run_bash_case block "backtick substitution" 'echo `date`'

run_bash_case block "substitution inside double quotes" 'echo "today is $(date)"'

run_bash_case pass "find -exec terminator" "find . -name '*.tmp' -exec rm {} \\;"

run_bash_case block "heredoc into git commit via substitution" 'git commit -m "$(cat <<EOF
msg
EOF
)"'

run_bash_case block "heredoc piped to git commit -F" "git commit -F - <<'EOF'
msg body
EOF"

run_bash_case pass "semicolon inside quoted jq filter" "jq 'gsub(\"a;b\"; \"x\")' file.json"

run_bash_case pass "apostrophe inside double quotes" 'echo "do not panic; wait"'

run_bash_case pass "single pipe allowed" 'grep foo file.txt | head -5'

run_bash_case pass "escaped dollar-paren" 'echo "literal \$(not run)"'

run_bash_case pass "git commit with double-dash-message only" 'git commit -m "plain message"'

echo "block-inbox-em-dashes.sh:"

run_write_case block "em dash in inbox write" Write \
    "/Users/x/Legion/scratch/output/_inbox/2026-07-02-1-reply.md" \
    "This is fine — except it is not."

run_write_case block "en dash in inbox edit" Edit \
    "/Users/x/Legion/scratch/output/_inbox/2026-07-02-1-reply.md" \
    "Range talk – the lazy kind."

run_write_case block "spaced hyphen in inbox write" Write \
    "/Users/x/Legion/scratch/output/_inbox/2026-07-02-2-note.md" \
    "A pause - dressed as punctuation."

run_write_case pass "clean inbox write" Write \
    "/Users/x/Legion/scratch/output/_inbox/2026-07-02-3-clean.md" \
    "Plain prose, kebab-case-slug, and a hyphenated compound word."

run_write_case pass "em dash outside inbox" Write \
    "/Users/x/Legion/scratch/output/_framework-audit/notes.md" \
    "Internal notes — dashes allowed here."

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "ALL PASS ($COUNT cases)"
    exit 0
else
    echo "$FAILURES of $COUNT cases FAILED"
    exit 1
fi
