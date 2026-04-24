import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

@main
struct TareasApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = TaskStore()
    @StateObject private var noteStore = NoteStore()

    var body: some Scene {
        WindowGroup(id: "main-window") {
            MainView()
                .environmentObject(store)
                .environmentObject(noteStore)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 380, height: 520)

        MenuBarExtra(store.totalPendingCount > 0 ? "\(store.totalPendingCount)" : "", systemImage: "checkmark.circle") {
            MenuBarContentView()
                .environmentObject(store)
                .environmentObject(noteStore)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarContentView: View {
    @EnvironmentObject var store: TaskStore
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var allSectionsCollapsed = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(store.totalPendingCount > 0
                     ? "\(store.totalPendingCount) pendiente\(store.totalPendingCount == 1 ? "" : "s")"
                     : "Todo listo")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()

                Button(action: {
                    withAnimation(.spring(duration: 0.25)) {
                        allSectionsCollapsed.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 28, height: 28)
                        Circle()
                            .strokeBorder(AppTheme.glassBorder, lineWidth: 0.5)
                            .frame(width: 28, height: 28)
                        Image(systemName: allSectionsCollapsed ? "line.3.horizontal" : "line.3.horizontal.decrease")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.violet)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)

            TasksContentView(allSectionsCollapsed: $allSectionsCollapsed)
        }
        .environmentObject(store)
        .frame(width: 440, height: 480)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .background(WindowAppearanceSetter(isDarkMode: isDarkMode))
    }
}

private struct WindowAppearanceSetter: NSViewRepresentable {
    let isDarkMode: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.window?.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
    }
}
