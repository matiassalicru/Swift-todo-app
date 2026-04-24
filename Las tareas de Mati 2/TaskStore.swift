import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

struct SectionsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(sections: [Section]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.data = (try? encoder.encode(sections)) ?? Data()
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

final class TaskStore: ObservableObject {
    @Published var sections: [Section] = []

    private let saveURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        saveURL = docs.appendingPathComponent("tareas.json")
        load()
        if sections.isEmpty {
            sections.append(Section(title: "General"))
        }
    }

    var activeSections: [Section] {
        sections.filter { !$0.isArchived }
    }

    var archivedSections: [Section] {
        sections.filter { $0.isArchived }
    }

    var totalPendingCount: Int {
        var count = 0
        for section in activeSections {
            for task in section.tasks where !task.isCompleted {
                count += 1
            }
        }
        return count
    }

    func archiveSection(_ section: Section) {
        guard let index = sections.firstIndex(where: { $0.id == section.id }) else { return }
        sections[index].isArchived = true
        save()
    }

    func unarchiveSection(_ section: Section) {
        guard let index = sections.firstIndex(where: { $0.id == section.id }) else { return }
        sections[index].isArchived = false
        save()
    }

    func addSection(title: String) {
        sections.append(Section(title: title))
        save()
    }

    func deleteSection(_ section: Section) {
        sections.removeAll { $0.id == section.id }
        save()
    }

    func updateSectionTitle(_ section: Section, title: String) {
        guard let index = sections.firstIndex(where: { $0.id == section.id }) else { return }
        sections[index].title = title
        save()
    }

    func addTask(title: String, toSection section: Section) {
        guard let index = sections.firstIndex(where: { $0.id == section.id }) else { return }
        sections[index].tasks.append(Task(title: title))
        save()
    }

    func toggleTask(_ task: Task, inSection section: Section) {
        guard let sIndex = sections.firstIndex(where: { $0.id == section.id }) else { return }
        guard let tIndex = sections[sIndex].tasks.firstIndex(where: { $0.id == task.id }) else { return }
        sections[sIndex].tasks[tIndex].isCompleted.toggle()
        sections[sIndex].tasks[tIndex].updatedAt = Date()
        save()
    }

    func updateTask(_ task: Task, title: String, inSection section: Section) {
        guard let sIndex = sections.firstIndex(where: { $0.id == section.id }) else { return }
        guard let tIndex = sections[sIndex].tasks.firstIndex(where: { $0.id == task.id }) else { return }
        sections[sIndex].tasks[tIndex].title = title
        sections[sIndex].tasks[tIndex].updatedAt = Date()
        save()
    }

    func deleteTask(_ task: Task, fromSection section: Section) {
        guard let sIndex = sections.firstIndex(where: { $0.id == section.id }) else { return }
        sections[sIndex].tasks.removeAll { $0.id == task.id }
        save()
    }

    func importSections(from url: URL, replacing: Bool) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Section].self, from: data) else { return }
        if replacing {
            sections = decoded
        } else {
            sections.append(contentsOf: decoded)
        }
        save()
    }

    func moveTask(_ task: Task, fromSection source: Section, toSectionId destinationId: UUID) {
        guard let sIndex = sections.firstIndex(where: { $0.id == source.id }),
              let tIndex = sections[sIndex].tasks.firstIndex(where: { $0.id == task.id }),
              let dIndex = sections.firstIndex(where: { $0.id == destinationId }) else { return }
        let removed = sections[sIndex].tasks.remove(at: tIndex)
        sections[dIndex].tasks.append(removed)
        save()
    }

    private func save() {
        guard loadedSuccessfully || sections.contains(where: { !$0.tasks.isEmpty }) else { return }
        guard let data = try? JSONEncoder().encode(sections) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private var loadedSuccessfully = false

    private func load() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        guard let decoded = try? JSONDecoder().decode([Section].self, from: data) else {
            // Backup del archivo si falla el decode para no perder datos
            let backupURL = saveURL.deletingLastPathComponent().appendingPathComponent("tareas_backup.json")
            try? data.write(to: backupURL, options: .atomic)
            return
        }
        sections = decoded
        loadedSuccessfully = true
    }
}
