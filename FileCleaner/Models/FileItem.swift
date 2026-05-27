import Foundation

struct FileItem: Identifiable {
    let id = UUID()
    let sourceURL: URL
    let destinationURL: URL
    let category: String
    var isSelected: Bool = true

    var fileName: String { sourceURL.lastPathComponent }
    var sourcePath: String { sourceURL.path }
    var destinationPath: String { destinationURL.path }
}
