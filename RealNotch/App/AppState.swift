import Foundation
import Observation

enum NotchTab: String, CaseIterable, Identifiable {
    case clipboard, agents, music, notes
    var id: String { rawValue }

    var title: String {
        switch self {
        case .clipboard: "Clipboard"
        case .agents: "Agents"
        case .music: "Music"
        case .notes: "Notes"
        }
    }

    /// SF Symbol name for the tab.
    var symbol: String {
        switch self {
        case .clipboard: "doc.on.clipboard"
        case .agents: "terminal"
        case .music: "music.note"
        case .notes: "note.text"
        }
    }
}

@Observable
final class AppState {
    var isExpanded = false
    var tab: NotchTab = .clipboard
}
