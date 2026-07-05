import SwiftUI

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
    @Environment(\.openSettings) private var openSettings
    @State private var hoverTask: Task<Void, Never>?
    @State private var copyToast: String?
    @State private var glow = false

    @AppStorage("openOnHover") private var openOnHover = true
    @AppStorage("hoverDelayMs") private var hoverDelayMs = 300

    private let expandedWidth: CGFloat = 440
    private let closeDelayMs = 120
    private let notchWidth: CGFloat
    private let notchHeight: CGFloat

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
        ZStack(alignment: .top) {
            if expanded {
                NotchPanel(
                    appState: appState, clipboard: clipboard, notes: notes,
                    nowPlaying: nowPlaying, caffeine: caffeine,
                    width: expandedWidth, onCopy: showToast, openSettings: { openSettings() }
                )
                .shadow(color: Color(hex: "#30D158FF").opacity(glow ? 0.5 : 0), radius: glow ? 26 : 0)
                .overlay(alignment: .top) { toast }
                .transition(.opacity)
            } else {
                CollapsedNotchView(clipboardCount: clipboard.items.count, isPlaying: nowPlaying.isPlaying)
                    .frame(width: max(notchWidth, 190), height: notchHeight)
                    .background(NotchShape(bottomRadius: theme.shape.notchCornerRadius).fill(.black))
                    .transition(.opacity)
            }
        }
        .animation(theme.spring, value: expanded)
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

    @ViewBuilder
    private var toast: some View {
        if let label = copyToast {
            Text("\(label) ✓")
                .font(theme.font(theme.typography.captionSize, weight: .bold))
                .foregroundStyle(Color(hex: "#08210FFF"))
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: "#30D158FF")))
                .shadow(color: Color(hex: "#30D158FF").opacity(0.55), radius: 12, y: 4)
                .offset(y: -6)
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
