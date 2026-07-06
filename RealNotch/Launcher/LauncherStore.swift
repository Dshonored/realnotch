import AppKit
import Foundation
import Observation

struct AppBinding: Codable, Identifiable, Equatable {
    var id = UUID()
    var app: String    // display name, e.g. "Google Chrome"
    var key: String    // canonical, e.g. "option+1"
    var path: String?  // .app path — for the real icon and reliable launching

    /// The app's real Finder icon.
    var icon: NSImage? {
        if let path { return NSWorkspace.shared.icon(forFile: path) }
        if let resolved = NSWorkspace.shared.fullPath(forApplication: app) {
            return NSWorkspace.shared.icon(forFile: resolved)
        }
        return nil
    }
}

/// The built-in App Launcher: user-configured global hotkeys that launch/focus apps.
/// Bindings are added/edited in Settings and persisted; hotkeys register via Carbon.
@Observable
final class LauncherStore {
    private(set) var bindings: [AppBinding] = []

    private let url: URL
    private let hotkeys = HotKeyManager()

    init(storageDirectory: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appending(path: "RealNotch")
    ) {
        url = storageDirectory.appending(path: "launcher.json")
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        load()
        register()
    }

    func add(app: String, key: String, path: String? = nil) {
        // Replace any existing binding on the same key.
        bindings.removeAll { $0.key == key }
        bindings.append(AppBinding(app: app, key: key, path: path))
        save(); register()
    }

    func remove(_ binding: AppBinding) {
        bindings.removeAll { $0.id == binding.id }
        save(); register()
    }

    func launch(_ binding: AppBinding) {
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == binding.app }) {
            running.activate(options: [.activateAllWindows])
        } else if let path = binding.path {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        } else {
            NSWorkspace.shared.launchApplication(binding.app)
        }
    }

    private func register() {
        hotkeys.setBindings(bindings.map { .init(key: $0.key, app: $0.app) })
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode([AppBinding].self, from: data) else { return }
        bindings = saved
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(bindings) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
