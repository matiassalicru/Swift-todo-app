import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TaskStore
    @State private var newSectionTitle = ""
    @State private var isAddingSection = false
    @State private var archivedGroupCollapsed = true
    @FocusState private var sectionInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(store.activeSections) { section in
                        SectionView(
                            section: section,
                            onToggleTask: { task in store.toggleTask(task, inSection: section) },
                            onDeleteTask: { task in store.deleteTask(task, fromSection: section) },
                            onAddTask: { title in store.addTask(title: title, toSection: section) },
                            onDeleteSection: { store.deleteSection(section) },
                            onUpdateTitle: { title in store.updateSectionTitle(section, title: title) },
                            onUpdateTask: { task, title in store.updateTask(task, title: title, inSection: section) },
                            onArchive: { store.archiveSection(section) },
                            onUnarchive: {}
                        )
                        .id(section.id.uuidString + "-active")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            VStack(spacing: 0) {
                if !store.archivedSections.isEmpty {
                    Divider()

                        archivedGroupHeader
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    if !archivedGroupCollapsed {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                ForEach(store.archivedSections) { section in
                                    SectionView(
                                        section: section,
                                        onToggleTask: { task in store.toggleTask(task, inSection: section) },
                                        onDeleteTask: { task in store.deleteTask(task, fromSection: section) },
                                        onAddTask: { _ in },
                                        onDeleteSection: { store.deleteSection(section) },
                                        onUpdateTitle: { title in store.updateSectionTitle(section, title: title) },
                                        onUpdateTask: { task, title in store.updateTask(task, title: title, inSection: section) },
                                        onArchive: {},
                                        onUnarchive: { store.unarchiveSection(section) },
                                        defaultCollapsed: true
                                    )
                                    .id(section.id.uuidString + "-archived")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                        .frame(maxHeight: 200)
                    }
                }

                Divider()

                addSectionView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 360, minHeight: 500)
        .background(AppColors.background)
    }

    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tareas")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.text)
                if store.totalPendingCount > 0 {
                    Text("\(store.totalPendingCount) pendiente\(store.totalPendingCount == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.violet.opacity(0.7))
                } else {
                    Text("Todo listo")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.success.opacity(0.8))
                }
            }
            Spacer()
            Circle()
                .fill(AppColors.violet.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.violet)
                )
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    private var archivedGroupHeader: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation(.spring(duration: 0.25)) {
                    archivedGroupCollapsed.toggle()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .rotationEffect(.degrees(archivedGroupCollapsed ? -90 : 0))
                    .animation(.spring(duration: 0.25), value: archivedGroupCollapsed)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(AppColors.textSecondary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .contentShape(Circle())

            Image(systemName: "archivebox")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            Text("Archivados")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            Text("\(store.archivedSections.count)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(AppColors.textSecondary.opacity(0.1))
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private var addSectionView: some View {
        Group {
            if isAddingSection {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AppColors.violet.opacity(0.5))
                            .frame(width: 7, height: 7)
                        TextField("Nombre de la sección...", text: $newSectionTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.text)
                            .focused($sectionInputFocused)
                            .onSubmit { addSection() }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColors.violet.opacity(0.45), lineWidth: 1.5)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { sectionInputFocused = true }

                    Button(action: cancelAddSection) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(AppColors.textSecondary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                }
            } else {
                Button(action: startAddSection) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.violet.opacity(0.75))
                        Text("Nueva sección")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.violet.opacity(0.75))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppColors.violet.opacity(0.35), lineWidth: 1.5)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func startAddSection() {
        isAddingSection = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sectionInputFocused = true
        }
    }

    private func cancelAddSection() {
        isAddingSection = false
        newSectionTitle = ""
    }

    private func addSection() {
        let title = newSectionTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            cancelAddSection()
            return
        }
        store.addSection(title: title)
        newSectionTitle = ""
        isAddingSection = false
    }
}

private enum AppColors {
    static let violet = Color(red: 0.62, green: 0.52, blue: 0.98)
    static let success = Color(red: 0.25, green: 0.80, blue: 0.55)
    static let background = Color(NSColor.windowBackgroundColor)
    static let text = Color(NSColor.labelColor)
    static let textSecondary = Color(NSColor.secondaryLabelColor)
}
