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
        HStack(spacing: 8) {
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
            if tappable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: theme.colors.textSecondary))
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
