import AppKit
import SwiftUI

@main
struct RealNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("RealNotch", image: "MenuBarIcon") {
            Button("Settings…") { delegate.settingsController?.show() }
                .keyboardShortcut(",")
            Divider()
            Button("Quit RealNotch") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    // NSApp.delegate is SwiftUI's internal wrapper, not this object — casting it fails.
    private(set) static weak var shared: AppDelegate?

    let appState = AppState()
    let themeStore = ThemeStore()
    let clipboardStore = ClipboardStore()
    let notesStore = NotesStore()
    let nowPlaying = NowPlaying()
    let caffeine = CaffeineManager()
    let agentStore = AgentStore()
    let pluginStore = PluginStore()
    let launcherStore = LauncherStore()
    private(set) var settingsController: SettingsWindowController?
    private var monitor: ClipboardMonitor?
    private var windowController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        settingsController = SettingsWindowController(
            themeStore: themeStore, clipboard: clipboardStore,
            launcher: launcherStore, plugins: pluginStore
        )

        let monitor = ClipboardMonitor(store: clipboardStore)
        monitor.start()
        self.monitor = monitor

        windowController = NotchWindowController(
            content: NotchRootView(
                appState: appState, themeStore: themeStore, clipboard: clipboardStore,
                notes: notesStore, nowPlaying: nowPlaying, caffeine: caffeine,
                agents: agentStore, plugins: pluginStore, launcher: launcherStore
            )
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardStore.saveNow()
        notesStore.saveNow()
        caffeine.deactivate()
    }
}
