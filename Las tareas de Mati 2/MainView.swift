import SwiftUI
import UniformTypeIdentifiers

enum AppTab: String, CaseIterable {
    case tasks = "Tareas"
    case notes = "Notas"

    var icon: String {
        switch self {
        case .tasks: return "checkmark.circle"
        case .notes: return "note.text"
        }
    }
}

struct MainView: View {
    @EnvironmentObject var store: TaskStore
    @EnvironmentObject var noteStore: NoteStore
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var selectedTab: AppTab = .tasks
    @State private var allSectionsCollapsed = false
    @State private var showingImportPicker = false
    @State private var showingImportOptions = false
    @State private var importFileURL: URL?
    @State private var showingExportPicker = false
    @State private var showingAccentPicker = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            tabBar
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            switch selectedTab {
            case .tasks:
                TasksContentView(allSectionsCollapsed: $allSectionsCollapsed)
            case .notes:
                NotesView()
            }
        }
        .frame(minWidth: 360, minHeight: 500)
        .background(
            ZStack {
                LinearGradient(
                    colors: isDarkMode
                        ? [Color(red: 0.11, green: 0.11, blue: 0.14), Color(red: 0.09, green: 0.09, blue: 0.12)]
                        : [Color(red: 0.94, green: 0.93, blue: 0.96), Color(red: 0.90, green: 0.91, blue: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(AppTheme.violet.opacity(isDarkMode ? 0.06 : 0.12))
                    .frame(width: 200, height: 200)
                    .blur(radius: 80)
                    .offset(x: -80, y: -60)

                Circle()
                    .fill(Color(red: 0.4, green: 0.5, blue: 1.0).opacity(isDarkMode ? 0.04 : 0.08))
                    .frame(width: 160, height: 160)
                    .blur(radius: 70)
                    .offset(x: 100, y: 180)
            }
        )
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .fileExporter(
            isPresented: $showingExportPicker,
            document: SectionsDocument(sections: store.sections),
            contentType: .json,
            defaultFilename: "tareas.json"
        ) { _ in }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let selectedURL = urls.first else { return }
            importFileURL = selectedURL
            showingImportOptions = true
        }
        .confirmationDialog(
            "¿Cómo querés importar?",
            isPresented: $showingImportOptions,
            titleVisibility: .visible
        ) {
            Button("Reemplazar todo") {
                guard let fileURL = importFileURL else { return }
                store.importSections(from: fileURL, replacing: true)
            }
            Button("Agregar a lo existente") {
                guard let fileURL = importFileURL else { return }
                store.importSections(from: fileURL, replacing: false)
            }
            Button("Cancelar", role: .cancel) {
                importFileURL = nil
            }
        }
    }

    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedTab.rawValue)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.text)

                subtitleText
            }
            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isDarkMode.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                    Circle()
                        .strokeBorder(AppTheme.glassBorder, lineWidth: 0.5)
                        .frame(width: 36, height: 36)
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.violet)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .help(isDarkMode ? "Modo claro" : "Modo oscuro")

            accentColorMenu

            if selectedTab == .tasks {
                Button(action: { showingImportPicker = true }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)
                        Circle()
                            .strokeBorder(AppTheme.glassBorder, lineWidth: 0.5)
                            .frame(width: 36, height: 36)
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.violet)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .help("Importar tareas")

                Button(action: { showingExportPicker = true }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)
                        Circle()
                            .strokeBorder(AppTheme.glassBorder, lineWidth: 0.5)
                            .frame(width: 36, height: 36)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.violet)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .help("Exportar tareas")

                Button(action: {
                    withAnimation(.spring(duration: 0.25)) {
                        allSectionsCollapsed.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)
                        Circle()
                            .strokeBorder(AppTheme.glassBorder, lineWidth: 0.5)
                            .frame(width: 36, height: 36)
                        Image(systemName: allSectionsCollapsed ? "line.3.horizontal" : "line.3.horizontal.decrease")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.violet)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .help(allSectionsCollapsed ? "Expandir secciones" : "Colapsar secciones")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }

    private var accentColorMenu: some View {
        Button(action: { showingAccentPicker.toggle() }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                Circle()
                    .strokeBorder(AppTheme.glassBorder, lineWidth: 0.5)
                    .frame(width: 36, height: 36)
                Image(systemName: "circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help("Color de acento")
        .popover(isPresented: $showingAccentPicker, arrowEdge: .bottom) {
            accentColorPicker
        }
    }

    private var accentColorPicker: some View {
        let columns = [GridItem(.adaptive(minimum: 36), spacing: 8)]
        return VStack(alignment: .leading, spacing: 10) {
            Text("Color de acento")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(AccentColor.allCases) { accentOption in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.accent = accentOption
                        }
                        showingAccentPicker = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(accentOption.color)
                                .frame(width: 28, height: 28)
                                .shadow(color: accentOption.color.opacity(0.5), radius: 4)

                            if themeManager.accent == accentOption {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .help(accentOption.displayName)
                }
            }
        }
        .padding(14)
        .frame(width: 200)
    }

    @ViewBuilder
    private var subtitleText: some View {
        switch selectedTab {
        case .tasks:
            if store.totalPendingCount > 0 {
                Text("\(store.totalPendingCount) pendiente\(store.totalPendingCount == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.violet.opacity(0.7))
            } else {
                Text("Todo listo")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.success.opacity(0.8))
            }
        case .notes:
            let count = noteStore.activeNotes.count
            if count > 0 {
                Text("\(count) nota\(count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.violet.opacity(0.7))
            } else {
                Text("Sin notas")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(selectedTab == tab ? AppTheme.violet : Color.clear)
                    )
                    .foregroundColor(selectedTab == tab ? .white : AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    Capsule()
                        .strokeBorder(AppTheme.glassBorder, lineWidth: 0.5)
                )
        )
    }
}
