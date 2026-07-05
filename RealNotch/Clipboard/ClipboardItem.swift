import Foundation

struct ClipboardItem: Codable, Equatable, Identifiable {
    enum Content: Codable, Equatable {
        case text(String)
        /// Path to a PNG stored under Application Support/RealNotch/Images.
        case image(String)
        case fileURLs([URL])
    }

    let id: UUID
    let content: Content
    let date: Date
    let sourceApp: String?

    init(id: UUID = UUID(), content: Content, date: Date = .now, sourceApp: String? = nil) {
        self.id = id
        self.content = content
        self.date = date
        self.sourceApp = sourceApp
    }

    /// Short human-readable preview for rows and accessibility labels.
    var preview: String {
        switch content {
        case .text(let s):
            let line = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return line.count > 80 ? String(line.prefix(80)) + "…" : line
        case .image:
            return "Image"
        case .fileURLs(let urls):
            return urls.map(\.lastPathComponent).joined(separator: ", ")
        }
    }
}
