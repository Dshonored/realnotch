import Foundation
import Observation

enum NotchTab: String, CaseIterable, Identifiable {
    case clipboard, music, notes
    var id: String { rawValue }

    var title: String {
        switch self {
        case .clipboard: "Clipboard"
        case .music: "Music"
        case .notes: "Notes"
        }
    }

    var glyph: String {
        switch self {
        case .clipboard: "📋"
        case .music: "♪"
        case .notes: "🗒"
        }
    }
}

@Observable
final class AppState {
    var isExpanded = false
    var tab: NotchTab = .clipboard
}
