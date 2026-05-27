import SwiftUI

struct PreviewView: View {
    @State var items: [FileItem]
    let onConfirm: ([FileItem]) -> Void
    let onBack: () -> Void

    @State private var sortOrder = [KeyPathComparator(\FileItem.category)]

    private var selectedCount: Int { items.filter { $0.isSelected }.count }

    var body: some View {
        VStack(spacing: 0) {
            if items.isEmpty {
                emptyState
            } else {
                fileTable
            }
            Divider()
            footer
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Everything looks clean!")
                .font(.title2.bold())
            Text("No files need to be moved in this folder.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Table

    private var fileTable: some View {
        Table(items, sortOrder: $sortOrder) {
            TableColumn("") { item in
                Toggle("", isOn: selectionBinding(for: item.id))
                    .labelsHidden()
            }
            .width(30)

            TableColumn("File Name", value: \.fileName) { item in
                Label(item.fileName, systemImage: iconName(for: item.category))
                    .foregroundStyle(color(for: item.category))
                    .lineLimit(1)
            }

            TableColumn("Category", value: \.category)
                .width(min: 90, ideal: 100, max: 130)

            TableColumn("Will Move To") { item in
                Text(item.destinationPath)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .onChange(of: sortOrder) { newOrder in
            items.sort(using: newOrder)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Button("Select All")   { items.indices.forEach { items[$0].isSelected = true } }
            Button("Deselect All") { items.indices.forEach { items[$0].isSelected = false } }
            Spacer()
            Text("\(selectedCount) of \(items.count) file\(items.count == 1 ? "" : "s") selected")
                .foregroundStyle(.secondary)
            Button("Back", action: onBack)
            Button("Run Organizer") { onConfirm(items) }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
        }
        .padding(12)
    }

    // MARK: - Helpers

    private func selectionBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { items.first(where: { $0.id == id })?.isSelected ?? false },
            set: { newValue in
                if let idx = items.firstIndex(where: { $0.id == id }) {
                    items[idx].isSelected = newValue
                }
            }
        )
    }

    private func iconName(for category: String) -> String {
        OrganizationRule.defaults.first(where: { $0.category == category })?.systemImage ?? "doc"
    }

    private func color(for category: String) -> Color {
        switch OrganizationRule.defaults.first(where: { $0.category == category })?.colorName {
        case "blue":   return .blue
        case "purple": return .purple
        case "pink":   return .pink
        case "orange": return .orange
        case "brown":  return .brown
        case "green":  return .green
        case "cyan":   return .cyan
        default:       return .gray
        }
    }
}
