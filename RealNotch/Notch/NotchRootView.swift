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

    private var geometry: (width: CGFloat, height: CGFloat) {
        let notch = NotchDetector.detect()
        return (notch?.notchWidth ?? 200, notch?.notchHeight ?? 32)
    }

    var body: some View {
        let expanded = appState.isExpanded
        let width = expanded ? expandedWidth : geometry.width
        let height = expanded ? expandedHeight : geometry.height
        let radius = expanded ? theme.shape.panelCornerRadius : theme.shape.notchCornerRadius

        ZStack(alignment: .top) {
            if theme.material.blur != "none", expanded {
                NotchShape(bottomRadius: radius)
                    .fill(theme.material.blur == "thin" ? Material.ultraThinMaterial : .regularMaterial)
            }
            NotchShape(bottomRadius: radius)
                .fill(Color(hex: theme.colors.background)
                    .opacity(expanded ? theme.material.backgroundOpacity : 1))

            if expanded {
                ClipboardHistoryView(clipboard: clipboard)
                    .padding(.top, geometry.height)
                    .transition(.opacity)
            }
        }
        .frame(width: width, height: height)
        .contentShape(NotchShape(bottomRadius: radius))
        .onHover { hovering in
            withAnimation(theme.spring) { appState.isExpanded = hovering }
        }
        .animation(theme.spring, value: expanded)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
