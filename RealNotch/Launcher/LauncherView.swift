import SwiftUI

/// The Launcher notch tab: lists your app hotkeys (click to launch), plus a
/// quick-add that auto-assigns the next ⌥number. Full control lives in Settings.
struct LauncherView: View {
    let launcher: LauncherStore
    let openSettings: () -> Void
    @Environment(\.theme) private var theme
    @State private var apps: [AppInfo] = []

    var body: some View {
        VStack(spacing: 7) {
            ForEach(launcher.bindings) { b in
                Button { launcher.launch(b) } label: { row(b) }
                    .buttonStyle(.plain)
            }
            addMenu
        }
        .onAppear { if apps.isEmpty { apps = InstalledApps.all() } }
    }

    private func row(_ b: AppBinding) -> some View {
        HStack(spacing: 10) {
            Group {
                if let icon = b.icon {
                    Image(nsImage: icon).resizable().frame(width: 20, height: 20)
                } else {
                    Image(systemName: "app.dashed").foregroundStyle(Color(hex: theme.colors.accent))
                }
            }
            .frame(width: 20)
            Text(b.app)
                .font(theme.font(theme.typography.itemSize))
                .foregroundStyle(Color(hex: theme.colors.textPrimary))
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(Shortcut.display(b.key))
                .font(.system(size: theme.typography.captionSize, design: .rounded).weight(.semibold))
                .foregroundStyle(Color(hex: theme.colors.textSecondary))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(hex: theme.colors.textPrimary).opacity(0.08))
                .clipShape(.rect(cornerRadius: 5))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: theme.shape.itemCornerRadius)
                .fill(Color(hex: theme.colors.surface))
        )
    }

    @ViewBuilder
    private var addMenu: some View {
        if launcher.nextFreeKey() != nil {
            Menu {
                ForEach(apps) { a in
                    Button { launcher.quickAdd(app: a.name, path: a.path) } label: {
                        Label { Text(a.name) } icon: { Image(nsImage: a.icon) }
                    }
                }
                Divider()
                Button("More options…", action: openSettings)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add app")
                }
                .font(theme.font(theme.typography.itemSize, weight: .semibold))
                .foregroundStyle(Color(hex: theme.colors.accent))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.shape.itemCornerRadius)
                        .strokeBorder(Color(hex: theme.colors.accent).opacity(0.4),
                                      style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(maxWidth: .infinity, minHeight: launcher.bindings.isEmpty ? 80 : nil)
        } else {
            Button("All ⌥ slots used — edit in Settings", action: openSettings)
                .font(theme.font(theme.typography.captionSize))
                .foregroundStyle(Color(hex: theme.colors.textSecondary))
                .buttonStyle(.plain)
        }
    }
}

/// Formats "option+1" as "⌥1" for display.
enum Shortcut {
    static func display(_ key: String) -> String {
        var out = ""
        for part in key.lowercased().split(whereSeparator: { $0 == "+" || $0 == " " }) {
            switch String(part) {
            case "cmd", "command": out += "⌘"
            case "opt", "option", "alt": out += "⌥"
            case "ctrl", "control": out += "⌃"
            case "shift": out += "⇧"
            case let k: out += k.uppercased()
            }
        }
        return out
    }
}
