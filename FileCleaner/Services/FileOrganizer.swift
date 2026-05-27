import Foundation

@MainActor
class FileOrganizer: ObservableObject {
    @Published var progress: Double = 0
    @Published var isRunning = false

    /// Moves all selected `items` to their proposed destinations.
    /// Returns an array of (original, final) URL pairs for undo support.
    func organize(items: [FileItem]) async throws -> [(from: URL, to: URL)] {
        isRunning = true
        progress = 0
        defer { isRunning = false }

        let fm = FileManager.default
        var results: [(from: URL, to: URL)] = []
        let selected = items.filter { $0.isSelected }
        guard !selected.isEmpty else { return [] }

        for (index, item) in selected.enumerated() {
            let destFolder = item.destinationURL.deletingLastPathComponent()
            if !fm.fileExists(atPath: destFolder.path) {
                try fm.createDirectory(at: destFolder, withIntermediateDirectories: true)
            }
            let finalDest = resolveCollision(for: item.destinationURL, fm: fm)
            try fm.moveItem(at: item.sourceURL, to: finalDest)
            results.append((from: item.sourceURL, to: finalDest))
            progress = Double(index + 1) / Double(selected.count)
        }

        return results
    }

    // MARK: - Private

    private func resolveCollision(for url: URL, fm: FileManager) -> URL {
        guard fm.fileExists(atPath: url.path) else { return url }
        let base   = url.deletingPathExtension().lastPathComponent
        let ext    = url.pathExtension
        let folder = url.deletingLastPathComponent()
        for i in 1...10_000 {
            let name      = ext.isEmpty ? "\(base)_\(i)" : "\(base)_\(i).\(ext)"
            let candidate = folder.appendingPathComponent(name)
            if !fm.fileExists(atPath: candidate.path) { return candidate }
        }
        // Fallback: append a UUID to guarantee uniqueness
        let uniqueName = ext.isEmpty ? "\(base)_\(UUID().uuidString)" : "\(base)_\(UUID().uuidString).\(ext)"
        return folder.appendingPathComponent(uniqueName)
    }
}
