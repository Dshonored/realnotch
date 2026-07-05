import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Bindable var themeStore: ThemeStore
    let clipboard: ClipboardStore

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var maxItems = 200

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
