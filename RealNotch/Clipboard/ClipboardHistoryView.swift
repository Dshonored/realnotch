import AppKit
import SwiftUI

struct ClipboardHistoryView: View {
    let clipboard: ClipboardStore
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 10) {
            header

            if clipboard.items.isEmpty {
                Text("Copy something — it shows up here.")
                    .font(theme.font(theme.typography.itemSize))
                    .foregroundStyle(Color(hex: theme.colors.textSecondary))
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(clipboard.items) { item in
                            ClipboardItemRow(item: item, clipboard: clipboard)
                        }
                    }
                    // So the scroll fade/last row clears the rounded bottom corners.
                    .padding(.bottom, 4)
                }
                .scrollIndicators(.never)
            }
        }
        // Horizontal clears the top flares; bottom scales with the panel's corner
        // radius so rows never tuck under the curve on any skin.
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, max(16, theme.shape.panelCornerRadius * 0.7))
    }

    private var header: some View {
        HStack {
            Text("Clipboard")
                .font(theme.font(theme.typography.titleSize, weight: .semibold))
                .foregroundStyle(Color(hex: theme.colors.textPrimary))

            Spacer()

            if !clipboard.stack.isEmpty {
                StackChip(clipboard: clipboard)
            }

            Button {
                clipboard.clear()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color(hex: theme.colors.textSecondary))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear clipboard history")
        }
    }
}

/// Shows how many items are stacked. Click copies them all (newline-joined) and
/// clears the stack; the ✕ clears without copying.
struct StackChip: View {
    let clipboard: ClipboardStore
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            Button {
                clipboard.copyStack()
            } label: {
                Label("\(clipboard.stack.count)", systemImage: "square.stack.3d.up.fill")
                    .font(theme.font(theme.typography.captionSize, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy \(clipboard.stack.count) stacked items")

            Button {
                clipboard.clearStack()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear stack")
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: theme.colors.stackChip))
        .clipShape(.capsule)
    }
}
