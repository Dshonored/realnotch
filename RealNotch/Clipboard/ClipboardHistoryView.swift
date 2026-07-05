import AppKit
import SwiftUI

struct ClipboardHistoryView: View {
    let clipboard: ClipboardStore
    /// Fires with the copy label ("Copied"/"Stacked") so the panel can show the toast + glow.
    let onCopy: (String) -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("click to copy · ⇧-click to stack")
                    .font(theme.font(theme.typography.captionSize))
                    .foregroundStyle(Color(hex: theme.colors.textSecondary))
                Spacer()
                if !clipboard.stack.isEmpty {
                    Button { clipboard.copyStack(); onCopy("Stacked") } label: {
                        Text("📎 \(clipboard.stack.count) stacked")
                            .font(theme.font(theme.typography.captionSize, weight: .semibold))
                            .foregroundStyle(Color(hex: theme.colors.accent))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: theme.colors.accent).opacity(0.16))
                            .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy \(clipboard.stack.count) stacked items")
                }
            }
            .padding(.horizontal, 2)

            if clipboard.items.isEmpty {
                Text("Copy something — it shows up here.")
                    .font(theme.font(theme.typography.itemSize))
                    .foregroundStyle(Color(hex: theme.colors.textSecondary))
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ScrollView {
                    LazyVStack(spacing: 7) {
                        ForEach(clipboard.items) { item in
                            ClipboardItemRow(item: item, clipboard: clipboard, onCopy: onCopy)
                        }
                    }
                }
                .frame(maxHeight: 260)
                .scrollIndicators(.never)
            }
        }
    }
}
