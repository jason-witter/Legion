#!/bin/bash
# PostToolUse hook (Agent, Read): surfaces watchdog alerts to the orchestrator.
# Reads every alert file in scratch/tmp/watchdog-alerts/, emits the contents
# as additionalContext, and deletes the files so an alert is delivered exactly
# once. Exits silently when there are no alerts.
#
# Counterpart to agent-watchdog-start.sh / agent-watchdog-monitor.sh, which
# write the alerts. Delivery lives in its own hook so the monitor stays a
# detached background process with no context channel of its own.
#
# Depends on: jq

# Consume stdin (hook contract); the payload itself is not needed.
cat > /dev/null

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
ALERT_DIR="${HOOK_DIR}/../scratch/tmp/watchdog-alerts"

[ -d "$ALERT_DIR" ] || exit 0

alerts=""
for f in "$ALERT_DIR"/*.json; do
    [ -f "$f" ] || continue
    alerts="${alerts}$(cat "$f")
"
    rm -f "$f"
done

[ -z "$alerts" ] && exit 0

message="Agent watchdog alerts (delivered once, source files consumed):
${alerts}"

jq -n --arg msg "$message" '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$msg}}'
exit 0
