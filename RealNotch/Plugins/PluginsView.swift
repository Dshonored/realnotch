import SwiftUI

struct PluginsView: View {
    let plugins: PluginStore
    @Environment(\.theme) private var theme

    var body: some View {
        if plugins.plugins.isEmpty {
            VStack(spacing: 6) {
                Text("No plugins")
                    .font(theme.font(theme.typography.itemSize))
                    .foregroundStyle(Color(hex: theme.colors.textPrimary))
                Text("Drop a .lua file in the plugins folder — it loads live.")
                    .font(theme.font(theme.typography.captionSize))
                    .foregroundStyle(Color(hex: theme.colors.textSecondary))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(plugins.plugins) { plugin in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Image(systemName: plugin.icon).font(.system(size: 11))
                            Text(plugin.name)
                                .font(theme.font(theme.typography.captionSize, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: theme.colors.textSecondary))

                        ForEach(plugins.output[plugin.id] ?? []) { row in
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: theme.shape.itemCornerRadius)
                                    .fill(Color(hex: theme.colors.surface))
                            )
                        }
                    }
                }
            }
        }
    }
}
