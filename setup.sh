#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$REPO_DIR/hooks/notch-agent-hook.py"
SETTINGS="$HOME/.claude/settings.json"

echo "=== NotchAgent Setup ==="
echo ""

# 1. Install the app
echo "Step 1: Building and installing NotchAgent.app..."
"$REPO_DIR/scripts/install.sh"
echo ""

# 2. Wire up Claude Code hooks
echo "Step 2: Installing Claude Code hooks..."

mkdir -p "$HOME/.claude"

python3 - "$SETTINGS" "$HOOK" << 'PYEOF'
import sys, json, os

settings_path = sys.argv[1]
hook_path = sys.argv[2]

if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)
else:
    settings = {}

hooks = settings.setdefault("hooks", {})

# Remove old bash hook entries (notch-agent-hook.sh)
for event in list(hooks.keys()):
    if isinstance(hooks[event], list):
        cleaned = []
        for entry in hooks[event]:
            if isinstance(entry, dict):
                entry_hooks = [h for h in entry.get("hooks", [])
                               if "notch-agent-hook.sh" not in h.get("command", "")]
                if entry_hooks:
                    entry_copy = dict(entry)
                    entry_copy["hooks"] = entry_hooks
                    cleaned.append(entry_copy)
            else:
                cleaned.append(entry)
        if cleaned:
            hooks[event] = cleaned
        else:
            del hooks[event]

command = f"python3 {hook_path}"

# Events where tool context applies — use matcher: "*"
tool_events = ["PreToolUse", "PostToolUse", "PermissionRequest", "Notification"]
# Events with no tool context — omit matcher
session_events = ["UserPromptSubmit", "Stop", "SessionStart", "SessionEnd"]

def already_installed(entries):
    return any(
        "notch-agent-hook" in h.get("command", "")
        for entry in entries
        for h in entry.get("hooks", [])
    )

added = []
for event in tool_events:
    entries = hooks.setdefault(event, [])
    if not already_installed(entries):
        entries.append({"matcher": "*", "hooks": [{"type": "command", "command": command}]})
        added.append(event)

for event in session_events:
    entries = hooks.setdefault(event, [])
    if not already_installed(entries):
        entries.append({"hooks": [{"type": "command", "command": command}]})
        added.append(event)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

if added:
    print(f"  Added hooks for: {', '.join(added)}")
else:
    print("  Hooks already installed — nothing to do.")
PYEOF

echo ""
echo "=== Done! ==="
echo ""
echo "Open /Applications/NotchAgent.app to start."
echo "You'll see a ● dot in your menu bar tracking Claude's state."
echo "Click it to enable 'Launch at Login'."
