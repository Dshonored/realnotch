import AppKit

struct AppInfo: Identifiable, Hashable {
    let name: String
    let path: String
    var id: String { path }
    var icon: NSImage { NSWorkspace.shared.icon(forFile: path) }
}

enum InstalledApps {
    /// Apps from the standard locations, running apps first, de-duplicated by name.
    static func all() -> [AppInfo] {
        var seen = Set<String>()
        var apps: [AppInfo] = []

        func add(_ name: String, _ path: String) {
            guard !name.isEmpty, seen.insert(name).inserted else { return }
            apps.append(AppInfo(name: name, path: path))
        }

        // Running apps first — most likely what you want to bind.
        for app in NSWorkspace.shared.runningApplications
            where app.activationPolicy == .regular {
            if let name = app.localizedName, let url = app.bundleURL {
                add(name, url.path)
            }
        }

        let dirs = ["/Applications", "/System/Applications",
                    NSHomeDirectory() + "/Applications"]
        for dir in dirs {
            let contents = (try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? []
            for item in contents where item.hasSuffix(".app") {
                let path = dir + "/" + item
                let name = (Bundle(path: path)?.infoDictionary?["CFBundleName"] as? String)
                    ?? String(item.dropLast(4))
                add(name, path)
            }
        }
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
