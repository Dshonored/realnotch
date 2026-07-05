import AppKit
import SwiftUI

@main
struct RealNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("RealNotch", systemImage: "sparkles.rectangle.stack") {
            SettingsLink { Text("Settings…") }
                .keyboardShortcut(",")
            Divider()
            Button("Quit RealNotch") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }

        Settings {
            SettingsView(themeStore: delegate.themeStore, clipboard: delegate.clipboardStore)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let themeStore = ThemeStore()
    let clipboardStore = ClipboardStore()
    private var monitor: ClipboardMonitor?
    private var windowController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let monitor = ClipboardMonitor(store: clipboardStore)
        monitor.start()
        self.monitor = monitor

        windowController = NotchWindowController(
            content: NotchRootView(appState: appState, themeStore: themeStore, clipboard: clipboardStore)
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardStore.saveNow()
    }
}
