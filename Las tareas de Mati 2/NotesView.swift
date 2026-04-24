import SwiftUI

struct NotesView: View {
    @EnvironmentObject private var noteStore: NoteStore

    @State private var archivedCollapsed = true
    @State private var isAddingNote = false
    @State private var newNoteTitle = ""
    @FocusState private var noteInputFocused: Bool

    private let columns = [GridItem(.adaptive(minimum: 240), spacing: 14)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                if noteStore.activeNotes.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(noteStore.activeNotes) { note in
                            NoteCard(note: note)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }

            VStack(spacing: 0) {
                if !noteStore.archivedNotes.isEmpty {
                    Divider()

                    archivedHeader
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    if !archivedCollapsed {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(noteStore.archivedNotes) { note in
                                    archivedNoteCard(note)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                        .frame(maxHeight: 200)
                    }
                }

                Divider()

                addNoteView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(.thinMaterial.opacity(0.7))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textSecondary.opacity(0.3))
            Text("Sin notas")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }

    private var archivedHeader: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation(.spring(duration: 0.25)) {
                    archivedCollapsed.toggle()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .rotationEffect(.degrees(archivedCollapsed ? -90 : 0))
                    .animation(.spring(duration: 0.25), value: archivedCollapsed)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .contentShape(Circle())

            Image(systemName: "archivebox")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)

            Text("Archivados")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)

            Text("\(noteStore.archivedNotes.count)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(AppTheme.textSecondary.opacity(0.1))
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private func archivedNoteCard(_ note: Note) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title.isEmpty ? "Sin titulo" : note.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                Text(relativeDate(note.updatedAt))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            }

            Spacer()

            Button(action: { noteStore.unarchiveNote(note) }) {
                Image(systemName: "arrow.uturn.left")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .contentShape(Circle())

            Button(action: { noteStore.deleteNote(note) }) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
        }
        .padding(12)
        .opacity(0.65)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
    }

    private var addNoteView: some View {
        Group {
            if isAddingNote {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.violet)
                        TextField("Titulo de la nota...", text: $newNoteTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.text)
                            .focused($noteInputFocused)
                            .onSubmit { addNote() }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(AppTheme.violet.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { noteInputFocused = true }

                    Button(action: cancelAddNote) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                }
            } else {
                Button(action: startAddNote) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.violet.opacity(0.75))
                        Text("Nueva nota")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.violet.opacity(0.75))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(AppTheme.violet.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func startAddNote() {
        isAddingNote = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            noteInputFocused = true
        }
    }

    private func cancelAddNote() {
        isAddingNote = false
        newNoteTitle = ""
    }

    private func addNote() {
        let title = newNoteTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            cancelAddNote()
            return
        }
        noteStore.addNote(title: title)
        newNoteTitle = ""
        isAddingNote = false
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
