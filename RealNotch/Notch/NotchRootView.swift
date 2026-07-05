import SwiftUI

/// Root of the notch panel. Observes the theme store so live theme edits restyle
/// everything, and injects the current theme into the environment.
struct NotchRootView: View {
    let appState: AppState
    let themeStore: ThemeStore
    let clipboard: ClipboardStore

    var body: some View {
        NotchContainer(appState: appState, clipboard: clipboard)
            .environment(\.theme, themeStore.current)
    }
}

private struct NotchContainer: View {
    let appState: AppState
    let clipboard: ClipboardStore
    @Environment(\.theme) private var theme

    private let expandedWidth: CGFloat = 480
    private let expandedHeight: CGFloat = 340
    private let topFlare: CGFloat = 8

    // Detected once per view identity — NEVER per frame. NSScreen queries during
    // an animation tank the frame rate. The panel repositions itself on screen
    // changes; a stale width here only mis-sizes the collapsed state briefly.
    private let notchWidth: CGFloat
    private let notchHeight: CGFloat

    init(appState: AppState, clipboard: ClipboardStore) {
        self.appState = appState
        self.clipboard = clipboard
        let g = NotchDetector.detect()
        notchWidth = g?.notchWidth ?? 200
        notchHeight = g?.notchHeight ?? 32
    }

    var body: some View {
        let expanded = appState.isExpanded
        // Collapsed hit area = the notch itself (no extra), so it only triggers
        // when the cursor is actually over the notch, not near it.
        let width = expanded ? expandedWidth : notchWidth
        let height = expanded ? expandedHeight : notchHeight
        let radius = expanded ? theme.shape.panelCornerRadius : theme.shape.notchCornerRadius
        let shape = NotchShape(bottomRadius: radius, topRadius: topFlare)

        ZStack(alignment: .top) {
            // Always in the hierarchy — inserting/removing views mid-animation
            // causes visible ghosting. Animate opacity instead.
            shape
                .fill(theme.material.blur == "thin" ? Material.ultraThinMaterial : .regularMaterial)
                .opacity(theme.material.blur == "none" || !expanded ? 0 : 1)
            shape
                .fill(Color(hex: theme.colors.background)
                    .opacity(expanded ? theme.material.backgroundOpacity : 1))

            ClipboardHistoryView(clipboard: clipboard)
                .padding(.top, notchHeight)
                .frame(width: expandedWidth, height: expandedHeight, alignment: .top)
                .opacity(expanded ? 1 : 0)
                .allowsHitTesting(expanded)
        }
        .frame(width: width, height: height)
        .clipShape(shape)
        .contentShape(shape)
        // Click the notch to open — hovering does NOT expand, so moving the cursor
        // toward tabs/menu-bar items near the top never covers them with the panel.
        .onTapGesture {
            if !expanded { appState.isExpanded = true }
        }
        // Auto-close the moment the cursor leaves the open panel, revealing whatever
        // is behind it. Collapsed hover does nothing.
        .onHover { hovering in
            if expanded && !hovering { appState.isExpanded = false }
        }
        .animation(theme.spring, value: expanded)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
