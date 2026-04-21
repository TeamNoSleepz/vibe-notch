import SwiftUI
import Combine

final class ClaudeState: ObservableObject {
    static let shared = ClaudeState()
    @Published var pattern: IndicatorPattern = .idle
    @Published var agentCount: Int = 0

    // Written by Claude Code hooks (hooks/vibe-notch-hook.sh) on every event
    private let statePath = "/tmp/vibe-notch"
    private var cancellable: AnyCancellable?
    private var agentCancellable: AnyCancellable?

    func start() {
        // Polling instead of FSEvents — simpler, and 300ms is fast enough for a visual indicator
        cancellable = Timer.publish(every: 0.3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.poll() }
        poll()

        agentCancellable = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.pollAgentCount() }
        pollAgentCount()
    }

    private func poll() {
        guard let raw = try? String(contentsOfFile: statePath, encoding: .utf8) else {
            if pattern != .idle { pattern = .idle }
            return
        }
        let next: IndicatorPattern
        switch raw.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "thinking", "tool": next = .working
        case "awaiting":         next = .awaiting
        default:                 next = .idle
        }
        // Guard against redundant assignments — each @Published write triggers a SwiftUI redraw
        if pattern != next { pattern = next }
    }

    private func pollAgentCount() {
        // pgrep spawns a subprocess; dispatch to avoid blocking the main thread every 2s
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let count = Self.countRunningAgents()
            DispatchQueue.main.async {
                if self?.agentCount != count { self?.agentCount = count }
            }
        }
    }

    private static func countRunningAgents() -> Int {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        // -x = exact name match; without it "claude-helper" and similar would be counted too
        task.arguments = ["-x", "claude"]
        let pipe = Pipe()
        task.standardOutput = pipe
        // Discard stderr — pgrep exits 1 with no output when no processes match, which is normal
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        // Each non-empty line is one PID
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
    }
}
