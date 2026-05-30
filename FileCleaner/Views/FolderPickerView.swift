import SwiftUI
import UniformTypeIdentifiers

struct FolderPickerView: View {
    let onFolderSelected: (URL) -> Void

    @State private var isTargeted = false

    var body: some View {
        VStack {
            Spacer()
            dropZone
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    isTargeted ? Color.blue : Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isTargeted ? Color.blue.opacity(0.08) : Color.clear)
                )

            VStack(spacing: 18) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(isTargeted ? .blue : .secondary)

                Text("Drop a Folder Here")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(isTargeted ? .blue : .primary)

                Text("or")
                    .foregroundStyle(.secondary)

                Button("Choose Folder…") { openPanel() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(48)
        }
        .frame(width: 480, height: 300)
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted, perform: handleDrop)
        .animation(.easeInOut(duration: 0.15), value: isTargeted)
    }

    // MARK: - Private

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Folder"
        panel.message = "Select the folder you want FileMate to organize."
        if panel.runModal() == .OK, let url = panel.url {
            onFolderSelected(url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.hasDirectoryPath else { return }
            DispatchQueue.main.async { onFolderSelected(url) }
        }
        return true
    }
}
