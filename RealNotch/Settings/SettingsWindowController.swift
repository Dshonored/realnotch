import AppKit
import SwiftUI

/// An AppKit-owned settings window. We manage it directly instead of relying on the
/// SwiftUI `Settings` scene + `showSettingsWindow:` selector, which is unreliable for
/// an accessory (LSUIElement) app whose only UI is a hosted notch panel.
@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let themeStore: ThemeStore
    private let clipboard: ClipboardStore
    private let launcher: LauncherStore
    private let plugins: PluginStore
    private let updater: Updater

    init(themeStore: ThemeStore, clipboard: ClipboardStore, launcher: LauncherStore,
         plugins: PluginStore, updater: Updater) {
        self.themeStore = themeStore
        self.clipboard = clipboard
        self.launcher = launcher
        self.plugins = plugins
        self.updater = updater
    }

    func show() {
        NSApplication.shared.activate(ignoringOtherApps: true)

        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(
            rootView: SettingsView(themeStore: themeStore, clipboard: clipboard,
                                   launcher: launcher, plugins: plugins, updater: updater)
        )
        let w = NSWindow(contentViewController: hosting)
        w.title = "RealNotch Settings"
        w.styleMask = [.titled, .closable, .miniaturizable]
        w.isReleasedWhenClosed = false
        w.setContentSize(NSSize(width: 460, height: 520))
        w.center()
        w.makeKeyAndOrderFront(nil)
        window = w
    }
}
