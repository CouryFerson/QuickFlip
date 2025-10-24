import SwiftUI

struct BulkStorageLocationSheet: View {
    let selectedCount: Int
    let onUpdate: (String) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var locationText: String = ""
    @State private var recentLocations: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Set storage location for \(selectedCount) selected item\(selectedCount == 1 ? "" : "s")")
                        .font(.headline)

                    TextField("e.g., Garage shelf, Closet bin 3", text: $locationText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 8)

                    if !recentLocations.isEmpty {
                        Text("Recent Locations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentLocations, id: \.self) { location in
                                    Button(action: { locationText = location }) {
                                        Text(location)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Storage Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = locationText.trimmingCharacters(in: .whitespacesAndNewlines)
                        onUpdate(trimmed)
                        if !trimmed.isEmpty {
                            saveToRecentLocations(trimmed)
                        }
                        dismiss()
                    }
                    .disabled(locationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            loadRecentLocations()
        }
    }

    private func loadRecentLocations() {
        if let saved = UserDefaults.standard.stringArray(forKey: "recentStorageLocations") {
            recentLocations = saved
        }
    }

    private func saveToRecentLocations(_ location: String) {
        guard !location.isEmpty else { return }

        var locations = recentLocations
        // Remove if already exists
        locations.removeAll { $0 == location }
        // Add to front
        locations.insert(location, at: 0)
        // Keep only last 5
        locations = Array(locations.prefix(5))

        UserDefaults.standard.set(locations, forKey: "recentStorageLocations")
    }
}
