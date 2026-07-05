import Foundation

enum AgentState: String {
    case working   // actively running tools / mid-turn
    case waiting   // needs you — permission or a question
    case idle      // finished its turn, waiting for the next prompt

    var order: Int {
        switch self {
        case .waiting: 0
        case .working: 1
        case .idle: 2
        }
    }
}

/// One Claude Code session, as reported by the hook script into
/// Application Support/RealNotch/Agents/<session_id>.json.
struct Agent: Codable, Identifiable, Equatable {
    let session_id: String
    var name: String?
    var task: String?
    let cwd: String
    let status: String
    let detail: String
    let updatedAt: Double

    var id: String { session_id }
    var state: AgentState { AgentState(rawValue: status) ?? .working }

    var project: String {
        let folder = URL(fileURLWithPath: cwd).lastPathComponent
        return folder.isEmpty ? "session" : folder
    }

    /// Row title: what the agent is working on (its latest prompt), falling back to
    /// an explicit `--name`, then the project folder while no prompt has landed yet.
    var label: String {
        if let t = task, !t.isEmpty { return t }
        if let n = name, !n.isEmpty { return n }
        return project
    }
}
