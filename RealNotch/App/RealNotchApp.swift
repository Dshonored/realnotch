import AppKit
import SwiftUI

@main
struct RealNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("RealNotch", systemImage: "sparkles.rectangle.stack") {
            Button("Settings…") { delegate.settingsController?.show() }
                .keyboardShortcut(",")
            Divider()
            Button("Quit RealNotch") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let themeStore = ThemeStore()
    let clipboardStore = ClipboardStore()
    let notesStore = NotesStore()
    let nowPlaying = NowPlaying()
    let caffeine = CaffeineManager()
    private(set) var settingsController: SettingsWindowController?
    private var monitor: ClipboardMonitor?
    private var windowController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        settingsController = SettingsWindowController(themeStore: themeStore, clipboard: clipboardStore)

        let monitor = ClipboardMonitor(store: clipboardStore)
        monitor.start()
        self.monitor = monitor

        windowController = NotchWindowController(
            content: NotchRootView(
                appState: appState, themeStore: themeStore, clipboard: clipboardStore,
                notes: notesStore, nowPlaying: nowPlaying, caffeine: caffeine
            )
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardStore.saveNow()
        notesStore.saveNow()
        caffeine.deactivate()
    }
}
