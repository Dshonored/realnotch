import Foundation
import Observation

@Observable
final class PluginStore {
    private(set) var plugins: [LuaPlugin] = []
    private(set) var output: [UUID: [PluginRow]] = [:]

    static let directory = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appending(path: "RealNotch/Plugins")

    private let engine = LuaEngine()
    private var watcher: DispatchSourceFileSystemObject?
    private var timer: Timer?

    /// Plugins that render — each gets its own notch tab.
    var tabPlugins: [LuaPlugin] { plugins.filter(\.hasRender) }

    init() {
        try? FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        reload()
        watch()
        // Re-run render() periodically so live plugins stay fresh.
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshAll()
        }
    }

    func runAction(_ ref: Int32) { engine.callRef(ref) }

    func reload() {
        engine.resetForReload()
        for p in plugins { engine.unload(p) }
        plugins = []
        output = [:]
        let files = (try? FileManager.default.contentsOfDirectory(
            at: Self.directory, includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "lua" }.sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
        for url in files {
            if let plugin = engine.load(path: url.path) { plugins.append(plugin) }
        }
        refreshAll()
    }

    func refreshAll() {
        for p in plugins { output[p.id] = engine.render(p) }
    }

    /// Install a plugin from a `.zip`: extract it and copy any `.lua` files into
    /// the plugins folder. Returns how many `.lua` files were installed.
    @discardableResult
    func installZip(at zipURL: URL) -> Int {
        let tmp = FileManager.default.temporaryDirectory.appending(path: "rn-plugin-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmp) }
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        task.arguments = ["-x", "-k", zipURL.path, tmp.path]
        guard (try? task.run()) != nil else { return 0 }
        task.waitUntilExit()
        guard task.terminationStatus == 0 else { return 0 }

        var installed = 0
        if let en = FileManager.default.enumerator(at: tmp, includingPropertiesForKeys: nil) {
            for case let f as URL in en where f.pathExtension == "lua" && !f.lastPathComponent.hasPrefix(".") {
                let dest = Self.directory.appending(path: f.lastPathComponent)
                try? FileManager.default.removeItem(at: dest)
                if (try? FileManager.default.copyItem(at: f, to: dest)) != nil { installed += 1 }
            }
        }
        reload()
        return installed
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
}
