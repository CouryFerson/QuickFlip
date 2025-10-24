import SwiftUI

struct BulkStatusUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let selectedCount: Int
    let onUpdate: (ItemStatus) -> Void

    @State private var selectedStatus: ItemStatus = .readyToList

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Update the status for \(selectedCount) selected item\(selectedCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                }

                Section {
                    statusOption(for: .readyToList, title: "Ready to List", icon: "checkmark.circle.fill", color: .orange)
                    statusOption(for: .listed, title: "Listed", icon: "tag.fill", color: .blue)
                    statusOption(for: .sold, title: "Sold", icon: "dollarsign.circle.fill", color: .green)
                }
            }
            .navigationTitle("Update Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        onUpdate(selectedStatus)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func statusOption(for status: ItemStatus, title: String, icon: String, color: Color) -> some View {
        Button {
            selectedStatus = status
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if selectedStatus == status {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
