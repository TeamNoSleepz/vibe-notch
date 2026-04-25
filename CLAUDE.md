# NotchAgent

## Install

**Requirements:** macOS 13+, Xcode Command Line Tools (`xcode-select --install`)

```bash
git clone https://github.com/YOUR_USERNAME/notch-agent
cd notch-agent
./setup.sh
```

Then open `/Applications/NotchAgent.app`. A `●` dot appears in the menu bar — click it to enable **Launch at Login**.

`setup.sh` does two things:
1. Builds and installs `NotchAgent.app` to `/Applications`
2. Adds Claude Code hooks to `~/.claude/settings.json` so the dot tracks Claude's state

## Development

```bash
swift build && .build/debug/NotchAgent
```

Or use the dev script for auto-rebuild on file changes:

```bash
./dev.sh
```
