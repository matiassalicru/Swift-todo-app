import Foundation

struct Section: Identifiable, Codable {
    let id: UUID
    var title: String
    var tasks: [Task]
    var isArchived: Bool

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.tasks = []
        self.isArchived = false
    }
}
