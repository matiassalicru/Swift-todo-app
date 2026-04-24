import SwiftUI

struct NoteCard: View {
    let note: Note

    @EnvironmentObject private var noteStore: NoteStore

    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editingTitle = ""
    @State private var editingContent = ""
    @State private var showDeleteConfirmation = false
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isEditing {
                editingView
            } else {
                previewView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isEditing ? AppTheme.violet.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: AppTheme.glassShadow, radius: 10, y: 4)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .onTapGesture { startEditing() }
        .alert("Eliminar nota", isPresented: $showDeleteConfirmation) {
            Button("Eliminar", role: .destructive) { noteStore.deleteNote(note) }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta accion eliminara la nota permanentemente.")
        }
    }

    private var isBlurred: Bool {
        note.isPrivate && !isEditing
    }

    private var previewView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(note.title.isEmpty ? "Sin titulo" : note.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(note.title.isEmpty ? AppTheme.textSecondary : AppTheme.text)
                    .lineLimit(1)
                    .blur(radius: isBlurred ? 6 : 0)

                Spacer()

                if isHovered {
                    HStack(spacing: 4) {
                        Button(action: { noteStore.togglePrivate(note) }) {
                            Image(systemName: note.isPrivate ? "eye.slash" : "eye")
                                .font(.system(size: 10))
                                .foregroundColor(note.isPrivate ? AppTheme.violet : AppTheme.textSecondary)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(note.isPrivate ? AppTheme.violet.opacity(0.12) : Color.primary.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())

                        Button(action: { noteStore.archiveNote(note) }) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.primary.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())

                        Button(action: { showDeleteConfirmation = true }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.primary.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                } else if note.isPrivate {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.violet.opacity(0.5))
                }
            }

            if !note.content.isEmpty {
                Text(note.content)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .blur(radius: isBlurred ? 6 : 0)
            }

            Text(relativeDate(note.updatedAt))
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                .blur(radius: isBlurred ? 4 : 0)
        }
        .padding(14)
        .animation(.easeInOut(duration: 0.2), value: note.isPrivate)
    }

    private var editingView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Button(action: commitEdit) {
                    Text("Listo")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.violet)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.violet.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())
            }

            TextField("Titulo", text: $editingTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.text)
                .focused($titleFocused)

            TextEditor(text: $editingContent)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(AppTheme.text)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120, maxHeight: 300)

            Text(relativeDate(note.updatedAt))
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
        }
        .padding(14)
    }

    private func startEditing() {
        guard !isEditing else { return }
        editingTitle = note.title
        editingContent = note.content
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            titleFocused = true
        }
    }

    private func commitEdit() {
        let title = editingTitle.trimmingCharacters(in: .whitespaces)
        let content = editingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty || !content.isEmpty {
            noteStore.updateNote(note, title: title, content: content)
        }
        isEditing = false
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
