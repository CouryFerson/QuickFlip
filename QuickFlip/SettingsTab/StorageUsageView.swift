//
//  StorageUsageView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 9/22/25.
//

import SwiftUI

struct StorageUsageView: View {
    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var storageStats: StorageStats?
    @State private var isLoading = true
    @State private var showingClearCacheAlert = false
    @State private var showingClearPhotosAlert = false

    var body: some View {
        List {
            if isLoading {
                loadingSection
            } else {
                overviewSection
                dataBreakdownSection
                storageActionsSection
            }
        }
        .navigationTitle("Storage Usage")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStorageStats()
        }
        .refreshable {
            await loadStorageStats()
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Clear", role: .destructive) {
                clearCache()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear temporary files and cached data. Your scanned items will not be affected.")
        }
        .alert("Clear All Photos", isPresented: $showingClearPhotosAlert) {
            Button("Clear", role: .destructive) {
                clearAllPhotos()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all stored photos. Analysis results will be preserved but photos cannot be recovered.")
        }
    }
}

// MARK: - View Sections
private extension StorageUsageView {

    @ViewBuilder
    var loadingSection: some View {
        Section {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Calculating storage usage...")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    @ViewBuilder
    var overviewSection: some View {
        Section {
            VStack(spacing: 16) {
                storageOverviewCard
                itemCountCard
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    var storageOverviewCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "internaldrive")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text(totalStorageText)
                .font(.title2)
                .fontWeight(.bold)

            Text("Total Storage Used")
                .font(.subheadline)
                .foregroundColor(.gray)

            if let stats = storageStats {
                storageProgressBar(stats)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    @ViewBuilder
    func storageProgressBar(_ stats: StorageStats) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Used")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Text("Available")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            ProgressView(value: Double(stats.totalBytes), total: Double(stats.deviceCapacity))
                .progressViewStyle(LinearProgressViewStyle(tint: storageColor(for: stats)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }

    @ViewBuilder
    var itemCountCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(itemStorage.totalItemCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Text("Items Scanned")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let stats = storageStats {
                VStack(spacing: 4) {
                    Text("\(stats.photoCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Text("Photos Stored")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    @ViewBuilder
    var dataBreakdownSection: some View {
        Section("Storage Breakdown") {
            if let stats = storageStats {
                dataTypeRow(
                    icon: "photo",
                    title: "Photos",
                    size: stats.photosSize,
                    color: .blue,
                    description: "Original scanned item photos"
                )

                dataTypeRow(
                    icon: "doc.text",
                    title: "Analysis Data",
                    size: stats.analysisSize,
                    color: .green,
                    description: "AI analysis results and metadata"
                )

                dataTypeRow(
                    icon: "gearshape",
                    title: "App Data",
                    size: stats.appDataSize,
                    color: .orange,
                    description: "Settings and user preferences"
                )

                dataTypeRow(
                    icon: "externaldrive",
                    title: "Cache",
                    size: stats.cacheSize,
                    color: .gray,
                    description: "Temporary files and cached data"
                )
            }
        }
    }

    @ViewBuilder
    func dataTypeRow(icon: String, title: String, size: Int64, color: Color, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(formatBytes(size))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    var storageActionsSection: some View {
        Section("Storage Management") {
            clearCacheRow
            clearPhotosRow
            exportDataRow
        }
    }

    @ViewBuilder
    var clearCacheRow: some View {
        Button {
            showingClearCacheAlert = true
        } label: {
            HStack {
                Label("Clear Cache", systemImage: "trash")
                    .foregroundColor(.orange)

                Spacer()

                if let stats = storageStats {
                    Text(formatBytes(stats.cacheSize))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    var clearPhotosRow: some View {
        Button {
            showingClearPhotosAlert = true
        } label: {
            HStack {
                Label("Clear All Photos", systemImage: "photo.on.rectangle")
                    .foregroundColor(.red)

                Spacer()

                if let stats = storageStats {
                    Text(formatBytes(stats.photosSize))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    var exportDataRow: some View {
        NavigationLink(destination: ExportDataView().environmentObject(itemStorage)) {
            Label("Export Data", systemImage: "square.and.arrow.up")
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Helper Methods
private extension StorageUsageView {

    var totalStorageText: String {
        guard let stats = storageStats else { return "Calculating..." }
        return formatBytes(stats.totalBytes)
    }

    func storageColor(for stats: StorageStats) -> Color {
        let percentage = Double(stats.totalBytes) / Double(stats.deviceCapacity)
        if percentage > 0.9 { return .red }
        if percentage > 0.7 { return .orange }
        return .blue
    }

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func loadStorageStats() async {
        isLoading = true

        // Simulate loading time for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // TODO: Calculate actual storage usage from your data
        // This would involve checking file sizes of stored photos, database size, etc.
        let mockStats = StorageStats(
            totalBytes: 2_400_000, // 2.4 MB
            photosSize: 1_800_000, // 1.8 MB
            analysisSize: 400_000,  // 400 KB
            appDataSize: 150_000,   // 150 KB
            cacheSize: 50_000,      // 50 KB
            photoCount: itemStorage.totalItemCount,
            deviceCapacity: 64_000_000_000 // 64 GB device
        )

        await MainActor.run {
            self.storageStats = mockStats
            self.isLoading = false
        }
    }

    func clearCache() {
        Task {
            // TODO: Implement cache clearing
            // This would clear temporary files, cached images, etc.
            await loadStorageStats() // Refresh after clearing
        }
    }

    func clearAllPhotos() {
        Task {
            // TODO: Implement photo deletion
            // This would delete stored photos while preserving analysis data
            await loadStorageStats() // Refresh after clearing
        }
    }
}

// MARK: - Data Models
struct StorageStats {
    let totalBytes: Int64
    let photosSize: Int64
    let analysisSize: Int64
    let appDataSize: Int64
    let cacheSize: Int64
    let photoCount: Int
    let deviceCapacity: Int64

    var totalAppBytes: Int64 {
        return photosSize + analysisSize + appDataSize + cacheSize
    }
}
