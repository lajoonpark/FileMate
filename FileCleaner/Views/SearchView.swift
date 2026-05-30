import SwiftUI

// MARK: - Model

struct SearchResult: Identifiable {
    let id = UUID()
    let url: URL
    let size: String
    let modified: String

    var fileName: String { url.lastPathComponent }
    var path: String { url.path }

    init(url: URL) {
        self.url = url
        let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
        let vals = try? url.resourceValues(forKeys: keys)

        if let byteCount = vals?.fileSize {
            self.size = ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
        } else {
            self.size = "—"
        }

        if let date = vals?.contentModificationDate {
            self.modified = date.formatted(date: .abbreviated, time: .omitted)
        } else {
            self.modified = ""
        }
    }
}

// MARK: - Service

@MainActor
class SearchService: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var isSearching = false
    @Published var searchFolder: URL = FileManager.default.homeDirectoryForCurrentUser

    private var searchTask: Task<Void, Never>?
    private let resultsBatchSize = 100

    func search(query: String) {
        searchTask?.cancel()
        results = []
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            isSearching = false
            return
        }

        isSearching = true
        let folder = searchFolder
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let batchSize = resultsBatchSize

        searchTask = Task.detached(priority: .userInitiated) { [weak self] in
            let fm = FileManager.default
            var found: [SearchResult] = []

            guard let enumerator = fm.enumerator(
                at: folder,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) else {
                await MainActor.run { self?.isSearching = false }
                return
            }

            for case let fileURL as URL in enumerator {
                if Task.isCancelled { break }

                guard let vals = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                      vals.isRegularFile == true else { continue }

                if fileURL.lastPathComponent.localizedCaseInsensitiveContains(trimmed) {
                    found.append(SearchResult(url: fileURL))
                    if found.count % batchSize == 0 {
                        let snapshot = found
                        await MainActor.run { self?.results = snapshot }
                    }
                }
            }

            if !Task.isCancelled {
                await MainActor.run {
                    self?.results = found
                    self?.isSearching = false
                }
            }
        }
    }
}

// MARK: - View

struct SearchView: View {
    @StateObject private var service = SearchService()
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            ZStack {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    emptyPrompt
                } else if service.results.isEmpty && !service.isSearching {
                    noResults
                } else {
                    resultsList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.body.weight(.medium))

            TextField("Search files by name…", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .onChange(of: query) { newVal in
                    service.search(query: newVal)
                }

            if !query.isEmpty {
                Button {
                    query = ""
                    service.search(query: "")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider().frame(height: 20)

            Button(action: pickFolder) {
                Label(service.searchFolder.lastPathComponent, systemImage: "folder")
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 160, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .help("Change the folder to search in")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - States

    private var emptyPrompt: some View {
        VStack(spacing: 18) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Search for any file")
                .font(.title2.bold())
            Text("Type a file name to search inside **\(service.searchFolder.lastPathComponent)**.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var noResults: some View {
        VStack(spacing: 18) {
            Image(systemName: "questionmark.folder")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No files found")
                .font(.title2.bold())
            Text("No files matching **\"\(query)\"** were found in \(service.searchFolder.lastPathComponent).")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Results list

    private var resultsList: some View {
        List(service.results) { result in
            HStack(spacing: 12) {
                Image(systemName: icon(for: result.url))
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(result.fileName)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    Text(result.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(result.size)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(result.modified)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Button("Reveal") {
                    NSWorkspace.shared.activateFileViewerSelecting([result.url])
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Open") {
                    NSWorkspace.shared.open(result.url)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.vertical, 4)
        }
        .overlay(alignment: .top) {
            if !service.results.isEmpty {
                HStack {
                    Spacer()
                    Text("\(service.results.count) result\(service.results.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if service.isSearching {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Searching…").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Helpers

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Search Here"
        panel.message = "Choose the folder FileMate will search in."
        if panel.runModal() == .OK, let url = panel.url {
            service.searchFolder = url
            if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                service.search(query: query)
            }
        }
    }

    private func icon(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp", "svg", "raw":
            return "photo"
        case "mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv":
            return "film"
        case "mp3", "aac", "flac", "wav", "m4a", "ogg", "opus":
            return "music.note"
        case "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "md", "rtf", "pages", "numbers", "key":
            return "doc.text"
        case "swift", "py", "js", "ts", "html", "htm", "css", "json", "yaml", "yml", "sh", "rb", "go", "rs", "c", "cpp", "h", "java", "kt", "xml":
            return "chevron.left.forwardslash.chevron.right"
        case "zip", "tar", "gz", "bz2", "rar", "7z", "xz", "dmg", "pkg":
            return "archivebox"
        default:
            return "doc"
        }
    }
}
