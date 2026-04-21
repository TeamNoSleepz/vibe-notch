#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$REPO_DIR/hooks/vibe-notch-hook.sh"
SETTINGS="$HOME/.claude/settings.json"

echo "=== VibeNotch Uninstall ==="
echo ""

# 1. Remove hooks from ~/.claude/settings.json
if [ -f "$SETTINGS" ]; then
    echo "Removing Claude Code hooks..."
    python3 - "$SETTINGS" "$HOOK" << 'PYEOF'
import sys, json

settings_path = sys.argv[1]
hook_path = sys.argv[2]

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get("hooks", {})
removed = []

for event, entries in hooks.items():
    before = len(entries)
    hooks[event] = [
        entry for entry in entries
        if not any(h.get("command", "").startswith(hook_path) for h in entry.get("hooks", []))
    ]
    if len(hooks[event]) < before:
        removed.append(event)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

if removed:
    print(f"  Removed hooks for: {', '.join(removed)}")
else:
    print("  No VibeNotch hooks found.")
PYEOF
else
    echo "  No ~/.claude/settings.json found — nothing to do."
fi

# 2. Remove the app
if [ -d "/Applications/VibeNotch.app" ]; then
    echo "Removing /Applications/VibeNotch.app..."
    rm -rf "/Applications/VibeNotch.app"
    echo "  Done."
else
    echo "  VibeNotch.app not found in /Applications."
fi

# 3. Remove Launch at Login if registered
if python3 -c "import subprocess; subprocess.run(['osascript', '-e', ''], check=True)" 2>/dev/null; then
    :
fi

# 4. Clean up tmp files
rm -f /tmp/vibe-notch /tmp/vibe-notch-log

echo ""
echo "=== Done. VibeNotch has been removed. ==="
