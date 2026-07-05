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
        reload()
        watchUserThemes()
    }

    func reload() {
        var loaded: [Theme] = [.default]
        // Xcode's synchronized groups may flatten resources into the bundle root.
        let bundled = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Themes")
            ?? Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        let user = (try? FileManager.default.contentsOfDirectory(
            at: Self.userThemesDirectory, includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "json" } ?? []

        for url in bundled + user {
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
