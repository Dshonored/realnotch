import SwiftUI

/// The grown notch: header tabs (hover to switch) · section body · Keep-Awake footer.
struct NotchPanel: View {
    let appState: AppState
    let clipboard: ClipboardStore
    let notes: NotesStore
    let nowPlaying: NowPlaying
    let caffeine: CaffeineManager
    let width: CGFloat
    /// Reserved for the physical notch — content starts below it so the header
    /// (tabs) isn't hidden behind the hardware notch on notch Macs.
    let notchHeight: CGFloat
    let onCopy: (String) -> Void
    let openSettings: () -> Void

    @Environment(\.theme) private var theme

    // Background/clip/border are owned by the animated container in NotchRootView
    // so the panel can grow out of the notch smoothly.
    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: notchHeight)
            header
            divider
            sectionBody
                .padding(12)
            divider
            footer
        }
        .frame(width: width)
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 6) {
            cameraDot
                .padding(.trailing, 4)
            ForEach(NotchTab.allCases) { tab in
                tabPill(tab)
            }
            Circle()
                .fill(Color(hex: "#30D158FF"))
                .frame(width: 5, height: 5)
                .padding(.leading, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func tabPill(_ tab: NotchTab) -> some View {
        let active = appState.tab == tab
        return HStack(spacing: 5) {
            Image(systemName: tab.symbol)
                .font(.system(size: 11, weight: .semibold))
            Text(tab.title)
                .font(theme.font(theme.typography.itemSize, weight: .semibold))
        }
            .foregroundStyle(active
                ? Color(hex: theme.colors.textPrimary)
                : Color(hex: theme.colors.textSecondary))
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(active ? Color.white.opacity(0.14) : .clear)
            )
            .contentShape(Rectangle())
            .onHover { if $0 { appState.tab = tab } }
            .onTapGesture { appState.tab = tab }
            .accessibilityLabel(tab.title)
    }

    private var cameraDot: some View {
        Circle()
            .fill(Color(hex: "#1A1A1CFF"))
            .frame(width: 6, height: 6)
            .overlay(Circle().strokeBorder(Color(hex: "#2B2B2EFF"), lineWidth: 1.2))
    }

    // MARK: body

    @ViewBuilder
    private var sectionBody: some View {
        switch appState.tab {
        case .clipboard: ClipboardHistoryView(clipboard: clipboard, onCopy: onCopy)
        case .music: MusicView(nowPlaying: nowPlaying)
        case .notes: NotesView(notes: notes)
        }
    }

    // MARK: footer

    private var footer: some View {
        HStack(spacing: 9) {
            Image(systemName: caffeine.isActive ? "moon.fill" : "moon")
                .font(.system(size: 14))
                .foregroundStyle(caffeine.isActive
                    ? Color(hex: "#30D158FF")
                    : Color(hex: theme.colors.textSecondary))
            VStack(alignment: .leading, spacing: 1) {
                Text("Keep Awake")
                    .font(theme.font(theme.typography.itemSize, weight: .semibold))
                    .foregroundStyle(Color(hex: theme.colors.textPrimary))
                Text(caffeine.isActive ? "On — display stays awake" : "Off")
                    .font(theme.font(theme.typography.captionSize))
                    .foregroundStyle(Color(hex: theme.colors.textSecondary))
            }
            Spacer()
            awakeToggle
            Button(action: openSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: theme.colors.textSecondary))
                    .frame(width: 30, height: 30)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.07)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private var awakeToggle: some View {
        Button { caffeine.toggle() } label: {
            RoundedRectangle(cornerRadius: 20)
                .fill(caffeine.isActive ? Color(hex: "#30D158FF") : Color.white.opacity(0.2))
                .frame(width: 34, height: 20)
                .overlay(alignment: caffeine.isActive ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .padding(2)
                        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: caffeine.isActive)
        .accessibilityLabel("Keep Awake")
        .accessibilityValue(caffeine.isActive ? "On" : "Off")
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(hex: theme.colors.divider))
            .frame(height: 1)
    }
}
