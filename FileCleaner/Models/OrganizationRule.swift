import Foundation

struct OrganizationRule: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var category: String
    var extensions: [String]

    static let defaults: [OrganizationRule] = [
        .init(category: "Images",      extensions: ["jpg", "jpeg", "png", "gif", "heic", "webp", "svg", "raw", "tiff", "bmp"]),
        .init(category: "Videos",      extensions: ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv"]),
        .init(category: "Audio",       extensions: ["mp3", "aac", "flac", "wav", "m4a", "ogg", "opus"]),
        .init(category: "Documents",   extensions: ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md", "rtf", "pages", "numbers", "key", "odt", "csv"]),
        .init(category: "Archives",    extensions: ["zip", "tar", "gz", "bz2", "rar", "7z", "xz", "dmg", "pkg"]),
        // Both "html"/"htm" and "yaml"/"yml" are included because both extensions
        // are in common use and should be captured without relying on case folding.
        .init(category: "Code",        extensions: ["swift", "py", "js", "ts", "html", "htm", "css", "json", "yaml", "yml", "sh", "rb", "go", "rs", "c", "cpp", "h", "java", "kt", "xml"]),
        .init(category: "Screenshots", extensions: []),
        .init(category: "Others",      extensions: [])
    ]

    // MARK: - Presentation helpers

    /// SF Symbol name representing this category.
    var systemImage: String {
        switch category {
        case "Images":      return "photo"
        case "Videos":      return "film"
        case "Audio":       return "music.note"
        case "Documents":   return "doc.text"
        case "Archives":    return "archivebox"
        case "Code":        return "chevron.left.forwardslash.chevron.right"
        case "Screenshots": return "camera.viewfinder"
        default:            return "doc"
        }
    }

    /// Accent color name for this category (used in views).
    var colorName: String {
        switch category {
        case "Images":      return "blue"
        case "Videos":      return "purple"
        case "Audio":       return "pink"
        case "Documents":   return "orange"
        case "Archives":    return "brown"
        case "Code":        return "green"
        case "Screenshots": return "cyan"
        default:            return "gray"
        }
    }

    // MARK: - Extension parsing

    /// Parses a comma-separated string of extensions into a normalized array.
    static func parseExtensions(_ raw: String) -> [String] {
        raw.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }
}
