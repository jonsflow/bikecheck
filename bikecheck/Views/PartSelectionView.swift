import SwiftUI

struct PartSelectionView: View {
    @Environment(\.dismiss) var dismiss

    let initialSelectedIds: Set<String>
    let onConfirm: ([String]) -> Void

    @State private var selectedIds: Set<String>

    private var confirmLabel: String {
        initialSelectedIds.isEmpty ? "Add" : "Done"
    }

    init(initialSelectedIds: Set<String> = [], onConfirm: @escaping ([String]) -> Void) {
        self.initialSelectedIds = initialSelectedIds
        self.onConfirm = onConfirm
        _selectedIds = State(initialValue: initialSelectedIds)
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(PartTemplateService.shared.getAllCategories()) { category in
                    let parts = PartTemplateService.shared.getTemplatesByCategory(category.id)
                    if !parts.isEmpty {
                        Section(header: Label(category.name, systemImage: category.icon)) {
                            ForEach(parts) { part in
                                partRow(for: part)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Choose Parts to Track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(confirmLabel) {
                        onConfirm(Array(selectedIds))
                        dismiss()
                    }
                    .disabled(selectedIds.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func partRow(for part: PartTemplate) -> some View {
        Button(action: {
            if selectedIds.contains(part.id) {
                selectedIds.remove(part.id)
            } else {
                selectedIds.insert(part.id)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: part.icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(part.name)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text("\(Int(part.defaultIntervalHours)) hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if selectedIds.contains(part.id) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("part_\(part.id)")
    }
}
