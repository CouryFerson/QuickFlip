import SwiftUI

struct BulkAnalysisResultsView: View {
    let result: BulkAnalysisResult
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode
    @State private var processedItems: Set<Int> = []
    @State private var showingPhotoPrompt = false
    @State private var showingCamera = false
    @State private var showingMarketplaceSelection = false
    @State private var selectedItemIndex: Int = 0
    @State private var selectedItemImage: UIImage?
    @State private var isListingFlow = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    itemsListSection
                    completionSection

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
                    Menu {
                        Button("Share Results") {
                            shareResults()
                        }

                        Button("Start Over", role: .destructive) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPhotoPrompt) {
            PhotoPromptView(
                item: result.items[selectedItemIndex],
                originalImage: result.originalImage,
                isListingFlow: isListingFlow
            ) { image in
                selectedItemImage = image
                if isListingFlow {
                    showingMarketplaceSelection = true
                } else {
                    saveItem(at: selectedItemIndex, with: image)
                }
            }
        }
        .sheet(isPresented: $showingMarketplaceSelection) {
            if let image = selectedItemImage {
                NavigationView {
                    MarketplaceSelectionView(
                        scannedItem: createScannedItem(from: result.items[selectedItemIndex], image: image),
                        capturedImage: image
                    )
                    .environmentObject(itemStorage)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Back") {
                                showingMarketplaceSelection = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - View Components
private extension BulkAnalysisResultsView {
    @ViewBuilder
    private var headerSection: some View {
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

                Text("Choose what to do with each item")
                    .font(.subheadline)
                    .foregroundColor(.gray)

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
    }

    @ViewBuilder
    private var itemsListSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(result.items.enumerated()), id: \.offset) { index, item in
                BulkItemActionCard(
                    item: item,
                    index: index,
                    isProcessed: processedItems.contains(index),
                    onList: {
                        selectedItemIndex = index
                        isListingFlow = true
                        showingPhotoPrompt = true
                    },
                    onSave: {
                        selectedItemIndex = index
                        isListingFlow = false
                        showingPhotoPrompt = true
                    }
                )
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var completionSection: some View {
        if processedItems.count == result.items.count {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)

                    Text("All Items Processed!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("You've made decisions for all \(result.items.count) items")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)

                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .font(.headline)
            }
            .padding(.horizontal)
        } else {
            VStack(spacing: 12) {
                Text("Processed \(processedItems.count) of \(result.items.count) items")
                    .font(.caption)
                    .foregroundColor(.gray)

                ProgressView(value: Double(processedItems.count), total: Double(result.items.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Actions
private extension BulkAnalysisResultsView {
    private func saveItem(at index: Int, with image: UIImage) {
        let item = result.items[index]
        let scannedItem = createScannedItem(from: item, image: image)

        itemStorage.saveItem(scannedItem)
        processedItems.insert(index)

        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator()
        impactFeedback.impactOccurred()
    }

    private func createScannedItem(from item: BulkAnalyzedItem, image: UIImage) -> ScannedItem {
        let analysis = item.toItemAnalysis()

        return ScannedItem(
            itemName: analysis.itemName,
            category: analysis.category,
            condition: analysis.condition,
            description: analysis.description,
            estimatedValue: analysis.estimatedValue,
            image: image,
            priceAnalysis: createDefaultAnalysis(for: analysis)
        )
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
        📝 \(result.sceneDescription)
        
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

// MARK: - Bulk Item Action Card
struct BulkItemActionCard: View {
    let item: BulkAnalyzedItem
    let index: Int
    let isProcessed: Bool
    let onList: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            itemDetails

            if !isProcessed {
                actionButtons
            } else {
                processedIndicator
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isProcessed ? Color.green.opacity(0.05) : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isProcessed ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - BulkItemActionCard Components
private extension BulkItemActionCard {
    @ViewBuilder
    private var itemDetails: some View {
        HStack(spacing: 12) {
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
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("💾 Save") {
                onSave()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(8)
            .font(.subheadline)
            .fontWeight(.semibold)

            Button("🚀 List Now") {
                onList()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.subheadline)
            .fontWeight(.semibold)
        }
    }

    @ViewBuilder
    private var processedIndicator: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Processed")
                .font(.subheadline)
                .foregroundColor(.green)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Photo Prompt View
struct PhotoPromptView: View {
    let item: BulkAnalyzedItem
    let originalImage: UIImage
    let isListingFlow: Bool
    let onPhotoSelected: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCamera = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                photoPreview
                actionButtons

                Spacer()
            }
            .padding()
            .navigationTitle(isListingFlow ? "List Item" : "Save Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            SaveImageCameraView { capturedImage in
                onPhotoSelected(capturedImage)
                showingCamera = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - PhotoPromptView Components
private extension PhotoPromptView {
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(item.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(isListingFlow ? "Ready to list this item?" : "Ready to save this item?")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            HStack {
                Text(item.condition)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(6)

                Text(item.estimatedValue)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        VStack(spacing: 12) {
            Text("Current Photo")
                .font(.headline)

            Image(uiImage: originalImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

            Text("Individual photos get 3x more engagement")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("📷 Take New Photo") {
                showingCamera = true
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.headline)

            Button("✓ Use Current Photo") {
                onPhotoSelected(originalImage)
                presentationMode.wrappedValue.dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.green)
            .cornerRadius(8)
            .font(.subheadline)
        }
    }
}
