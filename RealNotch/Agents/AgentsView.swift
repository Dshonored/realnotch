import SwiftUI

struct AgentsView: View {
    let agents: AgentStore
    @Environment(\.theme) private var theme

    var body: some View {
        if agents.agents.isEmpty {
            VStack(spacing: 6) {
                Text("No Claude Code agents")
                    .font(theme.font(theme.typography.itemSize))
                    .foregroundStyle(Color(hex: theme.colors.textPrimary))
                Text("Start Claude in a terminal — sessions show up here.")
                    .font(theme.font(theme.typography.captionSize))
                    .foregroundStyle(Color(hex: theme.colors.textSecondary))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
        } else {
            VStack(spacing: 7) {
                ForEach(agents.agents) { agent in
                    AgentRow(agent: agent, store: agents)
                }
            }
        }
    }
}

private struct AgentRow: View {
    let agent: Agent
    let store: AgentStore
    @Environment(\.theme) private var theme
    @State private var hovered = false

    var body: some View {
        Button {
            store.focusTerminal(agent)
        } label: {
            HStack(spacing: 10) {
                statusDot
                VStack(alignment: .leading, spacing: 1) {
                    Text(agent.project)
                        .font(theme.font(theme.typography.itemSize, weight: .semibold))
                        .foregroundStyle(Color(hex: theme.colors.textPrimary))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(theme.font(theme.typography.captionSize))
                        .foregroundStyle(Color(hex: statusColor))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if agent.state == .waiting {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: theme.colors.textSecondary))
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: theme.shape.itemCornerRadius)
                    .fill(agent.state == .waiting
                        ? Color(hex: theme.colors.success).opacity(hovered ? 0.22 : 0.14)
                        : Color(hex: theme.colors.surface).opacity(hovered ? 1.6 : 1))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityLabel("\(agent.project), \(subtitle). Click to focus terminal.")
    }

    private var statusDot: some View {
        Circle()
            .fill(Color(hex: statusColor))
            .frame(width: 8, height: 8)
            .overlay {
                if agent.state == .working {
                    Circle().stroke(Color(hex: statusColor).opacity(0.4), lineWidth: 3)
                }
            }
    }

    private var statusColor: String {
        switch agent.state {
        case .waiting: theme.colors.success
        case .working: theme.colors.accent
        case .idle: theme.colors.textSecondary
        }
    }

    private var subtitle: String {
        switch agent.state {
        case .waiting: "needs you"
        case .working: agent.detail.isEmpty ? "working…" : "running \(agent.detail)"
        case .idle: "done"
        }
    }
}
