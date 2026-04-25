#!/usr/bin/env python3
"""
NotchAgent hook — sends session state to NotchAgent.app via Unix socket.
Fire-and-forget: exits immediately after sending, no bidirectional handling.
"""
import json
import os
import socket
import sys

SOCKET_PATH = "/tmp/notch-agent.sock"


def send_event(state):
    try:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.settimeout(2)
        sock.connect(SOCKET_PATH)
        sock.sendall(json.dumps(state).encode())
        sock.close()
    except (socket.error, OSError):
        pass


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    event = data.get("hook_event_name", "")
    session_id = data.get("session_id", "unknown")
    cwd = data.get("cwd", "")

    state = {
        "session_id": session_id,
        "cwd": cwd,
        "event": event,
        "pid": os.getppid(),
    }

    if event == "PreToolUse":
        state["status"] = "running_tool"
        state["tool"] = data.get("tool_name")
    elif event in ("UserPromptSubmit", "PostToolUse", "PostToolUseFailure",
                   "SubagentStart", "SubagentStop", "PreCompact", "PostCompact"):
        state["status"] = "processing"
    elif event == "PermissionRequest":
        state["status"] = "waiting_for_approval"
    elif event == "Notification":
        nt = data.get("notification_type")
        if nt == "permission_prompt":
            sys.exit(0)  # PermissionRequest hook handles this with better info
        state["status"] = "waiting_for_input" if nt == "idle_prompt" else "processing"
        state["notification_type"] = nt
    elif event in ("Stop", "StopFailure", "SessionStart"):
        state["status"] = "waiting_for_input"
    elif event == "SessionEnd":
        state["status"] = "ended"
    else:
        state["status"] = "unknown"

    send_event(state)


if __name__ == "__main__":
    main()
