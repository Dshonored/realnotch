import AppKit
import SwiftUI

/// A button that records the next modifier+key combo into a canonical string
/// like "option+1". Requires at least one modifier. Works in the Settings window
/// (a real key window) via a local key-down monitor.
struct ShortcutRecorder: View {
    @Binding var key: String
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            recording ? stop() : start()
        } label: {
            Text(recording ? "Press a shortcut…"
                            : (key.isEmpty ? "Record shortcut" : Shortcut.display(key)))
                .frame(minWidth: 120)
        }
        .onDisappear(perform: stop)
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if let s = canonical(event) { key = s; stop() }
            return nil // consume the key so it doesn't type elsewhere
        }
    }

    private func stop() {
        recording = false
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    private func canonical(_ e: NSEvent) -> String? {
        var parts: [String] = []
        let f = e.modifierFlags
        if f.contains(.command) { parts.append("cmd") }
        if f.contains(.option) { parts.append("option") }
        if f.contains(.control) { parts.append("ctrl") }
        if f.contains(.shift) { parts.append("shift") }
        guard !parts.isEmpty else { return nil }               // need a modifier
        guard let ch = e.charactersIgnoringModifiers?.lowercased(),
              let first = ch.first, first.isLetter || first.isNumber else { return nil }
        parts.append(String(first))
        return parts.joined(separator: "+")
    }
}
