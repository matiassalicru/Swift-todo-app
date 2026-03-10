import Foundation
import Combine

final class TaskStore: ObservableObject {
    @Published var sections: [Section] = []

    private let saveURL: URL

    // #region agent log
    private let debugLogPath = "/tmp/debug-bae0c3.log"
    private func debugLog(message: String, data: [String: Any] = [:], hypothesisId: String = "") {
        let payload: [String: Any] = ["sessionId": "bae0c3", "timestamp": Date().timeIntervalSince1970 * 1000, "message": message, "data": data, "hypothesisId": hypothesisId, "location": "TaskStore.swift"]
        guard let json = try? JSONSerialization.data(withJSONObject: payload),
              var line = String(data: json, encoding: .utf8) else { return }
        line += "\n"
        guard let lineData = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: debugLogPath) {
            if let handle = FileHandle(forWritingAtPath: debugLogPath) {
                handle.seekToEndOfFile(); handle.write(lineData); handle.closeFile()
            }
        } else {
            FileManager.default.createFile(atPath: debugLogPath, contents: lineData)
        }
    }
    // #endregion

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
        // #region agent log
        let foundIndex = sections.firstIndex(where: { $0.id == section.id })
        debugLog(message: "archiveSection called", data: ["sectionId": section.id.uuidString, "sectionTitle": section.title, "sectionIsArchived": section.isArchived, "foundIndex": foundIndex as Any, "totalSections": sections.count], hypothesisId: "H-A,H-B,H-E")
        // #endregion
        guard let index = foundIndex else { return }
        sections[index].isArchived = true
        // #region agent log
        debugLog(message: "archiveSection: sections[index].isArchived set to true", data: ["index": index, "newIsArchived": sections[index].isArchived], hypothesisId: "H-D")
        // #endregion
        save()
    }

    func unarchiveSection(_ section: Section) {
        // #region agent log
        let foundIndex = sections.firstIndex(where: { $0.id == section.id })
        debugLog(message: "unarchiveSection called", data: ["sectionId": section.id.uuidString, "sectionTitle": section.title, "sectionIsArchived": section.isArchived, "foundIndex": foundIndex as Any, "totalSections": sections.count], hypothesisId: "H-A,H-B,H-E")
        // #endregion
        guard let index = foundIndex else { return }
        sections[index].isArchived = false
        // #region agent log
        debugLog(message: "unarchiveSection: sections[index].isArchived set to false", data: ["index": index, "newIsArchived": sections[index].isArchived], hypothesisId: "H-D")
        // #endregion
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

    private func save() {
        guard let data = try? JSONEncoder().encode(sections) else {
            // #region agent log
            debugLog(message: "save() FAILED: JSONEncoder encode failed", data: [:], hypothesisId: "H-C")
            // #endregion
            return
        }
        do {
            try data.write(to: saveURL, options: .atomic)
            // #region agent log
            debugLog(message: "save() succeeded", data: ["savedSectionsCount": sections.count, "archivedCount": sections.filter { $0.isArchived }.count], hypothesisId: "H-C")
            // #endregion
        } catch {
            // #region agent log
            debugLog(message: "save() FAILED: write error", data: ["error": error.localizedDescription], hypothesisId: "H-C")
            // #endregion
        }
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: saveURL),
            let decoded = try? JSONDecoder().decode([Section].self, from: data)
        else { return }
        sections = decoded
    }
}
