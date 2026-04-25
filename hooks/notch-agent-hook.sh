#!/bin/bash
# Called by Claude Code hooks (configured in ~/.claude/settings.json).
# Writes the current agent state to /tmp/notch-agent (read by the NotchAgent app)
# and appends a human-readable line to /tmp/notch-agent-log.
#
# Usage: notch-agent-hook.sh <event>
# Events: user-prompt | pre-tool | post-tool | stop | session-start | permission

EVENT="$1"
LOG=/tmp/notch-agent-log
TS=$(date "+%H:%M:%S")

case "$EVENT" in
  user-prompt)
    echo "thinking" > /tmp/notch-agent
    ;;
  pre-tool)
    echo "tool" > /tmp/notch-agent
    printf '%s  Working\n' "$TS" >> "$LOG"
    ;;
  post-tool)
    echo "thinking" > /tmp/notch-agent
    printf '%s  Thinking\n' "$TS" >> "$LOG"
    ;;
  stop)
    INPUT=$(cat)
    OUTPUT=$(printf '%s' "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('output',''))" 2>/dev/null || echo "")
    if printf '%s' "$OUTPUT" | grep -qiE "\?[[:space:]]*$|should I|shall I|do you want|would you like|please confirm|want me to|proceed\?|continue\?"; then
      echo "awaiting" > /tmp/notch-agent
      printf '%s  Awaiting\n' "$TS" >> "$LOG"
    else
      echo "idle" > /tmp/notch-agent
      printf '%s  Done\n' "$TS" >> "$LOG"
    fi
    ;;
  session-start)
    echo "idle" > /tmp/notch-agent
    ;;
  permission)
    echo "awaiting" > /tmp/notch-agent
    printf '%s  Permission\n' "$TS" >> "$LOG"
    ;;
esac
