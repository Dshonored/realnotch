import Foundation
import Observation

/// A tab in the expanded notch — either a built-in section or a plugin.
struct NotchTab: Identifiable, Equatable {
    let id: String        // "clipboard" … or "plugin:<uuid>"
    let title: String
    let symbol: String    // SF Symbol

    static let builtins: [NotchTab] = [
        .init(id: "clipboard", title: "Clipboard", symbol: "doc.on.clipboard"),
        .init(id: "agents",    title: "Agents",    symbol: "terminal"),
        .init(id: "music",     title: "Music",     symbol: "music.note"),
        .init(id: "notes",     title: "Notes",     symbol: "note.text"),
        .init(id: "launcher",  title: "Launcher",  symbol: "keyboard"),
    ]
}

@Observable
final class AppState {
    var isExpanded = false
    var tabID: String = "clipboard"
}
