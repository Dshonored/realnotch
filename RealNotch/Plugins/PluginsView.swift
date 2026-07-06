import SwiftUI

/// One plugin's tab — the rows returned by its render().
struct PluginTabView: View {
    let plugin: LuaPlugin
    let plugins: PluginStore
    @Environment(\.theme) private var theme

    var body: some View {
        let rows = plugins.output[plugin.id] ?? []
        if rows.isEmpty {
            Text("Nothing to show")
                .font(theme.font(theme.typography.itemSize))
                .foregroundStyle(Color(hex: theme.colors.textSecondary))
                .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            VStack(spacing: 7) {
                ForEach(rows) { row in
                    if let ref = row.actionRef {
                        Button { plugins.runAction(ref) } label: { rowBody(row, tappable: true) }
                            .buttonStyle(.plain)
                    } else {
                        rowBody(row, tappable: false)
                    }
                }
            }
        }
    }

    private func rowBody(_ row: PluginRow, tappable: Bool) -> some View {
        let tint = row.color.map { Color(hex: $0) } ?? Color(hex: theme.colors.accent)
        return VStack(spacing: 7) {
            HStack(spacing: 9) {
                if let icon = row.icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(tint)
                        .frame(width: 20)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(row.title)
                        .font(theme.font(theme.typography.itemSize))
                        .foregroundStyle(Color(hex: theme.colors.textPrimary))
                        .lineLimit(1)
                    if let s = row.subtitle {
                        Text(s)
                            .font(theme.font(theme.typography.captionSize))
                            .foregroundStyle(Color(hex: theme.colors.textSecondary))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let badge = row.badge {
                    Text(badge)
                        .font(.system(size: theme.typography.captionSize, weight: .bold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(tint.opacity(0.16))
                        .clipShape(.capsule)
                } else if tappable {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: theme.colors.textSecondary))
                }
            }
            if let p = row.progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: theme.colors.textPrimary).opacity(0.12))
                        Capsule().fill(tint).frame(width: geo.size.width * min(1, max(0, p)))
                    }
                }
                .frame(height: 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: theme.shape.itemCornerRadius)
                .fill(Color(hex: theme.colors.surface))
        )
    }
}
