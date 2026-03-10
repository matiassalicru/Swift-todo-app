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

    var body: some Scene {
        WindowGroup(id: "main-window") {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 380, height: 520)

        MenuBarExtra(store.totalPendingCount > 0 ? "\(store.totalPendingCount)" : "", systemImage: "checkmark.circle") {
            MenuBarContentView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarContentView: View {
    @EnvironmentObject var store: TaskStore

    var body: some View {
        ContentView()
            .environmentObject(store)
    }
}
