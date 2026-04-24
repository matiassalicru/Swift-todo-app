import Foundation
import Combine

final class NoteStore: ObservableObject {
    @Published var notes: [Note] = []

    private let saveURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        saveURL = docs.appendingPathComponent("notas.json")
        load()
    }

    var activeNotes: [Note] {
        notes.filter { !$0.isArchived }
    }

    var archivedNotes: [Note] {
        notes.filter { $0.isArchived }
    }

    func addNote(title: String) {
        notes.insert(Note(title: title), at: 0)
        save()
    }

    func updateNote(_ note: Note, title: String, content: String) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].title = title
        notes[index].content = content
        notes[index].updatedAt = Date()
        save()
    }

    func archiveNote(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isArchived = true
        save()
    }

    func unarchiveNote(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isArchived = false
        save()
    }

    func togglePrivate(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isPrivate.toggle()
        save()
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: saveURL),
            let decoded = try? JSONDecoder().decode([Note].self, from: data)
        else { return }
        notes = decoded
    }
}
