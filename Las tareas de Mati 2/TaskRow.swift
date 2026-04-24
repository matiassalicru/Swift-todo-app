import SwiftUI

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> Void
    var availableSections: [(id: UUID, title: String)] = []
    var onMove: (UUID) -> Void = { _ in }

    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editingText = ""
    @State private var showDeleteConfirmation = false
    @FocusState private var editFocused: Bool

    var body: some View {
        Group {
            if showDeleteConfirmation {
                HStack(spacing: 10) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)

                    Text("¿Eliminar \"\(task.title)\"?")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    Button("Cancelar") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showDeleteConfirmation = false
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                    Button("Eliminar") { onDelete() }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.75)))
            } else {
                HStack(spacing: 12) {
                    Button(action: onToggle) {
                        ZStack {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 20, height: 20)
                            Circle()
                                .strokeBorder(
                                    task.isCompleted ? AppTheme.violet : AppTheme.border,
                                    lineWidth: 1.5
                                )
                                .frame(width: 20, height: 20)
                            if task.isCompleted {
                                Circle()
                                    .fill(AppTheme.violet)
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
                                .foregroundColor(AppTheme.text)
                                .focused($editFocused)
                                .onSubmit { commitEdit() }
                                .onChange(of: editFocused) {_, focused in
                                    if !focused { commitEdit() }
                                }
                        } else {
                            Text(task.title)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .strikethrough(task.isCompleted, color: AppTheme.textSecondary)
                                .foregroundColor(task.isCompleted ? AppTheme.textSecondary : AppTheme.text)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .animation(.easeInOut(duration: 0.15), value: task.isCompleted)
                                .onTapGesture(count: 2) { startEditing() }

                            Text(relativeDate(task.createdAt))
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if isHovered && !isEditing {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showDeleteConfirmation = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(width: 20, height: 20)
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(AppTheme.textSecondary)
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
                        .fill(isEditing ? AppTheme.violet.opacity(0.1) : (isHovered ? Color.primary.opacity(0.06) : Color.clear))
                )
                .animation(.easeInOut(duration: 0.1), value: isHovered)
                .animation(.easeInOut(duration: 0.1), value: isEditing)
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isHovered = hovering
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showDeleteConfirmation)
        .contextMenu {
            if !availableSections.isEmpty {
                Menu("Mover a...") {
                    ForEach(availableSections, id: \.id) { section in
                        Button(section.title) {
                            onMove(section.id)
                        }
                    }
                }
            }
            Button("Eliminar", role: .destructive) {
                onDelete()
            }
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
