import SwiftUI

struct BulkAnalysisResultsView: View {
    let result: BulkAnalysisResult
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedItems: Set<Int> = []
    @State private var showingCreateListings = false
    @State private var currentPresentationMode: CurrentPresentationMode = .none
    @State private var itemsToList: [BulkAnalyzedItem] = []

    enum CurrentPresentationMode {
        case none
        case singleItem
        case bulkWorkflow
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Scene Photo
                    VStack(spacing: 16) {
                        Image(uiImage: result.originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                        VStack(spacing: 8) {
                            Text("Found \(result.formattedItemCount)")
                                .font(.title)
                                .fontWeight(.bold)

                            Text(result.totalValue)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)

                            if !result.sceneDescription.isEmpty {
                                Text(result.sceneDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Quick Actions
                    HStack(spacing: 12) {
                        Button("Select All") {
                            selectedItems = Set(0..<result.items.count)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)

                        Button("Clear All") {
                            selectedItems.removeAll()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    // Items List
                    VStack(spacing: 16) {
                        ForEach(Array(result.items.enumerated()), id: \.offset) { index, item in
                            BulkItemCard(
                                item: item,
                                index: index,
                                isSelected: selectedItems.contains(index)
                            ) {
                                if selectedItems.contains(index) {
                                    selectedItems.remove(index)
                                } else {
                                    selectedItems.insert(index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("Create \(selectedItems.count) Listings") {
                            createSelectedListings()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedItems.isEmpty ? Color.gray : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                        .disabled(selectedItems.isEmpty)

                        Button("Save All to History") {
                            saveAllToHistory()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Bulk Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareResults()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: .constant(currentPresentationMode != .none), onDismiss: {
            currentPresentationMode = .none
        }) {
            Group {
                if currentPresentationMode == .singleItem, let firstItem = itemsToList.first {
                    NavigationView {
                        MarketplaceSelectionView(
                            itemAnalysis: firstItem.toItemAnalysis(),
                            capturedImage: result.originalImage
                        )
                        .environmentObject(itemStorage)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    currentPresentationMode = .none
                                }
                            }
                        }
                    }
                } else if currentPresentationMode == .bulkWorkflow {
                    BulkListingWorkflowView(
                        selectedItems: itemsToList,
                        originalImage: result.originalImage
                    )
                    .environmentObject(itemStorage)
                }
            }
        }
    }

    private func createSelectedListings() {
        itemsToList = selectedItems.compactMap { index in
            result.items[safe: index]
        }

        if itemsToList.count == 1 {
            currentPresentationMode = .singleItem
        } else if itemsToList.count > 1 {
            currentPresentationMode = .bulkWorkflow
        }
    }

    private func saveAllToHistory() {
        for item in result.items {
            let analysis = item.toItemAnalysis()

            let scannedItem = ScannedItem(
                itemName: analysis.itemName,
                category: analysis.category,
                condition: analysis.condition,
                description: analysis.description,
                estimatedValue: analysis.estimatedValue,
                image: result.originalImage,
                priceAnalysis: createDefaultAnalysis(for: analysis)
            )

            itemStorage.saveItem(scannedItem)
        }

        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator()
        impactFeedback.impactOccurred()

        presentationMode.wrappedValue.dismiss()
    }

    private func createDefaultAnalysis(for item: ItemAnalysis) -> MarketplacePriceAnalysis {
        let basePrice = extractPrice(from: item.estimatedValue)
        let prices: [Marketplace: Double] = [
            .ebay: basePrice,
            .mercari: basePrice * 0.9,
            .facebook: basePrice * 0.8,
            .stockx: basePrice * 1.2
        ]

        return MarketplacePriceAnalysis(
            recommendedMarketplace: .ebay,
            confidence: .medium,
            averagePrices: prices,
            reasoning: "Bulk analysis result"
        )
    }

    private func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "25") ?? 25.0
    }

    private func shareResults() {
        let shareText = """
        QuickFlip Bulk Analysis Results:
        
        📊 Found \(result.items.count) items
        💰 Total value: \(result.totalValue)
        📍 \(result.sceneDescription)
        
        Items:
        \(result.items.enumerated().map { index, item in
            "\(index + 1). \(item.name) - \(item.estimatedValue)"
        }.joined(separator: "\n"))
        
        Analyzed with QuickFlip
        """

        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Bulk Item Card
struct BulkItemCard: View {
    let item: BulkAnalyzedItem
    let index: Int
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                // Item details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    HStack {
                        Text(item.condition)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)

                        if !item.location.isEmpty {
                            Text("📍 \(item.location)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Spacer()

                // Price
                VStack(alignment: .trailing) {
                    Text(item.estimatedValue)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    Text(item.category)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.purple.opacity(0.1) : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
