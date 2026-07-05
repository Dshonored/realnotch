import AppKit
import SwiftUI

/// Opens our AppKit-owned settings window. `@Environment(\.openSettings)` and the
/// `showSettingsWindow:` selector are both no-ops from a hosted NSPanel outside the
/// scene graph, so we drive an NSWindow we control directly.
@MainActor
func openAppSettings() {
    AppDelegate.shared?.settingsController?.show()
}

/// Root of the notch panel. Injects the current theme and holds all feature stores.
struct NotchRootView: View {
    let appState: AppState
    let themeStore: ThemeStore
    let clipboard: ClipboardStore
    let notes: NotesStore
    let nowPlaying: NowPlaying
    let caffeine: CaffeineManager

    var body: some View {
        NotchContainer(
            appState: appState, clipboard: clipboard,
            notes: notes, nowPlaying: nowPlaying, caffeine: caffeine
        )
        .environment(\.theme, themeStore.current)
    }
}

private struct NotchContainer: View {
    let appState: AppState
    let clipboard: ClipboardStore
    let notes: NotesStore
    let nowPlaying: NowPlaying
    let caffeine: CaffeineManager

    @Environment(\.theme) private var theme
    @State private var hoverTask: Task<Void, Never>?
    @State private var copyToast: String?
    @State private var glow = false
    @State private var panelHeight: CGFloat = 340

    @AppStorage("openOnHover") private var openOnHover = true
    @AppStorage("hoverDelayMs") private var hoverDelayMs = 300

    private let expandedWidth: CGFloat = 440
    private let closeDelayMs = 120
    private let notchWidth: CGFloat
    private let notchHeight: CGFloat

    private var collapsedWidth: CGFloat { max(notchWidth, 190) }

    init(appState: AppState, clipboard: ClipboardStore, notes: NotesStore,
         nowPlaying: NowPlaying, caffeine: CaffeineManager) {
        self.appState = appState
        self.clipboard = clipboard
        self.notes = notes
        self.nowPlaying = nowPlaying
        self.caffeine = caffeine
        let g = NotchDetector.detect()
        notchWidth = g?.notchWidth ?? 200
        notchHeight = g?.notchHeight ?? 32
    }

    var body: some View {
        let expanded = appState.isExpanded
        let width = expanded ? expandedWidth : collapsedWidth
        let height = expanded ? panelHeight : notchHeight
        let radius = expanded ? theme.shape.panelCornerRadius : theme.shape.notchCornerRadius
        let shape = NotchShape(bottomRadius: radius)

        ZStack(alignment: .top) {
            // One background shape that grows — clipping the content as it opens
            // gives a real "grow out of the notch" reveal instead of a pop.
            panelBackground(shape, expanded: expanded)

            CollapsedNotchView(clipboardCount: clipboard.items.count, isPlaying: nowPlaying.isPlaying)
                .frame(width: collapsedWidth, height: notchHeight)
                .opacity(expanded ? 0 : 1)

            NotchPanel(
                appState: appState, clipboard: clipboard, notes: notes,
                nowPlaying: nowPlaying, caffeine: caffeine,
                width: expandedWidth, notchHeight: notchHeight,
                onCopy: showToast, openSettings: openAppSettings
            )
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { panelHeight = $0 }
            .opacity(expanded ? 1 : 0)
            .allowsHitTesting(expanded)
            .overlay(alignment: .top) { toast }
        }
        .frame(width: width, height: height, alignment: .top)
        .clipShape(shape)
        .overlay(shape.stroke(Color(hex: theme.colors.border), lineWidth: expanded ? 1 : 0))
        .shadow(color: Color(hex: theme.colors.success).opacity(glow ? 0.5 : 0), radius: glow ? 26 : 0)
        // Pin hover/tap to the visible notch shape. clipShape only clips drawing —
        // without this the always-present (invisible) panel inflates the hit area.
        .contentShape(shape)
        .animation(theme.spring, value: expanded)
        .animation(theme.spring, value: panelHeight)
        .animation(.easeOut(duration: 0.5), value: glow)
        .onTapGesture { if !expanded { appState.isExpanded = true } }
        .onHover { hovering in
            hoverTask?.cancel()
            if hovering {
                guard !expanded, openOnHover else { return }
                hoverTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(hoverDelayMs))
                    if !Task.isCancelled { appState.isExpanded = true }
                }
            } else if expanded {
                hoverTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(closeDelayMs))
                    if !Task.isCancelled { appState.isExpanded = false }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func panelBackground(_ shape: NotchShape, expanded: Bool) -> some View {
        ZStack {
            if expanded && theme.material.blur != "none" {
                shape.fill(theme.material.blur == "thin" ? Material.ultraThinMaterial : .regularMaterial)
            }
            shape.fill(Color(hex: theme.colors.background)
                .opacity(expanded ? theme.material.backgroundOpacity : 1))
        }
    }

    @ViewBuilder
    private var toast: some View {
        if let label = copyToast {
            HStack(spacing: 4) {
                Text(label)
                Image(systemName: "checkmark")
            }
                .font(theme.font(theme.typography.captionSize, weight: .bold))
                .foregroundStyle(Color(hex: theme.colors.background))
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: theme.colors.success)))
                .shadow(color: Color(hex: theme.colors.success).opacity(0.55), radius: 12, y: 4)
                .offset(y: notchHeight + 4)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func showToast(_ label: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            copyToast = label
            glow = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation { copyToast = nil }
            glow = false
        }
    }
}
