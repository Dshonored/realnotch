import SwiftUI

struct MusicView: View {
    let nowPlaying: NowPlaying
    @Environment(\.theme) private var theme

    var body: some View {
        if nowPlaying.hasTrack {
            playing
        } else {
            Text("Nothing playing")
                .font(theme.font(theme.typography.itemSize))
                .foregroundStyle(Color(hex: theme.colors.textSecondary))
                .frame(maxWidth: .infinity, minHeight: 90)
        }
    }

    private var playing: some View {
        VStack(spacing: 14) {
            HStack(spacing: 13) {
                artwork
                VStack(alignment: .leading, spacing: 2) {
                    Text(nowPlaying.title)
                        .font(theme.font(theme.typography.titleSize, weight: .semibold))
                        .foregroundStyle(Color(hex: theme.colors.textPrimary))
                        .lineLimit(1)
                    Text(nowPlaying.artist)
                        .font(theme.font(theme.typography.itemSize))
                        .foregroundStyle(Color(hex: theme.colors.textSecondary))
                        .lineLimit(1)

                    ProgressBar(value: nowPlaying.progress, color: Color(hex: theme.colors.textPrimary))
                        .frame(height: 4)
                        .padding(.top, 6)
                }
            }

            HStack(spacing: 22) {
                control("backward.fill") { nowPlaying.previous() }
                Button { nowPlaying.playPause() } label: {
                    Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.black)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white))
                }
                .buttonStyle(.plain)
                control("forward.fill") { nowPlaying.next() }
            }
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let image = nowPlaying.artwork {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 58, height: 58)
                .clipShape(.rect(cornerRadius: 11))
        } else {
            RoundedRectangle(cornerRadius: 11)
                .fill(LinearGradient(colors: [Color(hex: "#FF5E7EFF"), Color(hex: "#A45CFFFF")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 58, height: 58)
        }
    }

    private func control(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: theme.colors.textPrimary).opacity(0.85))
        }
        .buttonStyle(.plain)
    }
}

struct ProgressBar: View {
    let value: Double
    var color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.16))
                Capsule().fill(color).frame(width: geo.size.width * value)
            }
        }
    }
}
