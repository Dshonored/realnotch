import SwiftUI

/// The idle notch: a slim black bar with live glyphs — clipboard count on the left,
/// a camera dot in the middle, an animated music waveform on the right.
struct CollapsedNotchView: View {
    let clipboardCount: Int
    let isPlaying: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "doc.on.clipboard").font(.system(size: 9))
                Text("\(clipboardCount)").font(theme.font(theme.typography.captionSize))
            }
            .foregroundStyle(Color(hex: theme.colors.textPrimary).opacity(0.55))

            Spacer()

            Circle()
                .fill(Color(hex: "#1A1A1CFF"))
                .frame(width: 6, height: 6)
                .overlay(Circle().strokeBorder(Color(hex: "#2B2B2EFF"), lineWidth: 1.2))

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "music.note").font(.system(size: 9))
                Waveform(active: isPlaying, color: Color(hex: theme.colors.textPrimary))
                    .frame(width: 12, height: 9)
            }
            .foregroundStyle(Color(hex: theme.colors.textPrimary).opacity(0.55))
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Three bars pulsing — the "something is playing" glyph.
struct Waveform: View {
    var active: Bool
    var color: Color
    @State private var phase = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 1.5) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 2)
                    .scaleEffect(y: active ? (phase ? 1 : 0.3) : 0.3, anchor: .bottom)
                    .animation(
                        active ? .easeInOut(duration: 0.45).repeatForever().delay(Double(i) * 0.15) : .default,
                        value: phase
                    )
            }
        }
        .onAppear { phase = true }
    }
}
