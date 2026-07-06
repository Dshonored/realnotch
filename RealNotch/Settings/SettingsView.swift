import AppKit
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var themeStore: ThemeStore
    let clipboard: ClipboardStore
    let launcher: LauncherStore
    let plugins: PluginStore

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var maxItems = 200
    @State private var newKey = ""
    @State private var newApp = ""
    @State private var newPath: String?
    @AppStorage("openOnHover") private var openOnHover = true
    @AppStorage("hoverDelayMs") private var hoverDelayMs = 300

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) {
                        do {
                            if launchAtLogin {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }

                Stepper("History size: \(maxItems)", value: $maxItems, in: 10...1000, step: 10)
                    .onChange(of: maxItems) { clipboard.maxItems = maxItems }

                Button("Clear History") { clipboard.clear() }
            }

            Section("Notch") {
                Toggle("Open on hover", isOn: $openOnHover)
                if openOnHover {
                    Stepper("Hover delay: \(hoverDelayMs) ms", value: $hoverDelayMs, in: 0...1000, step: 50)
                    Text("Longer delay means fewer accidental opens when reaching for tabs or the menu bar. You can always click the notch to open it instantly.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Click the notch to open it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("App Launcher") {
                ForEach(launcher.bindings) { b in
                    HStack {
                        Text(Shortcut.display(b.key))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .frame(minWidth: 44, alignment: .leading)
                        if let icon = b.icon {
                            Image(nsImage: icon).resizable().frame(width: 18, height: 18)
                        }
                        Text(b.app)
                        Spacer()
                        Button(role: .destructive) { launcher.remove(b) } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    ShortcutRecorder(key: $newKey)
                    TextField("App name", text: $newApp)
                    Button("Choose…") {
                        if let (n, p) = pickApp() { newApp = n; newPath = p }
                    }
                    Button("Add") { addBinding() }
                        .disabled(newKey.isEmpty || newApp.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Text("Record a shortcut and pick an app — the hotkey works everywhere.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Plugins") {
                Button("Install Plugin (.zip)…") { installPlugin() }
                Button("Open Plugins Folder") { NSWorkspace.shared.open(PluginStore.directory) }
                Text("Plugins are Lua files — each with a render() gets its own notch tab. Install a .zip or drop .lua files in the folder.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Theme") {
                Picker("Skin", selection: $themeStore.current) {
                    ForEach(themeStore.themes) { theme in
                        Text("\(theme.name) — \(theme.author)").tag(theme)
                    }
                }

                Button("Install Theme (.json / .zip)…") { installTheme() }
                Button("Open Themes Folder") {
                    NSWorkspace.shared.open(ThemeStore.userThemesDirectory)
                }
                Text("Install a skin, or drop .json files in the folder — changes apply live.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        // A grouped Form has no intrinsic height in an NSHostingController, so the
        // window collapses to its title bar without an explicit size.
        .frame(width: 480, height: 620)
        .onAppear { maxItems = clipboard.maxItems }
    }

    private func addBinding() {
        launcher.add(app: newApp.trimmingCharacters(in: .whitespaces), key: newKey, path: newPath)
        newKey = ""; newApp = ""; newPath = nil
    }

    private func pickApp() -> (String, String)? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        let name = (Bundle(url: url)?.infoDictionary?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        return (name, url.path)
    }

    private func installPlugin() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            plugins.installZip(at: url)
        }
    }

    private func installTheme() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json, .zip]
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            for url in panel.urls { themeStore.install(from: url) }
        }
    }
}
