import Foundation
import Observation
import os

@Observable
final class ThemeStore {
    private(set) var themes: [Theme] = [.default]
    var current: Theme = .default {
        didSet { UserDefaults.standard.set(current.name, forKey: "selectedTheme") }
    }

    static let userThemesDirectory = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appending(path: "RealNotch/Themes")

    private let log = Logger(subsystem: "com.realnotch.app", category: "themes")
    private var watcher: DispatchSourceFileSystemObject?

    init() {
        try? FileManager.default.createDirectory(at: Self.userThemesDirectory, withIntermediateDirectories: true)
        seedBundledThemes()
        reload()
        watchUserThemes()
    }

    /// Copy the bundled skins into the user's Themes folder on first run, so they're
    /// visible and editable (they'd otherwise be locked inside the .app bundle).
    private func seedBundledThemes() {
        // Synchronized groups flatten resources to the bundle root, so look there
        // (subdirectory: nil). Note: passing a missing subdirectory returns an empty
        // array, not nil — so a `?? fallback` on it would never fire.
        let bundled = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        for src in bundled {
            let dest = Self.userThemesDirectory.appending(path: src.lastPathComponent)
            if !FileManager.default.fileExists(atPath: dest.path) {
                try? FileManager.default.copyItem(at: src, to: dest)
            }
        }
    }

    /// Install a skin from a `.json` file or a `.zip` of skins into the themes folder.
    func install(from url: URL) {
        if url.pathExtension.lowercased() == "json" {
            let dest = Self.userThemesDirectory.appending(path: url.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.copyItem(at: url, to: dest)
            reload()
            return
        }
        // .zip — extract and copy any .json skins out
        let tmp = FileManager.default.temporaryDirectory.appending(path: "rn-theme-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmp) }
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        task.arguments = ["-x", "-k", url.path, tmp.path]
        guard (try? task.run()) != nil else { return }
        task.waitUntilExit()
        if let en = FileManager.default.enumerator(at: tmp, includingPropertiesForKeys: nil) {
            for case let f as URL in en where f.pathExtension.lowercased() == "json" && !f.lastPathComponent.hasPrefix(".") {
                let dest = Self.userThemesDirectory.appending(path: f.lastPathComponent)
                try? FileManager.default.removeItem(at: dest)
                try? FileManager.default.copyItem(at: f, to: dest)
            }
        }
        reload()
    }

    func reload() {
        var loaded: [Theme] = [.default]
        let user = (try? FileManager.default.contentsOfDirectory(
            at: Self.userThemesDirectory, includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "json" }.sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []

        for url in user {
            do {
                let theme = try JSONDecoder().decode(Theme.self, from: Data(contentsOf: url))
                loaded.removeAll { $0.name == theme.name }
                loaded.append(theme)
            } catch {
                // Never crash on a bad skin — log and keep going.
                log.error("Invalid theme at \(url.lastPathComponent): \(error)")
            }
        }
        themes = loaded

        let selected = UserDefaults.standard.string(forKey: "selectedTheme")
        current = loaded.first { $0.name == (selected ?? current.name) } ?? .default
    }

    /// Live reload: skin authors edit a JSON in the themes folder and the notch restyles instantly.
    private func watchUserThemes() {
        let fd = open(Self.userThemesDirectory.path, O_EVTONLY)
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
