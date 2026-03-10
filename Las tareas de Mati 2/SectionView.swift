import SwiftUI

struct SectionView: View {
    let section: Section
    let onToggleTask: (Task) -> Void
    let onDeleteTask: (Task) -> Void
    let onAddTask: (String) -> Void
    let onDeleteSection: () -> Void
    let onUpdateTitle: (String) -> Void
    let onUpdateTask: (Task, String) -> Void
    let onArchive: () -> Void
    let onUnarchive: () -> Void
    let defaultCollapsed: Bool

    @State private var newTaskTitle = ""
    @State private var isHeaderHovered = false
    @State private var editingTitle = ""
    @State private var isCollapsed: Bool
    @State private var showDeleteConfirmation = false
    @FocusState private var taskInputFocused: Bool
    @FocusState private var titleFocused: Bool

    init(
        section: Section,
        onToggleTask: @escaping (Task) -> Void,
        onDeleteTask: @escaping (Task) -> Void,
        onAddTask: @escaping (String) -> Void,
        onDeleteSection: @escaping () -> Void,
        onUpdateTitle: @escaping (String) -> Void,
        onUpdateTask: @escaping (Task, String) -> Void,
        onArchive: @escaping () -> Void,
        onUnarchive: @escaping () -> Void,
        defaultCollapsed: Bool = false
    ) {
        self.section = section
        self.onToggleTask = onToggleTask
        self.onDeleteTask = onDeleteTask
        self.onAddTask = onAddTask
        self.onDeleteSection = onDeleteSection
        self.onUpdateTitle = onUpdateTitle
        self.onUpdateTask = onUpdateTask
        self.onArchive = onArchive
        self.onUnarchive = onUnarchive
        self.defaultCollapsed = defaultCollapsed
        _isCollapsed = State(initialValue: defaultCollapsed)
    }

    // #region agent log
    private let debugLogPath = "/tmp/debug-bae0c3.log"
    private func debugLog(message: String, data: [String: Any] = [:], hypothesisId: String = "") {
        let payload: [String: Any] = ["sessionId": "bae0c3", "timestamp": Date().timeIntervalSince1970 * 1000, "message": message, "data": data, "hypothesisId": hypothesisId, "location": "SectionView.swift"]
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

    var pendingCount: Int {
        var count = 0
        for task in section.tasks where !task.isCompleted {
            count += 1
        }
        return count
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
                                onToggle: { onToggleTask(task) },
                                onDelete: { onDeleteTask(task) },
                                onUpdate: { title in onUpdateTask(task, title) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                }

                if !section.isArchived { addTaskRow }
            }
        }
        .opacity(section.isArchived ? 0.65 : 1)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SectionColors.cardBackground)
        )
        .onAppear {
            editingTitle = section.title
            // #region agent log
            debugLog(message: "SectionView onAppear", data: ["sectionId": section.id.uuidString, "title": section.title, "isArchived": section.isArchived], hypothesisId: "H-A,H-C")
            // #endregion
        }
        .onChange(of: section.title) { newTitle in
            editingTitle = newTitle
        }
        // #region agent log
        .onChange(of: section.isArchived) { newIsArchived in
            debugLog(message: "SectionView section.isArchived changed", data: ["sectionId": section.id.uuidString, "title": section.title, "newIsArchived": newIsArchived], hypothesisId: "H-A,H-B")
        }
        // #endregion
        .alert("Eliminar \"\(section.title)\"", isPresented: $showDeleteConfirmation) {
            Button("Eliminar", role: .destructive) { onDeleteSection() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción eliminará la sección y todas sus tareas permanentemente.")
        }
    }

    private var sectionHeader: some View {
        // #region agent log
        let _ = { debugLog(message: "sectionHeader rendered", data: ["sectionId": section.id.uuidString, "title": section.title, "isArchived": section.isArchived, "isHeaderHovered": isHeaderHovered], hypothesisId: "H-A,H-B,H-C") }()
        // #endregion
        return HStack(spacing: 8) {
            Button(action: {
                withAnimation(.spring(duration: 0.25)) {
                    isCollapsed.toggle()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SectionColors.textSecondary)
                    .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                    .animation(.spring(duration: 0.25), value: isCollapsed)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(SectionColors.textSecondary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .contentShape(Circle())

            Circle()
                .fill(SectionColors.violet)
                .frame(width: 7, height: 7)

            TextField("Sección sin título", text: $editingTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(SectionColors.text)
                .focused($titleFocused)
                .onSubmit { commitTitle() }
                .onChange(of: titleFocused) { focused in
                    if !focused { commitTitle() }
                }

            Spacer()

            if pendingCount > 0 {
                Text("\(pendingCount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(SectionColors.violet)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(SectionColors.violet.opacity(0.12))
                    .clipShape(Capsule())
            }

            if section.isArchived {
                if isHeaderHovered {
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(SectionColors.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(SectionColors.textSecondary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                Button(action: onUnarchive) {
                    Image(systemName: "arrow.uturn.left")
                        .font(.system(size: 11))
                        .foregroundColor(SectionColors.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(SectionColors.textSecondary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            } else if isHeaderHovered {
                Button(action: onArchive) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 11))
                        .foregroundColor(SectionColors.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(SectionColors.textSecondary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .transition(.opacity.combined(with: .scale(scale: 0.8)))

                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(SectionColors.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(SectionColors.textSecondary.opacity(0.08)))
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
                .foregroundColor(taskInputFocused ? SectionColors.violet : SectionColors.textSecondary)
                .animation(.easeInOut(duration: 0.15), value: taskInputFocused)

            TextField("Agregar tarea...", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(SectionColors.text)
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
            onUpdateTitle(trimmed)
        }
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        onAddTask(title)
        newTaskTitle = ""
        taskInputFocused = true
    }
}

private enum SectionColors {
    static let violet = Color(red: 0.62, green: 0.52, blue: 0.98)
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let text = Color(NSColor.labelColor)
    static let textSecondary = Color(NSColor.secondaryLabelColor)
}
