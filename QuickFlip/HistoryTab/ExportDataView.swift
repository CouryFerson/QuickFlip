//
//  ExportDataView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct ExportDataView: View {
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode
    @State private var exportFormat: ExportFormat = .csv
    @State private var includeImages = false
    @State private var isExporting = false

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"

        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Download your scanned items and analysis results")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Export Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Format")
                        .font(.headline)

                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle("Include Images", isOn: $includeImages)
                        .disabled(exportFormat == .csv) // CSV can't include images

                    if exportFormat == .csv && includeImages {
                        Text("Note: Images cannot be included in CSV format")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )

                // Stats
                VStack(spacing: 12) {
                    HStack {
                        Text("Items to export:")
                        Spacer()
                        Text("\(itemStorage.totalItemCount)")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Total savings tracked:")
                        Spacer()
                        Text(itemStorage.totalSavings)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Date range:")
                        Spacer()
                        Text(dateRangeText)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )

                Spacer()

                // Export Button
                Button {
                    exportData()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }

                        Text(isExporting ? "Exporting..." : "Export Data")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isExporting || itemStorage.isEmpty)

                if itemStorage.isEmpty {
                    Text("No data to export")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var dateRangeText: String {
        guard !itemStorage.scannedItems.isEmpty else { return "No items" }

        let dates = itemStorage.scannedItems.map(\.timestamp).sorted()
        guard let earliest = dates.first, let latest = dates.last else { return "No items" }

        let formatter = DateFormatter()
        formatter.dateStyle = .short

        if Calendar.current.isDate(earliest, inSameDayAs: latest) {
            return formatter.string(from: latest)
        } else {
            return "\(formatter.string(from: earliest)) - \(formatter.string(from: latest))"
        }
    }

    private func exportData() {
        isExporting = true

        Task {
            do {
                let fileName = "QuickFlip_Export_\(Date().timeIntervalSince1970).\(exportFormat.fileExtension)"

                let data: Data

                switch exportFormat {
                case .csv:
                    data = try generateCSV()
                case .json:
                    data = try generateJSON()
                }

                await MainActor.run {
                    shareFile(data: data, fileName: fileName)
                    self.isExporting = false
                }

            } catch {
                await MainActor.run {
                    print("Export error: \(error)")
                    self.isExporting = false
                }
            }
        }
    }

    private func generateCSV() throws -> Data {
        var csvContent = "Item Name,Category,Condition,Estimated Value,Recommended Marketplace,Best Price,Reasoning,Timestamp\n"

        for item in itemStorage.scannedItems {
            let bestPrice = item.priceAnalysis.averagePrices.values.max() ?? 0
            let row = [
                item.itemName,
                item.category,
                item.condition,
                item.estimatedValue,
                item.priceAnalysis.recommendedMarketplace,
                String(format: "%.2f", bestPrice),
                item.priceAnalysis.reasoning,
                ISO8601DateFormatter().string(from: item.timestamp)
            ].map { "\"\($0)\"" }.joined(separator: ",")

            csvContent += row + "\n"
        }

        return csvContent.data(using: .utf8) ?? Data()
    }

    private func generateJSON() throws -> Data {
        return try JSONEncoder().encode(itemStorage.scannedItems)
    }

    private func shareFile(data: Data, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)

            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }

        } catch {
            print("Failed to save export file: \(error)")
        }
    }
}
