import SwiftUI

/// The Launcher notch tab: lists your app hotkeys; click a row to launch.
struct LauncherView: View {
    let launcher: LauncherStore
    let openSettings: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        if launcher.bindings.isEmpty {
            VStack(spacing: 8) {
                Text("No app shortcuts yet")
                    .font(theme.font(theme.typography.itemSize))
                    .foregroundStyle(Color(hex: theme.colors.textPrimary))
                Button(action: openSettings) {
                    Text("Add one in Settings")
                        .font(theme.font(theme.typography.captionSize, weight: .semibold))
                        .foregroundStyle(Color(hex: theme.colors.accent))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
        } else {
            VStack(spacing: 7) {
                ForEach(launcher.bindings) { b in
                    Button { launcher.launch(b) } label: {
                        HStack(spacing: 10) {
                            Group {
                                if let icon = b.icon {
                                    Image(nsImage: icon).resizable().frame(width: 20, height: 20)
                                } else {
                                    Image(systemName: "app.dashed")
                                        .foregroundStyle(Color(hex: theme.colors.accent))
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
                    .buttonStyle(.plain)
                }
            }
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
