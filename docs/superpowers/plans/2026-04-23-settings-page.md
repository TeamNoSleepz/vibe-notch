# Settings Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Preferences window opened from the status menu, exposing color palette preset selection and Launch at Login toggle.

**Architecture:** New `SettingsWindowController.swift` holds `ColorPalette`, `AppPreferences`, the SwiftUI settings views, and the `NSWindow` controller. `main.swift` gets three small changes: `IndicatorPattern.color`/`nsColor` read from `AppPreferences`, `NotchView` observes `AppPreferences` for live redraws, and `AppDelegate` wires the "Preferences…" menu item.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit (`NSWindow`, `NSHostingView`), `ServiceManagement` (`SMAppService`), `UserDefaults`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `Sources/VibeNotch/SettingsWindowController.swift` | **Create** | `ColorPalette`, `AppPreferences`, `PaletteSwatchView`, `GeneralSettingsView`, `SettingsView`, `SettingsWindowController` |
| `Sources/VibeNotch/main.swift` | **Modify** | `IndicatorPattern.color`/`nsColor` → read from prefs; `NotchView` → add `@ObservedObject var prefs`; `AppDelegate` → add "Preferences…" menu item + handler |

---

## Task 1: Create `SettingsWindowController.swift` — data layer

**Files:**
- Create: `Sources/VibeNotch/SettingsWindowController.swift`

- [ ] **Step 1: Create the file with `ColorPalette` and `AppPreferences`**

```swift
// Sources/VibeNotch/SettingsWindowController.swift
import AppKit
import SwiftUI
import ServiceManagement

// MARK: - Color Palette

struct ColorPalette {
    let name: String
    let idle: Color
    let working: Color
    let awaiting: Color
}

// MARK: - App Preferences

final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    static let presets: [ColorPalette] = [
        ColorPalette(
            name: "Default",
            idle: Color(white: 0.35),
            working: Color(red: 1, green: 0.4, blue: 0),
            awaiting: Color(red: 1, green: 0.2, blue: 0.2)
        ),
        ColorPalette(
            name: "Neon",
            idle: Color(white: 0.4),
            working: Color(red: 0, green: 1, blue: 0.4),
            awaiting: Color(red: 0.4, green: 0.4, blue: 1)
        ),
        ColorPalette(
            name: "Pastel",
            idle: Color(white: 0.5),
            working: Color(red: 1, green: 0.75, blue: 0.5),
            awaiting: Color(red: 0.8, green: 0.6, blue: 1)
        ),
    ]

    @Published var paletteIndex: Int {
        didSet {
            UserDefaults.standard.set(paletteIndex, forKey: "vibenotch.paletteIndex")
        }
    }

    var selectedPalette: ColorPalette { Self.presets[paletteIndex] }

    private init() {
        let saved = UserDefaults.standard.integer(forKey: "vibenotch.paletteIndex")
        paletteIndex = saved < Self.presets.count ? saved : 0
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/nikpavic/vibe-notch && swift build 2>&1
```

Expected: build succeeds (new file has no entry point conflicts).

- [ ] **Step 3: Commit**

```bash
git add Sources/VibeNotch/SettingsWindowController.swift
git commit -m "feat: add ColorPalette and AppPreferences data layer"
```

---

## Task 2: Update `IndicatorPattern` to read colors from `AppPreferences`

**Files:**
- Modify: `Sources/VibeNotch/main.swift` — `IndicatorPattern.color` and `IndicatorPattern.nsColor`

Current code in `main.swift` (lines ~74–89):
```swift
var color: Color {
    switch self {
    case .idle:     return Color(white: 0.35)
    case .working:  return Color(red: 1, green: 0.4, blue: 0)
    case .awaiting: return Color(red: 1, green: 0.2, blue: 0.2)
    }
}

var nsColor: NSColor {
    switch self {
    case .idle:     return .tertiaryLabelColor
    case .working:  return NSColor(red: 1, green: 0.4, blue: 0, alpha: 1)
    case .awaiting: return NSColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
    }
}
```

- [ ] **Step 1: Replace both computed properties**

```swift
var color: Color {
    let p = AppPreferences.shared.selectedPalette
    switch self {
    case .idle:     return p.idle
    case .working:  return p.working
    case .awaiting: return p.awaiting
    }
}

var nsColor: NSColor {
    let p = AppPreferences.shared.selectedPalette
    switch self {
    case .idle:     return NSColor(p.idle)
    case .working:  return NSColor(p.working)
    case .awaiting: return NSColor(p.awaiting)
    }
}
```

`NSColor(Color)` is available on macOS 12+ — this project targets macOS 13+, so this is fine.

- [ ] **Step 2: Build**

```bash
cd /Users/nikpavic/vibe-notch && swift build 2>&1
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/VibeNotch/main.swift
git commit -m "feat: read indicator colors from AppPreferences"
```

---

## Task 3: Make `NotchView` observe `AppPreferences` for live palette redraws

**Files:**
- Modify: `Sources/VibeNotch/main.swift` — `NotchView`

Without this change, selecting a new palette in Preferences while Claude is idle (pattern unchanged) won't redraw the notch.

Current `NotchView` (around line 255):
```swift
struct NotchView: View {
    @ObservedObject var state = ClaudeState.shared
```

- [ ] **Step 1: Add `@ObservedObject var prefs`**

```swift
struct NotchView: View {
    @ObservedObject var state = ClaudeState.shared
    @ObservedObject var prefs = AppPreferences.shared
```

No other changes needed — SwiftUI will re-render the view when `prefs.paletteIndex` changes, and `IndicatorPattern.color` will read the new palette.

