import Foundation

struct MoveRecord: Codable {
    let from: String
    let to: String
}

/// Persists a log of file moves so they can be reversed in one shot.
class AppUndoManager {
    private let logURL: URL

    init() {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = support.appendingPathComponent("FileCleaner", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        logURL = dir.appendingPathComponent("undo_log.json")
    }

    /// Persists `records` to disk so `undoAll()` can revert them later.
    func save(records: [(from: URL, to: URL)]) throws {
        let encoded = records.map { MoveRecord(from: $0.from.path, to: $0.to.path) }
        let data = try JSONEncoder().encode(encoded)
        try data.write(to: logURL, options: .atomic)
    }

    /// Moves every file back to its original location in reverse order.
    /// Deletes the log when done.
    @discardableResult
    func undoAll() throws -> Int {
        let data    = try Data(contentsOf: logURL)
        let records = try JSONDecoder().decode([MoveRecord].self, from: data)
        let fm      = FileManager.default
        var count   = 0

        for record in records.reversed() {
            let src = URL(fileURLWithPath: record.from)
            let dst = URL(fileURLWithPath: record.to)
            guard fm.fileExists(atPath: dst.path) else { continue }
            let srcFolder = src.deletingLastPathComponent()
            if !fm.fileExists(atPath: srcFolder.path) {
                try fm.createDirectory(at: srcFolder, withIntermediateDirectories: true)
            }
            if !fm.fileExists(atPath: src.path) {
                try fm.moveItem(at: dst, to: src)
                count += 1
            }
        }

        try fm.removeItem(at: logURL)
        return count
    }

    var hasHistory: Bool {
        FileManager.default.fileExists(atPath: logURL.path)
    }
}
