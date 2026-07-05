import Foundation

struct Note: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var pinned: Bool
    var date: Date

    init(id: UUID = UUID(), title: String = "", body: String = "", pinned: Bool = false, date: Date = .now) {
        self.id = id
        self.title = title
        self.body = body
        self.pinned = pinned
        self.date = date
    }
}
