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
        .init(category: "Code",        extensions: ["swift", "py", "js", "ts", "html", "htm", "css", "json", "yaml", "yml", "sh", "rb", "go", "rs", "c", "cpp", "h", "java", "kt", "xml"]),
        .init(category: "Screenshots", extensions: []),
        .init(category: "Others",      extensions: [])
    ]
}
