import AppKit
import Foundation
import Observation

/// A GitHub release as returned by `GET /repos/{owner}/{repo}/releases/latest`.
/// Only the fields the updater needs are decoded.
struct Release: Equatable, Decodable, Sendable {
    struct Asset: Equatable, Decodable, Sendable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    let tagName: String
    let name: String?
    let body: String?
    let htmlURL: URL
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name, body
        case htmlURL = "html_url"
        case draft, prerelease, assets
    }

    /// The tag without its leading "v" — "v0.8.1" → "0.8.1".
    var version: String { Updater.stripPrefix(tagName) }

    /// The downloadable disk image, e.g. `RealNotch-0.8.1.dmg`.
    var dmgAsset: Asset? { assets.first { $0.name.lowercased().hasSuffix(".dmg") } }
}

/// In-app updater backed by GitHub Releases. The app is ad-hoc signed and not
/// sandboxed, so instead of Sparkle it downloads the release DMG, stages the new
/// bundle, and hands the swap to a detached shell script that runs after we quit.
@MainActor
@Observable
final class Updater {
    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case available(Release)
        case downloading(progress: Double)
        case installing
        case failed(String)
    }

    static let autoCheckKey = "autoCheckUpdates"
    static let skippedVersionKey = "skippedUpdateVersion"
    nonisolated static let latestReleaseURL =
        URL(string: "https://api.github.com/repos/Dshonored/realnotch/releases/latest")!

    private(set) var state: State = .idle
    private(set) var lastChecked: Date?

    let currentVersion: String =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

    /// True while a check, download, or install is in flight — nothing may overlap it.
    var isBusy: Bool {
        switch state {
        case .checking, .downloading, .installing: return true
        default: return false
        }
    }

    @ObservationIgnored private var schedule: Task<Void, Never>?

    init() {
        UserDefaults.standard.register(defaults: [Self.autoCheckKey: true])
    }

    private var autoCheckEnabled: Bool { UserDefaults.standard.bool(forKey: Self.autoCheckKey) }

    // MARK: - Scheduling

    /// Checks shortly after launch, then once a day. The toggle is read on every
    /// tick, so flipping it in Settings takes effect without a restart.
    func start() {
        guard schedule == nil else { return }
        schedule = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            while !Task.isCancelled {
                guard let self else { return }
                if self.autoCheckEnabled { await self.performCheck(userInitiated: false, silent: false) }
                try? await Task.sleep(for: .seconds(24 * 60 * 60))
            }
        }
    }

    // MARK: - Checking

    /// - Parameters:
    ///   - userInitiated: `true` for an explicit request (menu or Settings). Automatic
    ///     checks only alert for a version the user hasn't skipped.
    ///   - silent: `true` updates `state` only (Settings shows it inline); otherwise a
    ///     user-initiated check alerts for every outcome.
    func check(userInitiated: Bool, silent: Bool = false) {
        guard !isBusy else { return }
        Task { await performCheck(userInitiated: userInitiated, silent: silent) }
    }

    private func performCheck(userInitiated: Bool, silent: Bool) async {
        guard !isBusy else { return }
        state = .checking
        do {
            let release = try await Self.fetchLatestRelease()
            lastChecked = Date()
            if !release.draft, !release.prerelease, Self.isNewer(release.version, than: currentVersion) {
                state = .available(release)
                guard !silent else { return }
                let skipped = UserDefaults.standard.string(forKey: Self.skippedVersionKey)
                if userInitiated || release.version != skipped { presentAvailableAlert(release) }
            } else {
                state = .upToDate
                if userInitiated, !silent {
                    alert("RealNotch is up to date",
                          "Version \(currentVersion) is the latest version available.")
                }
            }
        } catch {
            lastChecked = Date()
            state = .failed(error.localizedDescription)
            if userInitiated, !silent {
                alert("Couldn't check for updates", error.localizedDescription)
            }
        }
    }

    nonisolated static func fetchLatestRelease() async throws -> Release {
        var request = URLRequest(url: latestReleaseURL, timeoutInterval: 30)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("RealNotch", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw UpdateError("GitHub sent an unexpected response.")
        }
        switch http.statusCode {
        case 200: return try decodeRelease(data)
        case 404: throw UpdateError("No published release was found.")
        case 403, 429: throw UpdateError("GitHub rate limit reached. Try again later.")
        default: throw UpdateError("GitHub returned HTTP \(http.statusCode).")
        }
    }

    nonisolated static func decodeRelease(_ data: Data) throws -> Release {
        try JSONDecoder().decode(Release.self, from: data)
    }

    // MARK: - Version comparison

    nonisolated static func stripPrefix(_ version: String) -> String {
        let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first == "v" || first == "V" else { return trimmed }
        return String(trimmed.dropFirst())
    }

    /// Numeric dot components; pre-release/build suffixes ("-beta", "+3") are dropped
    /// and any non-numeric component counts as 0.
    nonisolated static func components(_ version: String) -> [Int] {
        let core = stripPrefix(version).split(
            maxSplits: 1, omittingEmptySubsequences: false, whereSeparator: { $0 == "-" || $0 == "+" }
        ).first ?? ""
        return core.split(separator: ".", omittingEmptySubsequences: false)
            .map { Int($0).map { max(0, $0) } ?? 0 }
    }

    /// `true` when `remote` is strictly newer than `local`. Missing components are 0,
    /// so "1.0" == "1.0.0".
    nonisolated static func isNewer(_ remote: String, than local: String) -> Bool {
        let r = components(remote), l = components(local)
        for i in 0..<max(r.count, l.count) {
            let a = i < r.count ? r[i] : 0
            let b = i < l.count ? l[i] : 0
            if a != b { return a > b }
        }
        return false
    }

    // MARK: - Installing

    func install(_ release: Release) {
        guard !isBusy else { return }
        Task { await performInstall(release) }
    }

    private func performInstall(_ release: Release) async {
        let appURL = Bundle.main.bundleURL
        let parent = appURL.deletingLastPathComponent()
        let fm = FileManager.default
        guard fm.isWritableFile(atPath: parent.path), fm.isWritableFile(atPath: appURL.path) else {
            failInstall(
                "RealNotch can't replace itself in \(parent.path) because that folder isn't writable. "
                    + "Download the update from the release page and install it manually.",
                release: release, openReleasePage: true
            )
            return
        }
        guard let asset = release.dmgAsset else {
            failInstall("The release has no .dmg to download.", release: release, openReleasePage: true)
            return
        }

        let workDir = fm.temporaryDirectory.appending(path: "RealNotchUpdate-\(UUID().uuidString)")
        do {
            try fm.createDirectory(at: workDir, withIntermediateDirectories: true)

            state = .downloading(progress: 0)
            let dmg = try await Self.download(asset.browserDownloadURL,
                                              to: workDir.appending(path: asset.name)) { [weak self] p in
                Task { @MainActor in
                    guard let self, case .downloading = self.state else { return }
                    self.state = .downloading(progress: p)
                }
            }

            state = .installing
            let bundleID = Bundle.main.bundleIdentifier ?? "com.realnotch.app"
            let staged = try await Task.detached {
                try Self.stage(dmg: dmg, in: workDir, expectedBundleID: bundleID)
            }.value

            try Self.launchSwapScript(pid: ProcessInfo.processInfo.processIdentifier,
                                      installed: appURL, staged: staged, workDir: workDir)
            NSApp.terminate(nil)
        } catch {
            try? fm.removeItem(at: workDir)
            failInstall("Update failed: \(error.localizedDescription)", release: release, openReleasePage: false)
        }
    }

    private func failInstall(_ message: String, release: Release, openReleasePage: Bool) {
        state = .failed(message)
        alert("Couldn't install RealNotch \(release.version)", message)
        if openReleasePage { NSWorkspace.shared.open(release.htmlURL) }
    }

    /// Downloads to `destination`, reporting fractional progress (throttled to 1% steps).
    nonisolated private static func download(
        _ url: URL, to destination: URL, progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.setValue("RealNotch", forHTTPHeaderField: "User-Agent")
        let observer = DownloadProgressObserver(onProgress: progress)
        let (tempFile, response) = try await URLSession.shared.download(for: request, delegate: observer)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw UpdateError("Download failed with HTTP \(http.statusCode).")
        }
        try FileManager.default.moveItem(at: tempFile, to: destination)
        progress(1)
        return destination
    }

    /// Mounts the DMG, copies RealNotch.app out to a staging folder, unmounts, strips
    /// quarantine, and verifies the bundle identity. Blocking — call off the main actor.
    nonisolated private static func stage(dmg: URL, in workDir: URL, expectedBundleID: String) throws -> URL {
        let fm = FileManager.default
        let mount = workDir.appending(path: "mount")
        let stagingDir = workDir.appending(path: "staging")
        try fm.createDirectory(at: mount, withIntermediateDirectories: true)
        try fm.createDirectory(at: stagingDir, withIntermediateDirectories: true)

        try run("/usr/bin/hdiutil", ["attach", "-nobrowse", "-readonly", "-noautoopen",
                                     "-mountpoint", mount.path, dmg.path])
        var mounted = true
        defer {
            if mounted, (try? run("/usr/bin/hdiutil", ["detach", mount.path])) == nil {
                _ = try? run("/usr/bin/hdiutil", ["detach", "-force", mount.path])
            }
        }

        var source = mount.appending(path: "RealNotch.app")
        if !fm.fileExists(atPath: source.path) {
            let apps = (try? fm.contentsOfDirectory(at: mount, includingPropertiesForKeys: nil))?
                .filter { $0.pathExtension == "app" } ?? []
            guard let first = apps.first else { throw UpdateError("The disk image doesn't contain RealNotch.app.") }
            source = first
        }

        let staged = stagingDir.appending(path: "RealNotch.app")
        try run("/usr/bin/ditto", [source.path, staged.path])
        try run("/usr/bin/hdiutil", ["detach", mount.path])
        mounted = false

        // Exits non-zero when nothing was quarantined — that's fine.
        _ = try? run("/usr/bin/xattr", ["-dr", "com.apple.quarantine", staged.path])

        let plist = NSDictionary(contentsOf: staged.appending(path: "Contents/Info.plist"))
        guard let stagedID = plist?["CFBundleIdentifier"] as? String, stagedID == expectedBundleID else {
            throw UpdateError("The downloaded app isn't RealNotch (bundle identifier mismatch).")
        }
        return staged
    }

    /// Starts a detached script that waits for this process to exit, swaps the bundle
    /// (keeping a backup until the move succeeds), and relaunches. Paths are passed as
    /// positional arguments, never interpolated into the script.
    nonisolated private static func launchSwapScript(pid: Int32, installed: URL, staged: URL, workDir: URL) throws {
        let script = """
        pid="$1"; old="$2"; new="$3"; work="$4"
        n=0
        while kill -0 "$pid" 2>/dev/null; do
          n=$((n + 1)); [ "$n" -gt 300 ] && exit 1
          sleep 0.2
        done
        backup="$old.update-backup"
        rm -rf "$backup"
        mv "$old" "$backup" || { open "$old"; exit 1; }
        if mv "$new" "$old"; then
          rm -rf "$backup"
        else
          rm -rf "$old"; mv "$backup" "$old"
        fi
        rm -rf "$work"
        open "$old"
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nohup")
        process.arguments = ["/bin/sh", "-c", script, "realnotch-update",
                             String(pid), installed.path, staged.path, workDir.path]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    @discardableResult
    nonisolated private static func run(_ tool: String, _ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let name = (tool as NSString).lastPathComponent
            let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
            throw UpdateError("\(name) failed (\(process.terminationStatus))" + (detail.isEmpty ? "." : ": \(detail)"))
        }
        return output
    }

    // MARK: - Alerts

    private func presentAvailableAlert(_ release: Release) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "RealNotch \(release.version) is available"
        var info = "You have version \(currentVersion)."
        let notes = (release.body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty {
            info += "\n\n" + (notes.count > 600 ? String(notes.prefix(600)) + "…" : notes)
        }
        alert.informativeText = info
        alert.addButton(withTitle: "Install Update")
        alert.addButton(withTitle: "Later")
        alert.addButton(withTitle: "Skip This Version")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            install(release)
        case .alertThirdButtonReturn:
            UserDefaults.standard.set(release.version, forKey: Self.skippedVersionKey)
        default:
            break
        }
    }

    private func alert(_ title: String, _ message: String) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

struct UpdateError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

/// Bridges the download task's `Progress` to a callback. `didCreateTask` hands us the
/// task created by `URLSession.download(for:delegate:)`.
private final class DownloadProgressObserver: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let onProgress: @Sendable (Double) -> Void
    private let lock = NSLock()
    private var observation: NSKeyValueObservation?
    private var lastReported = -1.0

    init(onProgress: @escaping @Sendable (Double) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            self?.report(progress.fractionCompleted)
        }
        lock.withLock { self.observation = observation }
    }

    private func report(_ fraction: Double) {
        let value = min(max(fraction, 0), 1)
        let shouldReport = lock.withLock {
            guard value - lastReported >= 0.01 else { return false }
            lastReported = value
            return true
        }
        if shouldReport { onProgress(value) }
    }
}
