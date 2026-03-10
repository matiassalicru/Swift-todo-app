import SwiftUI

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> Void

    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editingText = ""
    @State private var showDeleteConfirmation = false
    @FocusState private var editFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 20, height: 20)
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? RowColors.violet : RowColors.border,
                            lineWidth: 1.5
                        )
                        .frame(width: 20, height: 20)
                    if task.isCompleted {
                        Circle()
                            .fill(RowColors.violet)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .contentShape(Circle())
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: task.isCompleted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                if isEditing {
                    TextField("", text: $editingText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(RowColors.text)
                        .focused($editFocused)
                        .onSubmit { commitEdit() }
                        .onChange(of: editFocused) { focused in
                            if !focused { commitEdit() }
                        }
                } else {
                    Text(task.title)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .strikethrough(task.isCompleted, color: RowColors.textSecondary)
                        .foregroundColor(task.isCompleted ? RowColors.textSecondary : RowColors.text)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut(duration: 0.15), value: task.isCompleted)
                        .onTapGesture(count: 2) { startEditing() }

                    Text(relativeDate(task.createdAt))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(RowColors.textSecondary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isHovered && !isEditing {
                Button(action: { showDeleteConfirmation = true }) {
                    ZStack {
                        Circle()
                            .fill(Color(NSColor.separatorColor).opacity(0.4))
                            .frame(width: 20, height: 20)
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(RowColors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isEditing ? RowColors.editBackground : (isHovered ? RowColors.hoverBackground : Color.clear))
        )
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isEditing)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .alert("Eliminar \"\(task.title)\"", isPresented: $showDeleteConfirmation) {
            Button("Eliminar", role: .destructive) { onDelete() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción eliminará la tarea permanentemente.")
        }
    }

    private func startEditing() {
        editingText = task.title
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            editFocused = true
        }
    }

    private func commitEdit() {
        let trimmed = editingText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && trimmed != task.title {
            onUpdate(trimmed)
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

private enum RowColors {
    static let violet = Color(red: 0.62, green: 0.52, blue: 0.98)
    static let text = Color(NSColor.labelColor)
    static let textSecondary = Color(NSColor.secondaryLabelColor)
    static let border = Color(NSColor.separatorColor)
    static let hoverBackground = Color(NSColor.separatorColor).opacity(0.25)
    static let editBackground = Color(red: 0.62, green: 0.52, blue: 0.98).opacity(0.07)
}
