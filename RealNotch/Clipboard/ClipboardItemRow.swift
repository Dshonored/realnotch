import AppKit
import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let clipboard: ClipboardStore
    let onCopy: (String) -> Void
    @Environment(\.theme) private var theme
    @State private var hovered = false
    @State private var flashing = false

    var body: some View {
        Button {
            if NSEvent.modifierFlags.contains(.shift) {
                clipboard.toggleStack(item)
            } else {
                clipboard.copy(item)
                onCopy("Copied")
                flash()
            }
        } label: {
            HStack(spacing: 11) {
                iconChip
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.preview)
                        .font(theme.font(theme.typography.itemSize))
                        .foregroundStyle(Color(hex: theme.colors.textPrimary))
                        .lineLimit(1)
                    if let app = item.sourceApp {
                        Text(app)
                            .font(theme.font(theme.typography.captionSize))
                            .foregroundStyle(Color(hex: theme.colors.textSecondary).opacity(0.7))
                    }
                }
                Spacer(minLength: 0)

                if clipboard.isStacked(item) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: theme.colors.accent))
                }

                Button { clipboard.togglePin(item) } label: {
                    Image(systemName: item.pinned ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(item.pinned
                            ? Color(hex: theme.colors.pin)
                            : Color(hex: theme.colors.textSecondary).opacity(hovered ? 0.5 : 0.2))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: theme.shape.itemCornerRadius)
                    .fill(flashing
                        ? Color(hex: "#30D158FF").opacity(0.28)
                        : Color(hex: theme.colors.surface).opacity(hovered ? 1.6 : 1))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.9), value: flashing)
        .accessibilityLabel("Copy \(item.preview). Shift-click to add to stack.")
    }

    @ViewBuilder
    private var iconChip: some View {
        if case .image(let path) = item.content, let thumb = NSImage(contentsOfFile: path) {
            // Show a real thumbnail of the copied image instead of a generic glyph.
            Image(nsImage: thumb)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 34, height: 26)
                .clipShape(.rect(cornerRadius: 7))
        } else {
            Image(systemName: iconSymbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 7).fill(iconColor))
        }
    }

    private var iconSymbol: String {
        switch item.content {
        case .text: "text.alignleft"
        case .image: "photo"
        case .fileURLs: "link"
        }
    }

    private var iconColor: Color {
        switch item.content {
        case .text: Color(hex: "#5E5CE6FF")
        case .image: Color(hex: "#FF9500FF")
        case .fileURLs: Color(hex: theme.colors.accent)
        }
    }

    private func flash() {
        flashing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) { flashing = false }
    }
}
