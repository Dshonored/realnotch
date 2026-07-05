import AppKit
import Foundation

/// There is no pasteboard-change notification on macOS — every clipboard manager
/// polls `changeCount`. 0.5s is imperceptible and costs nothing.
final class ClipboardMonitor {
    private let store: ClipboardStore
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    /// Password managers mark secrets with these; we must never record them.
    private static let skippedTypes: [NSPasteboard.PasteboardType] = [
        .init("org.nspasteboard.ConcealedType"),
        .init("org.nspasteboard.TransientType"),
    ]

    init(store: ClipboardStore) {
        self.store = store
    }

    func start() {
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in self?.poll() }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        if store.ignoreNextChange {
            store.ignoreNextChange = false
            return
        }
        guard let types = pb.types, !types.contains(where: Self.skippedTypes.contains) else { return }

        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        if let urls = pb.readObjects(forClasses: [NSURL.self]) as? [URL],
           !urls.isEmpty, urls.allSatisfy(\.isFileURL) {
            store.add(ClipboardItem(content: .fileURLs(urls), sourceApp: sourceApp))
        } else if let text = pb.string(forType: .string), !text.isEmpty {
            store.add(ClipboardItem(content: .text(text), sourceApp: sourceApp))
        } else if let image = NSImage(pasteboard: pb) {
            if let path = saveImage(image) {
                store.add(ClipboardItem(content: .image(path), sourceApp: sourceApp))
            }
        }
    }

    private func saveImage(_ image: NSImage) -> String? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return nil }
        let url = store.imagesDirectory.appending(path: "\(UUID().uuidString).png")
        do {
            try png.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }
}
