import SwiftUI

struct BulkAnalysisResultsView: View {
    let result: BulkAnalysisResult
    let listAction: (ScannedItem, UIImage) -> Void
    let doneAction: () -> Void

    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.presentationMode) var presentationMode
    @State private var processedItems: Set<Int> = []
    @State private var selectedItems: Set<Int> = []
    @State private var isSelectionMode = false
    @State private var showingPhotoPrompt = false
    @State private var showingCamera = false
    @State private var selectedItemIndex: Int = 0
    @State private var selectedItemImage: UIImage?
    @State private var isListingFlow = false
    @State private var isBulkAction = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                if !isSelectionMode && hasUnprocessedItems {
                    selectionModeToggle
                }

                if isSelectionMode {
                    selectionToolbar
                }

                itemsListSection
                completionSection

                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Bulk Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Share Results") {
                        shareResults()
                    }

                    Button("Done") {
                        doneAction()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingPhotoPrompt) {
            if isBulkAction {
                BulkPhotoPromptView(
                    items: selectedItems.map { result.items[$0] },
                    originalImage: result.originalImage,
                    isListingFlow: isListingFlow
                ) { useOriginal in
                    if useOriginal {
                        processBulkItems(with: result.originalImage)
                    } else {
                        // Camera flow for bulk - use original for now
                        processBulkItems(with: result.originalImage)
                    }
                }
            } else {
                PhotoPromptView(
                    item: result.items[selectedItemIndex],
                    originalImage: result.originalImage,
                    isListingFlow: isListingFlow
                ) { image in
                    selectedItemImage = image
                    if isListingFlow {
                        listAction(createScannedItem(from: result.items[selectedItemIndex], image: image), image)
                        saveItem(at: selectedItemIndex, with: image)
                    } else {
                        saveItem(at: selectedItemIndex, with: image)
                    }
                }
            }
        }
    }

    private var hasUnprocessedItems: Bool {
        processedItems.count < result.items.count
    }

    private var unprocessedSelectedItems: Set<Int> {
        selectedItems.filter { !processedItems.contains($0) }
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

                Text(isSelectionMode ? "Select items to process" : "Choose what to do with each item")
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
    private var selectionModeToggle: some View {
        Button {
            withAnimation {
                isSelectionMode.toggle()
                if !isSelectionMode {
                    selectedItems.removeAll()
                }
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle")
                Text("Select Multiple Items")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var selectionToolbar: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(unprocessedSelectedItems.count) selected")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                Button("Select All") {
                    selectAllUnprocessed()
                }
                .font(.subheadline)
                .foregroundColor(.blue)

                Button("Clear") {
                    selectedItems.removeAll()
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .padding(.leading, 8)
            }

            if !unprocessedSelectedItems.isEmpty {
                HStack(spacing: 12) {
                    Button {
                        isBulkAction = true
                        isListingFlow = false
                        showingPhotoPrompt = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save Selected")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    Button {
                        isBulkAction = true
                        isListingFlow = true
                        showingPhotoPrompt = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.circle")
                            Text("List Selected")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }

            Button("Cancel Selection") {
                withAnimation {
                    isSelectionMode = false
                    selectedItems.removeAll()
                }
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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
                    isSelected: selectedItems.contains(index),
                    isSelectionMode: isSelectionMode,
                    onToggleSelection: {
                        toggleSelection(at: index)
                    },
                    onList: {
                        selectedItemIndex = index
                        isListingFlow = true
                        isBulkAction = false
                        showingPhotoPrompt = true
                    },
                    onSave: {
                        selectedItemIndex = index
                        isListingFlow = false
                        isBulkAction = false
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
                    doneAction()
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
    private func toggleSelection(at index: Int) {
        guard !processedItems.contains(index) else { return }

        if selectedItems.contains(index) {
            selectedItems.remove(index)
        } else {
            selectedItems.insert(index)
        }
    }

    private func selectAllUnprocessed() {
        for index in 0..<result.items.count {
            if !processedItems.contains(index) {
                selectedItems.insert(index)
            }
        }
    }

    private func processBulkItems(with image: UIImage) {
        for index in unprocessedSelectedItems {
            let item = result.items[index]
            let scannedItem = createScannedItem(from: item, image: image)

            if isListingFlow {
                listAction(scannedItem, image)
            }

            itemStorage.saveItem(scannedItem, image: image)
            processedItems.insert(index)
        }

        selectedItems.removeAll()
        isSelectionMode = false

        // Show success feedback
        let impactFeedback = UIImpactFeedbackGenerator()
        impactFeedback.impactOccurred()
    }

    private func saveItem(at index: Int, with image: UIImage) {
        let item = result.items[index]
        let scannedItem = createScannedItem(from: item, image: image)

        itemStorage.saveItem(scannedItem, image: image)
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
    let isSelected: Bool
    let isSelectionMode: Bool
    let onToggleSelection: () -> Void
    let onList: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isSelectionMode && !isProcessed {
                selectionCheckbox
            }

            VStack(spacing: 12) {
                itemDetails

                if !isProcessed && !isSelectionMode {
                    actionButtons
                } else if isProcessed {
                    processedIndicator
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isProcessed ? Color.green.opacity(0.05) : isSelected ? Color.blue.opacity(0.05) : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isProcessed ? Color.green.opacity(0.3) :
                    isSelected ? Color.blue.opacity(0.5) :
                    Color.clear,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .onTapGesture {
            if isSelectionMode && !isProcessed {
                onToggleSelection()
            }
        }
    }
}

// MARK: - BulkItemActionCard Components
private extension BulkItemActionCard {
    @ViewBuilder
    private var selectionCheckbox: some View {
        Button {
            onToggleSelection()
        } label: {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }

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

// MARK: - Bulk Photo Prompt View
struct BulkPhotoPromptView: View {
    let items: [BulkAnalyzedItem]
    let originalImage: UIImage
    let isListingFlow: Bool
    let onPhotoDecision: (Bool) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                bulkHeaderSection
                photoPreview
                bulkActionButtons

                Spacer()
            }
            .padding()
            .navigationTitle(isListingFlow ? "List Items" : "Save Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - BulkPhotoPromptView Components
private extension BulkPhotoPromptView {
    @ViewBuilder
    private var bulkHeaderSection: some View {
        VStack(spacing: 12) {
            Text("\(items.count) Items Selected")
                .font(.title2)
                .fontWeight(.bold)

            Text(isListingFlow ? "Ready to list these items?" : "Ready to save these items?")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(item.estimatedValue)
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
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

            Text("Using the bulk photo for all selected items")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var bulkActionButtons: some View {
        VStack(spacing: 12) {
            Button("✓ Process All Items") {
                onPhotoDecision(true)
                presentationMode.wrappedValue.dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.headline)
        }
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
