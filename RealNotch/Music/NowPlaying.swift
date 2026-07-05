import AppKit
import Foundation
import Observation

/// Live "now playing" via the private MediaRemote framework.
///
/// ponytail: MediaRemote is a private API. Apple gated the now-playing read behind
/// an entitlement on recent macOS, so on newer systems the callbacks may never fire
/// — the UI then just shows the empty state. All access is guarded; nothing crashes
/// if the framework or a symbol is missing. If live media matters and this is dark on
/// your macOS, that's the known private-API restriction, not a logic bug.
@Observable
final class NowPlaying {
    var title = ""
    var artist = ""
    var appName = ""
    var artwork: NSImage?
    var isPlaying = false
    var elapsed: Double = 0
    var duration: Double = 0

    var hasTrack: Bool { !title.isEmpty }
    var progress: Double { duration > 0 ? min(1, elapsed / duration) : 0 }

    // MediaRemote symbols, resolved once.
    private typealias GetInfo = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias GetIsPlaying = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias SendCommand = @convention(c) (Int, [AnyHashable: Any]?) -> Bool
    private typealias RegisterNotifications = @convention(c) (DispatchQueue) -> Void

    private var getInfo: GetInfo?
    private var getIsPlaying: GetIsPlaying?
    private var sendCommand: SendCommand?

    init() {
        loadMediaRemote()
        refresh()
        // Poll — cheaper than fighting the private notification API, and MediaRemote's
        // notifications are unreliable when entitlement-gated anyway.
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func loadMediaRemote() {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_NOW
        ) else { return }
        if let s = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getInfo = unsafeBitCast(s, to: GetInfo.self)
        }
        if let s = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            getIsPlaying = unsafeBitCast(s, to: GetIsPlaying.self)
        }
        if let s = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommand = unsafeBitCast(s, to: SendCommand.self)
        }
    }

    func refresh() {
        getInfo?(.main) { [weak self] info in
            guard let self else { return }
            self.title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
            self.artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            self.duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
            self.elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0
            if let data = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                self.artwork = NSImage(data: data)
            } else if self.title.isEmpty {
                self.artwork = nil
            }
        }
        getIsPlaying?(.main) { [weak self] playing in
            self?.isPlaying = playing
        }
    }

    // MediaRemote command codes.
    func playPause() { _ = sendCommand?(2, nil); refresh() }
    func next() { _ = sendCommand?(4, nil); refresh() }
    func previous() { _ = sendCommand?(5, nil); refresh() }
}
