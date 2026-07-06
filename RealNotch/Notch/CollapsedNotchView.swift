import SwiftUI

/// The idle notch: a slim black bar with live glyphs — clipboard count on the left,
/// a camera dot in the middle, an animated music waveform on the right.
struct CollapsedNotchView: View {
    let clipboardCount: Int
    let isPlaying: Bool
    let keepAwake: Bool
    let agentsWaiting: Int
    /// Width of the physical notch. The glyphs must sit in the visible "wings"
    /// beside it — anything drawn inside this column lands behind the camera
    /// housing and is invisible.
    let notchWidth: CGFloat
    @Environment(\.theme) private var theme

    /// Width the idle bar needs so each wing clears the physical notch and holds
    /// its glyphs. Wings are sized to the *wider* side so the camera column stays
    /// centered on the notch. Glyph widths are estimated (tiny 9pt caption text) —
    /// tune the constants if a skin's font runs wide.
    static func idealWidth(clipboardCount: Int, keepAwake: Bool,
                           agentsWaiting: Int, notchWidth: CGFloat) -> CGFloat {
        func textW(_ n: Int) -> CGFloat { 7 * CGFloat(String(n).count) }
        let left = (keepAwake ? 15 : 0) + 13 + textW(clipboardCount)
        let right = (agentsWaiting > 0 ? 13 + textW(agentsWaiting) + 8 : 0) + 28  // + music glyph
        let wing = max(left, right) + 14
        return notchWidth + wing * 2
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                if keepAwake {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: theme.colors.success))
                }
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.clipboard").font(.system(size: 9))
                    Text("\(clipboardCount)").font(theme.font(theme.typography.captionSize))
                }
                .foregroundStyle(Color(hex: theme.colors.textPrimary).opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 10)

            // The notch column itself — a camera dot for synthetic notches,
            // invisible behind the real cutout on notched Macs.
            Circle()
                .fill(Color(hex: "#1A1A1CFF"))
                .frame(width: 6, height: 6)
                .overlay(Circle().strokeBorder(Color(hex: "#2B2B2EFF"), lineWidth: 1.2))
                .frame(width: notchWidth)

            HStack(spacing: 8) {
                // An agent needs you — the whole point of the integration is to
                // surface this without opening anything.
                if agentsWaiting > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "terminal.fill").font(.system(size: 9))
                        Text("\(agentsWaiting)").font(theme.font(theme.typography.captionSize, weight: .bold))
                    }
                    .foregroundStyle(Color(hex: theme.colors.success))
                }
                HStack(spacing: 5) {
                    Image(systemName: "music.note").font(.system(size: 9))
                    Waveform(active: isPlaying, color: Color(hex: theme.colors.textPrimary))
                        .frame(width: 12, height: 9)
                }
                .foregroundStyle(Color(hex: theme.colors.textPrimary).opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Three bars pulsing — the "something is playing" glyph.
struct Waveform: View {
    var active: Bool
    var color: Color
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 1.5) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 2)
                    .scaleEffect(y: animating ? 1 : 0.3, anchor: .bottom)
                    .animation(
                        active ? .easeInOut(duration: 0.45).repeatForever().delay(Double(i) * 0.15) : .default,
                        value: animating
                    )
            }
        }
        // Drive the pulse off `active` so it restarts whenever playback starts —
        // a one-shot onAppear gets "used up" while paused and never re-triggers.
        .onAppear { animating = active }
        .onChange(of: active) { _, now in animating = now }
    }
}
