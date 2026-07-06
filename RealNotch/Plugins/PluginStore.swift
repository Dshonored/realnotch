import Foundation
import Observation
import os

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

    init() {
        try? FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        seedExample()
        reload()
        watch()
        // Re-run render() periodically so live plugins (clock, clipboard…) stay fresh.
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshAll()
        }
    }

    func reload() {
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

    /// Drop a starter plugin in on first run so people have a working example to copy.
    private func seedExample() {
        let dest = Self.directory.appending(path: "example.lua")
        guard !FileManager.default.fileExists(atPath: dest.path) else { return }
        let script = """
        -- RealNotch example plugin. Copy this file to make your own.
        -- Return a table with: name, icon (an SF Symbol), and render().
        -- render() returns a list of rows: { title = "...", subtitle = "..." }
        -- Host API: notch.clipboard() -> string, notch.time() -> unix seconds
        return {
          name = "Hello Lua",
          icon = "puzzlepiece.extension",
          render = function()
            local clip = notch.clipboard()
            return {
              { title = "Plugins work!", subtitle = "edit example.lua to change this" },
              { title = "Clipboard length", subtitle = tostring(#clip) .. " characters" },
              { title = "Math from Lua", subtitle = "2^10 = " .. tostring(2 ^ 10) },
            }
          end
        }
        """
        try? script.write(to: dest, atomically: true, encoding: .utf8)
    }
}
