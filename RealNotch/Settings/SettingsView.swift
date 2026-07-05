import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Bindable var themeStore: ThemeStore
    let clipboard: ClipboardStore

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var maxItems = 200
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

            Section("Theme") {
                Picker("Skin", selection: $themeStore.current) {
                    ForEach(themeStore.themes) { theme in
                        Text("\(theme.name) — \(theme.author)").tag(theme)
                    }
                }

                Button("Open Themes Folder") {
                    NSWorkspace.shared.open(ThemeStore.userThemesDirectory)
                }
                Text("Drop .json skins in this folder — changes apply live.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .onAppear { maxItems = clipboard.maxItems }
    }
}
