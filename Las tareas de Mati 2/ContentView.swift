import SwiftUI

struct TasksContentView: View {
    @EnvironmentObject var store: TaskStore
    @Binding var allSectionsCollapsed: Bool

    @State private var newSectionTitle = ""
    @State private var isAddingSection = false
    @State private var archivedGroupCollapsed = true
    @State private var scrollToSectionId: UUID? = nil
    @FocusState private var sectionInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(store.activeSections) { section in
                            SectionView(section: section, allCollapsed: allSectionsCollapsed, onTaskAdded: {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    scrollProxy.scrollTo("addTask-\(section.id)", anchor: .bottom)
                                }
                            })
                            .id(section.id.uuidString + "-active")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 50)
                }
                .onChange(of: scrollToSectionId) { _, sectionId in
                    guard let sectionId else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        scrollProxy.scrollTo(sectionId.uuidString + "-active", anchor: .bottom)
                    }
                    scrollToSectionId = nil
                }
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
                                    SectionView(section: section, defaultCollapsed: true)
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
            .background(.thinMaterial.opacity(0.7))
        }
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
                    .foregroundColor(AppTheme.textSecondary)
                    .rotationEffect(.degrees(archivedGroupCollapsed ? -90 : 0))
                    .animation(.spring(duration: 0.25), value: archivedGroupCollapsed)
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

            Text("\(store.archivedSections.count)")
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

    private var addSectionView: some View {
        Group {
            if isAddingSection {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AppTheme.violet.opacity(0.5))
                            .frame(width: 7, height: 7)
                        TextField("Nombre de la seccion...", text: $newSectionTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.text)
                            .focused($sectionInputFocused)
                            .onSubmit { addSection() }
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
                    .onTapGesture { sectionInputFocused = true }

                    Button(action: cancelAddSection) {
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
                Button(action: startAddSection) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.violet.opacity(0.75))
                        Text("Nueva seccion")
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
        let newSectionId = store.activeSections.last?.id
        newSectionTitle = ""
        isAddingSection = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollToSectionId = newSectionId
        }
    }
}