- [ ] **Step 2: Build**

```bash
cd /Users/nikpavic/vibe-notch && swift build 2>&1
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/VibeNotch/main.swift
git commit -m "feat: observe AppPreferences in NotchView for live palette redraws"
```

---

## Task 4: Build the SwiftUI settings views

**Files:**
- Modify: `Sources/VibeNotch/SettingsWindowController.swift` — append `PaletteSwatchView`, `GeneralSettingsView`, `SettingsView`

- [ ] **Step 1: Append the three views to `SettingsWindowController.swift`**

```swift
// MARK: - Palette Swatch

struct PaletteSwatchView: View {
    let palette: ColorPalette
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.12))
                    .frame(width: 64, height: 52)
                VStack(spacing: 5) {
                    Circle().fill(palette.idle).frame(width: 9, height: 9)
                    Circle().fill(palette.working).frame(width: 9, height: 9)
                    Circle().fill(palette.awaiting).frame(width: 9, height: 9)
                }
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    .frame(width: 64, height: 52)
            }
            Text(palette.name)
                .font(.caption)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .onTapGesture(perform: onTap)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject private var prefs = AppPreferences.shared
    @State private var launchAtLogin = false
    private let hasBundle = Bundle.main.bundleIdentifier != nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Palette")
                    .font(.headline)
                HStack(spacing: 12) {
                    ForEach(Array(AppPreferences.presets.enumerated()), id: \.offset) { index, palette in
                        PaletteSwatchView(
                            palette: palette,
                            isSelected: prefs.paletteIndex == index,
                            onTap: { prefs.paletteIndex = index }
                        )
                    }
                }
            }

            if hasBundle {
                Divider()
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 340)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }
}

// MARK: - Settings Root

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 380, height: 260)
    }
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/nikpavic/vibe-notch && swift build 2>&1
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/VibeNotch/SettingsWindowController.swift
git commit -m "feat: add settings SwiftUI views"
```

---

## Task 5: Add `SettingsWindowController` (the `NSWindow` owner)

**Files:**
- Modify: `Sources/VibeNotch/SettingsWindowController.swift` — append `SettingsWindowController`

- [ ] **Step 1: Append `SettingsWindowController` to the file**

```swift
// MARK: - Window Controller

final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func showWindow() {
        if window == nil {
            let w = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            w.title = "Preferences"
            w.isReleasedWhenClosed = false
            w.appearance = NSAppearance(named: .darkAqua)
            w.center()
            w.contentView = NSHostingView(rootView: SettingsView())
            window = w
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
```

- [ ] **Step 2: Build**

```bash
cd /Users/nikpavic/vibe-notch && swift build 2>&1
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/VibeNotch/SettingsWindowController.swift
git commit -m "feat: add SettingsWindowController NSWindow owner"
```

---

## Task 6: Wire "Preferences…" into the status menu

**Files:**
- Modify: `Sources/VibeNotch/main.swift` — `AppDelegate.buildStatusMenu()` + add `openPreferences()` action

- [ ] **Step 1: Add `openPreferences` handler to `AppDelegate`**

In `AppDelegate`, after `toggleLaunchAtLogin`:
```swift
@objc private func openPreferences() {
    SettingsWindowController.shared.showWindow()
}
```

- [ ] **Step 2: Add "Preferences…" item in `buildStatusMenu()`**

The current end of `buildStatusMenu()` looks like this (the `if Bundle.main.bundleIdentifier != nil` block adds a separator after Launch at Login, so there is already a separator before Quit when running as a bundle):

```swift
        if Bundle.main.bundleIdentifier != nil {
            // ... launchItem added here ...
            menu.addItem(.separator())
        }

        menu.addItem(NSMenuItem(
            title: "Quit VibeNotch",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
```

Replace that entire tail (from the `if Bundle.main.bundleIdentifier != nil` block to the end of the function) with:

```swift
        if Bundle.main.bundleIdentifier != nil {
            let launchItem = NSMenuItem(
                title: "Launch at Login",
                action: #selector(toggleLaunchAtLogin),
                keyEquivalent: ""
            )
            launchItem.target = self
            launchItem.tag = 3
            menu.addItem(launchItem)
        }

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit VibeNotch",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
```

This gives the menu layout: state → agent count → separator → (Launch at Login) → separator → Preferences… → separator → Quit.

- [ ] **Step 3: Build**

```bash
cd /Users/nikpavic/vibe-notch && swift build 2>&1
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add Sources/VibeNotch/main.swift
git commit -m "feat: add Preferences menu item to status menu"
```

---

## Task 7: Smoke test and install

- [ ] **Step 1: Run the binary directly**

```bash
cd /Users/nikpavic/vibe-notch && swift build && .build/debug/VibeNotch
```

Manual checks:
- Status menu has "Preferences…" item with ⌘, shortcut
- Clicking "Preferences…" opens a dark window titled "Preferences"
- Window shows "General" tab with 3 palette swatches (Default, Neon, Pastel)
- Clicking a swatch selects it (accent border appears)
- Notch indicator color changes immediately on swatch click
- Color persists after quitting and relaunching (UserDefaults)
- Launch at Login toggle works if running as app bundle (no crash if running raw binary)

- [ ] **Step 2: Install as app bundle and full test**

```bash
cd /Users/nikpavic/vibe-notch && ./setup.sh
```

Reopen `/Applications/VibeNotch.app` and repeat manual checks above. Confirm Launch at Login toggle functions.

- [ ] **Step 3: Final commit if any fixups were needed**

```bash
git add -p
git commit -m "fix: <describe any fixups from smoke test>"
```
