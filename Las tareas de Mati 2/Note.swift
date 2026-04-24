import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var isArchived: Bool
    var isPrivate: Bool
    let createdAt: Date
    var updatedAt: Date

    init(title: String, content: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.isArchived = false
        self.isPrivate = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
