import Foundation

class FileScanner {

    /// Scans `folder` and returns a list of `FileItem`s describing each file's proposed move.
    func scan(folder: URL, rules: [OrganizationRule], recursive: Bool) -> [FileItem] {
        let fm = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = recursive
            ? [.skipsHiddenFiles]
            : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]

        guard let enumerator = fm.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: options
        ) else { return [] }

        // Skip files already sitting inside a known category folder
        let categoryNames = Set(rules.map { $0.category })
        var items: [FileItem] = []

        for case let fileURL as URL in enumerator {
            let relative = fileURL.pathComponents.dropFirst(folder.pathComponents.count)
            if let first = relative.first, categoryNames.contains(first) { continue }

            guard let vals = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  vals.isRegularFile == true else { continue }

            let cat = category(for: fileURL, rules: rules)
            let dest = folder
                .appendingPathComponent(cat)
                .appendingPathComponent(fileURL.lastPathComponent)

            // Skip if the file is already in the right destination folder
            if dest.deletingLastPathComponent().standardized == fileURL.deletingLastPathComponent().standardized {
                continue
            }

            items.append(FileItem(sourceURL: fileURL, destinationURL: dest, category: cat))
        }

        return items
    }

    func category(for url: URL, rules: [OrganizationRule]) -> String {
        let name = url.lastPathComponent
        let ext  = url.pathExtension.lowercased()

        if name.hasPrefix("Screenshot") || name.hasPrefix("Screen Shot") {
            return "Screenshots"
        }

        for rule in rules where rule.category != "Screenshots" && rule.category != "Others" {
            if rule.extensions.contains(ext) {
                return rule.category
            }
        }

        return "Others"
    }
}
