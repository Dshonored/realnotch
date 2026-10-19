import Foundation
import Observation

/// "Lid Closed" — keeps the Mac running with the lid shut (`pmset disablesleep`).
/// Power assertions can't stop clamshell sleep, so this needs root: the first use
/// asks for the admin password once and installs a sudoers rule limited to
/// exactly `pmset -a disablesleep 0|1`. Later toggles run silently via `sudo -n`.
/// Never persisted — turned off on quit so the Mac can't cook in a bag.
@MainActor
@Observable
final class LidAwakeManager {
    private(set) var isActive = false
    /// A toggle is in flight (the password prompt may be showing).
    private(set) var isBusy = false

    nonisolated static let sudoersPath = "/etc/sudoers.d/realnotch"

    init() {
        isActive = Self.readSleepDisabled()
    }

    func toggle() {
        set(!isActive)
    }

    func set(_ on: Bool) {
        guard !isBusy, on != isActive else { return }
        isBusy = true
        Task {
            let ok = await Task.detached { Self.apply(on) }.value
            isActive = ok ? on : Self.readSleepDisabled()
            isBusy = false
        }
    }

    /// Called from applicationWillTerminate — silent only, never prompts at quit.
    func deactivateForQuit() {
        guard isActive else { return }
        _ = Self.run("/usr/bin/sudo", ["-n", "/usr/bin/pmset", "-a", "disablesleep", "0"])
        isActive = false
    }

    // MARK: - System

    nonisolated private static func apply(_ on: Bool) -> Bool {
        let value = on ? "1" : "0"
        if run("/usr/bin/sudo", ["-n", "/usr/bin/pmset", "-a", "disablesleep", value]) { return true }
        // No sudoers rule yet (or it was removed) — install it with one admin prompt.
        let rule = "\(NSUserName()) ALL=(root) NOPASSWD: "
            + "/usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
        let script = """
        set -e
        tmp=$(/usr/bin/mktemp)
        printf '%s\\n' '\(rule)' > "$tmp"
        /usr/sbin/visudo -cf "$tmp" >/dev/null
        /bin/chmod 440 "$tmp"
        /usr/sbin/chown root:wheel "$tmp"
        /bin/mv "$tmp" \(sudoersPath)
        /usr/bin/pmset -a disablesleep \(value)
        """
        let prompt = "RealNotch needs your password once to keep the Mac awake with the lid closed."
        return run("/usr/bin/osascript", [
            "-e", "on run argv",
            "-e", "do shell script (item 1 of argv) with prompt (item 2 of argv) with administrator privileges",
            "-e", "end run",
            script, prompt,
        ])
    }

    nonisolated static func readSleepDisabled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return false }
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        return isSleepDisabled(pmsetOutput: output)
    }

    /// `pmset -g` lists " SleepDisabled\t\t1" when set; the line is absent or 0 otherwise.
    nonisolated static func isSleepDisabled(pmsetOutput: String) -> Bool {
        for line in pmsetOutput.split(whereSeparator: \.isNewline) {
            let parts = line.split(whereSeparator: \.isWhitespace)
            if parts.count >= 2, parts[0] == "SleepDisabled" { return parts[1] == "1" }
        }
        return false
    }

    @discardableResult
    nonisolated private static func run(_ tool: String, _ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return false }
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
}
