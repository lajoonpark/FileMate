import SwiftUI

// MARK: - App mode

enum AppMode: String, CaseIterable {
    case organize = "Organize"
    case search   = "Search"

    var systemImage: String {
        switch self {
        case .organize: return "folder.badge.gearshape"
        case .search:   return "magnifyingglass"
        }
    }
}

// MARK: - Organize state machine

enum AppState {
    case pickFolder
    case scanning
    case preview([FileItem])
    case organizing
    case done(movedCount: Int, folderCount: Int)
    case undone(count: Int)
    case error(String)
}

// MARK: - Content view

struct ContentView: View {
    @StateObject private var organizer = FileOrganizer()
    @State private var appMode: AppMode = .organize
    @State private var appState: AppState = .pickFolder
    @State private var selectedFolder: URL?
    @State private var rules: [OrganizationRule] = OrganizationRule.defaults
    @State private var recursive = false
    @State private var showRulesEditor = false
    @State private var moveRecords: [(from: URL, to: URL)] = []

    private let undoMgr = AppUndoManager()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
        .sheet(isPresented: $showRulesEditor) {
            RulesEditorView(rules: $rules)
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: 12) {
            // App brand
            Label("FileMate", systemImage: "sparkles")
                .font(.headline.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .labelStyle(.titleAndIcon)

            Divider().frame(height: 18)

            // Mode picker
            Picker("Mode", selection: $appMode) {
                ForEach(AppMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 210)
            .onChange(of: appMode) { _ in
                // Reset organize flow when switching away
                if appMode == .search { appState = .pickFolder }
            }

            Spacer()

            // Organize-only controls
            if appMode == .organize {
                Toggle("Recursive", isOn: $recursive)
                    .toggleStyle(.checkbox)
                    .help("Also organize files inside sub-folders")
                Button("Rules…") { showRulesEditor = true }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch appMode {
        case .search:
            SearchView()

        case .organize:
            organizeContent
        }
    }

    @ViewBuilder
    private var organizeContent: some View {
        switch appState {
        case .pickFolder:
            FolderPickerView { folder in
                selectedFolder = folder
                startScan(folder: folder)
            }

        case .scanning:
            VStack(spacing: 16) {
                ProgressView()
                Text("Scanning…").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .preview(let items):
            PreviewView(items: items) { confirmed in
                startOrganize(items: confirmed)
            } onBack: {
                appState = .pickFolder
            }

        case .organizing:
            VStack(spacing: 16) {
                ProgressView(value: organizer.progress)
                    .progressViewStyle(.linear)
                    .frame(width: 320)
                Text("Organizing… \(Int(organizer.progress * 100))%")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .done(let movedCount, let folderCount):
            CleanProgressView(
                movedCount: movedCount,
                folderCount: folderCount,
                folder: selectedFolder,
                canUndo: undoMgr.hasHistory,
                onDone: { appState = .pickFolder },
                onUndo: performUndo
            )

        case .undone(let count):
            VStack(spacing: 20) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)
                Text("Undone — \(count) file\(count == 1 ? "" : "s") restored.")
                    .font(.title2)
                Button("Start Over") { appState = .pickFolder }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .error(let msg):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                Text(msg).multilineTextAlignment(.center)
                Button("Start Over") { appState = .pickFolder }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Actions

    private func startScan(folder: URL) {
        appState = .scanning
        let localRules = rules
        let localRecursive = recursive
        Task.detached(priority: .userInitiated) {
            let items = FileScanner().scan(folder: folder, rules: localRules, recursive: localRecursive)
            await MainActor.run { appState = .preview(items) }
        }
    }

    private func startOrganize(items: [FileItem]) {
        appState = .organizing
        Task {
            do {
                let records = try await organizer.organize(items: items)
                moveRecords = records
                try undoMgr.save(records: records)
                let folderCount = Set(records.map {
                    $0.to.deletingLastPathComponent().lastPathComponent
                }).count
                appState = .done(movedCount: records.count, folderCount: folderCount)
            } catch {
                appState = .error(error.localizedDescription)
            }
        }
    }

    private func performUndo() {
        Task {
            do {
                let count = try undoMgr.undoAll()
                appState = .undone(count: count)
            } catch {
                appState = .error("Undo failed: \(error.localizedDescription)")
            }
        }
    }
}
