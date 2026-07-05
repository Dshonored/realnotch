import AppKit
import SwiftUI

/// Borderless, non-activating panel pinned over the notch. Clicks and hovers work
/// without stealing focus from the frontmost app. The panel is always sized to the
/// max expanded frame; SwiftUI animates the visible shape inside it, and
/// NSHostingView passes clicks through wherever no SwiftUI content is hit.
final class NotchWindowController {
    static let panelSize = NSSize(width: 640, height: 500)

    private let panel: NSPanel

    init<Content: View>(content: Content) {
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovable = false
        panel.hidesOnDeactivate = false

        let hosting = NSHostingView(rootView: content)
        hosting.frame = NSRect(origin: .zero, size: Self.panelSize)
        panel.contentView = hosting

        reposition()
        panel.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reposition),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func reposition() {
        guard let geometry = NotchDetector.detect() else { return }
        let screen = geometry.screen.frame
        let origin = NSPoint(
            x: screen.midX - Self.panelSize.width / 2,
            y: screen.maxY - Self.panelSize.height
        )
        panel.setFrame(NSRect(origin: origin, size: Self.panelSize), display: true)
    }
}
