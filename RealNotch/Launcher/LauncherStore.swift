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
        bindings.removeAll { $0.key == key } // one app per shortcut
        bindings.append(AppBinding(app: app, key: key, path: path))
        save(); register()
    }

    func remove(_ binding: AppBinding) {
        bindings.removeAll { $0.id == binding.id }
        save(); register()
    }

    /// Change a binding's shortcut in place (re-record).
    func updateKey(_ binding: AppBinding, to key: String) {
        guard let i = bindings.firstIndex(where: { $0.id == binding.id }) else { return }
        bindings.removeAll { $0.key == key && $0.id != binding.id }
        bindings[i].key = key
        save(); register()
    }

    /// The app already bound to this shortcut, if any (for conflict warnings).
    func appBound(to key: String) -> String? {
        bindings.first { $0.key == key }?.app
    }

    /// First free ⌥1…⌥9 for the quick-add flow in the notch.
    func nextFreeKey() -> String? {
        (1...9).map { "option+\($0)" }.first { key in !bindings.contains { $0.key == key } }
    }

    /// Quick-add from the notch: auto-assign the next ⌥number.
    func quickAdd(app: String, path: String?) {
        guard let key = nextFreeKey() else { return }
        add(app: app, key: key, path: path)
    }

    /// Focus the app — or hide it if it's already frontmost (toggle).
    func launch(_ binding: AppBinding) {
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == binding.app }) {
            if running.isActive {
                running.hide()
            } else {
                running.activate(options: [.activateAllWindows])
            }
        } else if let path = binding.path {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        } else {
            NSWorkspace.shared.launchApplication(binding.app)
        }
    }

    private func register() {
        hotkeys.unregisterAll()
        for b in bindings {
            hotkeys.register(b.key) { [weak self] in self?.launch(b) }
        }
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
