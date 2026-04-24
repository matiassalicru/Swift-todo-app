#if DEBUG
import SwiftUI
import AppKit

@MainActor
enum AppIconExporter {
    static let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]

    static func promptAndExport() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Seleccioná la carpeta AppIcon.appiconset"
        panel.prompt = "Exportar acá"

        guard panel.runModal() == .OK, let directory = panel.url else { return }

        let didStartAccessing = directory.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { directory.stopAccessingSecurityScopedResource() } }

        export(to: directory)
    }

    private static func export(to directory: URL) {
        var exported: [String] = []
        var failed: [String] = []

        for pixelSize in sizes {
            let view = AppIconView(size: CGFloat(pixelSize))
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0

            guard let cgImage = renderer.cgImage else {
                failed.append("icon_\(pixelSize)x\(pixelSize).png: render failed")
                continue
            }

            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            bitmap.size = NSSize(width: pixelSize, height: pixelSize)

            guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
                failed.append("icon_\(pixelSize)x\(pixelSize).png: PNG encoding failed")
                continue
            }

            let filename = "icon_\(pixelSize)x\(pixelSize).png"
            let fileURL = directory.appendingPathComponent(filename)

            do {
                try pngData.write(to: fileURL)
                exported.append(filename)
            } catch {
                failed.append("\(filename): \(error.localizedDescription)")
            }
        }

        let alert = NSAlert()
        if failed.isEmpty {
            alert.messageText = "Exportación completa"
            alert.informativeText = "Se escribieron \(exported.count) íconos en:\n\(directory.path)"
            alert.alertStyle = .informational
        } else {
            alert.messageText = "Exportación con errores"
            alert.informativeText =
                "Exportados: \(exported.count)\n\nFallidos:\n\(failed.joined(separator: "\n"))"
            alert.alertStyle = .warning
        }
        alert.runModal()
    }
}
#endif
