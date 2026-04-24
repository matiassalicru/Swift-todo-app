import SwiftUI

struct SectionView: View {
    let section: Section
    let defaultCollapsed: Bool
    var allCollapsed: Bool = false
    var onTaskAdded: (() -> Void)? = nil

    @EnvironmentObject private var store: TaskStore

    @State private var newTaskTitle = ""
    @State private var isHeaderHovered = false
    @State private var editingTitle = ""
    @State private var isCollapsed: Bool
    @State private var showDeleteConfirmation = false
    @FocusState private var taskInputFocused: Bool
    @FocusState private var titleFocused: Bool

    init(section: Section, defaultCollapsed: Bool = false, allCollapsed: Bool = false, onTaskAdded: (() -> Void)? = nil) {
        self.section = section
        self.defaultCollapsed = defaultCollapsed
        self.allCollapsed = allCollapsed
        self.onTaskAdded = onTaskAdded
        _isCollapsed = State(initialValue: defaultCollapsed || allCollapsed)
    }

    private var pendingCount: Int {
        section.tasks.filter { !$0.isCompleted }.count
    }

    private var otherActiveSections: [(id: UUID, title: String)] {
        store.activeSections
            .filter { $0.id != section.id }
            .map { (id: $0.id, title: $0.title) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader

            if !isCollapsed {
                if !section.tasks.isEmpty {
                    Divider()
                        .padding(.horizontal, 12)
                        .padding(.top, 4)

                    VStack(spacing: 2) {
                        ForEach(section.tasks) { task in
                            TaskRow(
                                task: task,
                                onToggle: { store.toggleTask(task, inSection: section) },
                                onDelete: { store.deleteTask(task, fromSection: section) },
                                onUpdate: { title in store.updateTask(task, title: title, inSection: section) },
                                availableSections: otherActiveSections,
                                onMove: { destinationId in store.moveTask(task, fromSection: section, toSectionId: destinationId) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                }

                if !section.isArchived {
                    addTaskRow
                        .id("addTask-\(section.id)")
                }
            }
        }
        .opacity(section.isArchived ? 0.65 : 1)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: AppTheme.glassShadow, radius: 10, y: 4)
        )
        .onAppear {
            editingTitle = section.title
        }
        .onChange(of: section.title) { _, newTitle in
            editingTitle = newTitle
        }
        .onChange(of: allCollapsed) { _, collapsed in
            withAnimation(.spring(duration: 0.25)) {
                isCollapsed = collapsed
            }
        }
        .overlay(alignment: .top) {
            if showDeleteConfirmation {
                HStack(spacing: 10) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)

                    Text("¿Eliminar \"\(section.title)\"?")
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

                    Button("Eliminar") { store.deleteSection(section) }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.85)))
            }
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation(.spring(duration: 0.25)) {
                    isCollapsed.toggle()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                    .animation(.spring(duration: 0.25), value: isCollapsed)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .contentShape(Circle())

            Circle()
                .fill(AppTheme.violet)
                .frame(width: 7, height: 7)

            TextField("Sección sin título", text: $editingTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.text)
                .focused($titleFocused)
                .onSubmit { commitTitle() }
                .onChange(of: titleFocused) { _, focused in
                    if !focused { commitTitle() }
                }

            Spacer()

            if pendingCount > 0 {
                Text("\(pendingCount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.violet)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(AppTheme.violet.opacity(0.12))
                    .clipShape(Capsule())
            }

            if section.isArchived {
                if isHeaderHovered {
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                Button(action: { store.unarchiveSection(section) }) {
                    Image(systemName: "arrow.uturn.left")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            } else if isHeaderHovered {
                Button(action: { store.archiveSection(section) }) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .transition(.opacity.combined(with: .scale(scale: 0.8)))

                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHeaderHovered = hovering
            }
        }
    }

    private var addTaskRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(taskInputFocused ? AppTheme.violet : AppTheme.textSecondary)
                .animation(.easeInOut(duration: 0.15), value: taskInputFocused)

            TextField("Agregar tarea...", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(AppTheme.text)
                .focused($taskInputFocused)
                .onSubmit { addTask() }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private func commitTitle() {
        let trimmed = editingTitle.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            editingTitle = section.title
        } else {
            store.updateSectionTitle(section, title: trimmed)
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        store.addTask(title: title, toSection: section)
        newTaskTitle = ""
        taskInputFocused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            onTaskAdded?()
        }
    }
}
