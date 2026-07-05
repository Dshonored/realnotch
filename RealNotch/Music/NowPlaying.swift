import AppKit
import Foundation
import Observation

/// Live "now playing" for ANY source (Music, Spotify, browsers…).
///
/// Reading MediaRemote directly is blocked for third-party apps since macOS 15.4 —
/// the media daemon only answers `com.apple.*` processes. So we READ by running a
/// tiny JXA snippet through `/usr/bin/osascript` (an Apple-signed binary the daemon
/// trusts) and parsing its JSON. Sending transport commands is NOT gated, so those
/// still go directly through MediaRemote via dlsym.
@Observable
final class NowPlaying {
    var title = ""
    var artist = ""
    var appName = ""
    var artwork: NSImage?
    /// The playing app's icon — a fallback "photo" when the source has no artwork
    /// (browsers/YouTube rarely provide album art; Music/Spotify do).
    var appIcon: NSImage?
    var isPlaying = false
    var elapsed: Double = 0
    var duration: Double = 0

    var hasTrack: Bool { !title.isEmpty }
    var progress: Double { duration > 0 ? min(1, elapsed / duration) : 0 }

    private typealias SendCommand = @convention(c) (Int, [AnyHashable: Any]?) -> Bool
    private var sendCommand: SendCommand?
    private var timer: Timer?

    init() {
        loadCommandSender()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    // MARK: reading (via osascript)

    private static let readScript = """
    function run() {
      const MR = $.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/MediaRemote.framework/');
      MR.load;
      const Req = $.NSClassFromString('MRNowPlayingRequest');
      const item = Req.localNowPlayingItem;
      if (!item) return '{}';
      const info = item.nowPlayingInfo;
      if (!info) return '{}';
      function s(k){ const v = info.valueForKey(k); return v ? v.js : null; }
      let art = info.valueForKey('kMRMediaRemoteNowPlayingInfoArtworkData');
      let artB64 = null;
      if (art && art.length > 0) { artB64 = art.base64EncodedStringWithOptions(0).js; }
      let app = null;
      const path = Req.localNowPlayingPlayerPath;
      if (path && path.client) { const dn = path.client.displayName; app = dn ? dn.js : null; }
      return JSON.stringify({
        title: s('kMRMediaRemoteNowPlayingInfoTitle'),
        artist: s('kMRMediaRemoteNowPlayingInfoArtist'),
        rate: s('kMRMediaRemoteNowPlayingInfoPlaybackRate'),
        duration: s('kMRMediaRemoteNowPlayingInfoDuration'),
        elapsed: s('kMRMediaRemoteNowPlayingInfoElapsedTime'),
        artwork: artB64,
        app: app
      });
    }
    """

    private struct Payload: Decodable {
        var title: String?
        var artist: String?
        var rate: Double?
        var duration: Double?
        var elapsed: Double?
        var artwork: String?
        var app: String?
    }

    func refresh() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let json = Self.runOsascript() else { return }
            let payload = try? JSONDecoder().decode(Payload.self, from: Data(json.utf8))
            DispatchQueue.main.async { self?.apply(payload) }
        }
    }

    private func apply(_ p: Payload?) {
        guard let p, let t = p.title, !t.isEmpty else {
            title = ""; artist = ""; appName = ""; artwork = nil; appIcon = nil
            isPlaying = false; elapsed = 0; duration = 0
            return
        }
        title = t
        artist = p.artist ?? ""
        appName = p.app ?? ""
        isPlaying = (p.rate ?? 0) > 0
        duration = p.duration ?? 0
        elapsed = p.elapsed ?? 0
        if let b64 = p.artwork, let data = Data(base64Encoded: b64) {
            artwork = NSImage(data: data)
        } else {
            artwork = nil
        }
        appIcon = NSWorkspace.shared.runningApplications
            .first { $0.localizedName == appName }?.icon
    }

    private static func runOsascript() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-l", "JavaScript", "-e", readScript]
        let out = Pipe()
        task.standardOutput = out
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
        } catch {
            return nil
        }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }

    // MARK: commands (still allowed directly)

    private func loadCommandSender() {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW
        ), let sym = dlsym(handle, "MRMediaRemoteSendCommand") else { return }
        sendCommand = unsafeBitCast(sym, to: SendCommand.self)
    }

    func playPause() { _ = sendCommand?(2, nil); nudge() }
    func next() { _ = sendCommand?(4, nil); nudge() }
    func previous() { _ = sendCommand?(5, nil); nudge() }

    /// Re-read shortly after a command so the UI reflects the new state fast.
    private func nudge() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.refresh() }
    }
}
