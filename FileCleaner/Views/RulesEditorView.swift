import SwiftUI

struct RulesEditorView: View {
    @Binding var rules: [OrganizationRule]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            rulesList
            Divider()
            footerBar
        }
        .frame(minWidth: 460, minHeight: 520)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Organization Rules")
                    .font(.title2.bold())
                Text("Edit the extensions that belong to each category.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Rules list

    private var rulesList: some View {
        List($rules) { $rule in
            if rule.category != "Others" {
                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Extensions")
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        TextField(
                            "Comma-separated (e.g. jpg, png)",
                            text: Binding(
                                get: { rule.extensions.joined(separator: ", ") },
                                set: {
                                    rule.extensions = $0
                                        .components(separatedBy: ",")
                                        .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                                        .filter { !$0.isEmpty }
                                }
                            )
                        )
                    }
                    .padding(.vertical, 2)
                } header: {
                    Label(rule.category, systemImage: iconName(for: rule.category))
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Button("Reset to Defaults") { rules = OrganizationRule.defaults }
                .foregroundStyle(.red)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Helpers

    private func iconName(for category: String) -> String {
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
}
