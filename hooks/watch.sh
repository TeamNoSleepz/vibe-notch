#!/bin/bash
LOG=/tmp/notch-agent-log
touch "$LOG"

echo "┌─────────────────────────────────────────────┐"
echo "│         Claude Code — Live Activity          │"
echo "└─────────────────────────────────────────────┘"
echo "  ◐ thinking   ⚙ tool use   ✓ done   ◉ awaiting"
echo ""

tail -n 20 -f "$LOG"
