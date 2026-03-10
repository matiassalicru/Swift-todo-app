import Foundation

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    let createdAt: Date
    var updatedAt: Date

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
