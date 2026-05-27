import SwiftUI

struct CleanProgressView: View {
    let movedCount: Int
    let folderCount: Int
    let folder: URL?
    let canUndo: Bool
    let onDone: () -> Void
    let onUndo: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 76))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("All done!")
                    .font(.largeTitle.bold())
                Text(summary)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                if canUndo {
                    Button("Undo All", action: onUndo)
                        .buttonStyle(.bordered)
                        .foregroundStyle(.orange)
                }
                if let folder {
                    Button("Open Folder") { NSWorkspace.shared.open(folder) }
                        .buttonStyle(.bordered)
                }
                Button("Done", action: onDone)
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var summary: String {
        let files   = movedCount == 1 ? "1 file"    : "\(movedCount) files"
        let folders = folderCount == 1 ? "1 folder" : "\(folderCount) folders"
        return "Moved \(files) into \(folders)."
    }
}
