import AppKit
import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let clipboard: ClipboardStore
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button {
            // Shift-click stacks; plain click copies.
            if NSEvent.modifierFlags.contains(.shift) {
                clipboard.toggleStack(item)
            } else {
                clipboard.copy(item)
            }
        } label: {
            HStack(spacing: 8) {
                icon
                    .foregroundStyle(Color(hex: theme.colors.accent))
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.preview)
                        .font(theme.font(theme.typography.itemSize))
                        .foregroundStyle(Color(hex: theme.colors.textPrimary))
                        .lineLimit(1)
                    if let app = item.sourceApp {
                        Text(app)
                            .font(theme.font(theme.typography.captionSize))
                            .foregroundStyle(Color(hex: theme.colors.textSecondary))
                    }
                }

                Spacer(minLength: 0)

                if clipboard.isStacked(item) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: theme.colors.stackChip))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Color(hex: theme.colors.surface)
                    .opacity(isHovered ? 1 : 0.6)
            )
            .clipShape(.rect(cornerRadius: theme.shape.itemCornerRadius))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel("Copy \(item.preview). Shift-click to add to stack.")
    }

    @ViewBuilder
    private var icon: some View {
        switch item.content {
        case .text: Image(systemName: "doc.on.doc")
        case .image: Image(systemName: "photo")
        case .fileURLs: Image(systemName: "folder")
        }
    }
}
