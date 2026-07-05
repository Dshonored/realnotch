import AppKit
import Foundation
import Observation

@Observable
final class AgentStore {
    private(set) var agents: [Agent] = []

    /// Sessions that go quiet longer than this are considered dead and dropped
    /// (covers cases where SessionEnd never fired — crash, kill -9, etc.).
    private let staleAfter: TimeInterval = 3 * 3600

    static let directory = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appending(path: "RealNotch/Agents")

    private var watcher: DispatchSourceFileSystemObject?
    private var timer: Timer?

    var waitingCount: Int { agents.filter { $0.state == .waiting }.count }
    var activeCount: Int { agents.count }

    init() {
        try? FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        reload()
        watch()
        // Prune stale sessions periodically even when no file events arrive.
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.reload()
        }
    }

    func reload() {
        let now = Date().timeIntervalSince1970
        let files = (try? FileManager.default.contentsOfDirectory(
            at: Self.directory, includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "json" } ?? []

        var loaded: [Agent] = []
        for url in files {
            guard let data = try? Data(contentsOf: url),
                  let agent = try? JSONDecoder().decode(Agent.self, from: data) else { continue }
            if now - agent.updatedAt > staleAfter {
                try? FileManager.default.removeItem(at: url)
                continue
            }
            loaded.append(agent)
        }
        // Waiting first, then working, then idle; newest within each group.
        agents = loaded.sorted {
            $0.state.order == $1.state.order ? $0.updatedAt > $1.updatedAt : $0.state.order < $1.state.order
        }
    }

    private func watch() {
        let fd = open(Self.directory.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .rename, .delete], queue: .main
        )
        source.setEventHandler { [weak self] in self?.reload() }
        source.setCancelHandler { close(fd) }
        source.resume()
        watcher = source
    }

    /// Bring the terminal forward. Window-precise focus isn't possible from a hook
    /// (no TTY/window id), so we activate Ghostty (or the frontmost terminal).
    func focusTerminal(_ agent: Agent) {
        let ghostty = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.mitchellh.ghostty"
        ).first
        if let ghostty {
            ghostty.activate(options: [.activateAllWindows])
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Ghostty.app"))
        }
    }
}
