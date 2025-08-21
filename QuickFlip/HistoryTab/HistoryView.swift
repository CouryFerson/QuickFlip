//
//  Enhanced HistoryView with iOS Native Design + Bulk Delete
//  QuickFlip
//

import SwiftUI

struct HistoryView: View {
    let itemSelectionAction: (ScannedItem) -> Void
    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var searchText = ""
    @State private var selectedSegment = 0
    @State private var showingExportSheet = false
    @State private var showingDetailView = false
    @State private var showingDetailItem: ScannedItem?

    // Bulk delete states
    @State private var isEditMode = false
    @State private var selectedItems = Set<UUID>()
    @State private var showingBulkDeleteAlert = false

    // Segmented control options
    private let segments = ["All", "Recent", "Profitable", "eBay", "StockX"]

    var filteredItems: [ScannedItem] {
        let searchResults = searchText.isEmpty ? itemStorage.scannedItems : itemStorage.searchItems(query: searchText)

        switch selectedSegment {
        case 0: // All
            return searchResults
        case 1: // Recent
            return Array(searchResults.prefix(10))
        case 2: // Profitable
            return searchResults.filter { item in
                item.profitBreakdowns?.first?.netProfit ?? 0 > 0
            }
        case 3: // eBay
            return searchResults.filter { $0.priceAnalysis.recommendedMarketplace == "eBay" }
        case 4: // StockX
            return searchResults.filter { $0.priceAnalysis.recommendedMarketplace == "StockX" }
        default:
            return searchResults
        }
    }

    var allItemsSelected: Bool {
        !filteredItems.isEmpty && selectedItems.count == filteredItems.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if itemStorage.isEmpty {
                    EmptyHistoryView()
                } else {
                    // Stats Header (keeping your design)
                    if !isEditMode {
                        statsHeaderView
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Search and Filter Section
                    if !isEditMode {
                        VStack(spacing: 16) {
                            // Search Bar
                            searchBarView

                            // Segmented Control
                            segmentedControlView
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Items List
                    itemsListView
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if isEditMode {
                        Button(allItemsSelected ? "Deselect All" : "Select All") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if allItemsSelected {
                                    selectedItems.removeAll()
                                } else {
                                    selectedItems = Set(filteredItems.map { $0.id })
                                }
                            }
                        }
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !itemStorage.isEmpty {
                        if isEditMode {
                            Button("Done") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isEditMode = false
                                    selectedItems.removeAll()
                                }
                            }
                        } else {
                            HStack {
                                Button("Edit") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isEditMode = true
                                    }
                                }

                                Button {
                                    showingExportSheet = true
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isEditMode && !selectedItems.isEmpty {
                bulkActionToolbar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isEditMode)
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
                .environmentObject(itemStorage)
        }
        .alert("Delete Items", isPresented: $showingBulkDeleteAlert) {
            Button("Delete \(selectedItems.count) Item\(selectedItems.count == 1 ? "" : "s")", role: .destructive) {
                performBulkDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(selectedItems.count) item\(selectedItems.count == 1 ? "" : "s")? This action cannot be undone.")
        }
    }

    // MARK: - View Components

    private var statsHeaderView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                EnhancedStatCard(
                    title: "Total Scanned",
                    value: "\(itemStorage.totalItemCount)",
                    subtitle: "All time",
                    icon: "camera.fill",
                    color: .blue
                )

                EnhancedStatCard(
                    title: "Potential Savings",
                    value: itemStorage.totalSavings,
                    subtitle: "Smart choices",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )

                EnhancedStatCard(
                    title: "Top Platform",
                    value: itemStorage.topMarketplace,
                    subtitle: "Most used",
                    icon: "crown.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))

            TextField("Search items...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    private var segmentedControlView: some View {
        Picker("Filter", selection: $selectedSegment) {
            ForEach(0..<segments.count, id: \.self) { index in
                Text(segments[index])
                    .tag(index)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    private var itemsListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredItems) { item in
                EnhancedHistoryItemCard(
                    item: item,
                    isEditMode: isEditMode,
                    isSelected: selectedItems.contains(item.id),
                    onTap: {
                        if isEditMode {
                            toggleSelection(for: item)
                        } else {
                            itemSelectionAction(item)
                        }
                    },
                    onToggleSelection: {
                        toggleSelection(for: item)
                    }
                )
                .environmentObject(itemStorage)
            }
        }
        .padding()
        .padding(.bottom, 20)
        .background(Color(.systemGroupedBackground))
    }

    private var bulkActionToolbar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                Spacer()

                Button {
                    showingBulkDeleteAlert = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text("Delete (\(selectedItems.count))")
                    }
                    .foregroundColor(.red)
                    .font(.system(size: 17, weight: .medium))
                }
                .disabled(selectedItems.isEmpty)

                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Helper Methods

    private func toggleSelection(for item: ScannedItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedItems.contains(item.id) {
                selectedItems.remove(item.id)
            } else {
                selectedItems.insert(item.id)
            }
        }
    }

    private func performBulkDelete() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let itemsToDelete = itemStorage.scannedItems.filter { selectedItems.contains($0.id) }

            for item in itemsToDelete {
                itemStorage.deleteItem(item)
            }

            selectedItems.removeAll()
            isEditMode = false
        }
    }
}

// MARK: - Enhanced Stat Card (following your HomeView style)

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
    }
}

// MARK: - Enhanced History Item Card (iOS Native Style with Selection)

struct EnhancedHistoryItemCard: View {
    let item: ScannedItem
    let isEditMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleSelection: () -> Void

    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var showingActionSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection Circle (like iOS Mail)
                if isEditMode {
                    Button(action: onToggleSelection) {
                        ZStack {
                            Circle()
                                .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                                .frame(width: 24, height: 24)

                            if isSelected {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 24, height: 24)

                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                }

                // Item Image
                itemImageView

                // Item Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.itemName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        CategoryBadge(category: item.category.shortForm)
                        ConditionBadge(condition: item.condition.shortForm)
                    }
                }

                Spacer()

                // Price, Marketplace and Actions
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 10) {
                        if let bestPrice = item.priceAnalysis.averagePrices.values.max() {
                            Text("$\(String(format: "%.0f", bestPrice))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }

                        Image(systemName: "chevron.compact.forward")
                            .resizable()
                            .frame(width: 7, height: 15)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    MarketplaceBadge(marketplace: item.priceAnalysis.recommendedMarketplace)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected && isEditMode ? Color.blue.opacity(0.1) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected && isEditMode ? Color.blue : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.3), value: isEditMode)
        .confirmationDialog("Item Actions", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Re-analyze Prices") {
                // TODO: Re-run price analysis
            }

            Button("Share Item") {
                shareItem()
            }

            Button("Delete Item", role: .destructive) {
                showingDeleteAlert = true
            }

            Button("Cancel", role: .cancel) { }
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    itemStorage.deleteItem(item)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(item.itemName)' from your history?")
        }
    }

    private var itemImageView: some View {
        Group {
            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.title3)
                    )
            }
        }
        .frame(width: 70, height: 70)
        .cornerRadius(12)
    }

    private func shareItem() {
        let bestPrice = item.priceAnalysis.averagePrices.values.max() ?? 0
        let shareText = """
        Check out this item I analyzed with QuickFlip:
        
        📱 \(item.itemName)
        💰 Best price: $\(String(format: "%.2f", bestPrice))
        🏪 Recommended marketplace: \(item.priceAnalysis.recommendedMarketplace)
        📅 Analyzed: \(item.formattedTimestamp)
        """

        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Badge Components

struct CategoryBadge: View {
    let category: String

    var body: some View {
        Text(category)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
    }
}

struct ConditionBadge: View {
    let condition: String

    var conditionColor: Color {
        switch condition.lowercased() {
        case "new", "mint":
            return .green
        case "excellent", "very good", "like new":
            return .blue
        case "good":
            return .orange
        case "fair", "poor", "used":
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        Text(condition)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(conditionColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(conditionColor.opacity(0.1))
            .cornerRadius(4)
    }
}

// MARK: - String Extensions for Shortening

extension String {
    var shortForm: String {
        // For categories - make them single words
        let categoryMappings: [String: String] = [
            "Electronics": "Tech",
            "Clothing": "Clothes",
            "Collectibles": "Collect",
            "Home & Garden": "Home",
            "Sports & Outdoors": "Sports",
            "Health & Beauty": "Beauty",
            "Toys & Games": "Toys",
            "Books & Media": "Books",
            "Automotive": "Auto",
            "Musical Instruments": "Music"
        ]

        // For conditions - standardize to 5 simple states
        let conditionMappings: [String: String] = [
            "Brand New": "New",
            "Like New": "Like New",
            "Very Good": "Good",
            "Excellent": "Good",
            "Fair": "Used",
            "Poor": "Poor"
        ]

        // Try category mapping first
        if let shortCategory = categoryMappings[self] {
            return shortCategory
        }

        // Try condition mapping
        if let shortCondition = conditionMappings[self] {
            return shortCondition
        }

        // If no mapping found, return original but truncated if too long
        return self.count > 8 ? String(self.prefix(8)) : self
    }
}

struct MarketplaceBadge: View {
    let marketplace: String

    var marketplaceColor: Color {
        switch marketplace.lowercased() {
        case "ebay":
            return .blue
        case "stockx":
            return .green
        case "mercari":
            return .orange
        case "etsy":
            return .purple
        default:
            return .gray
        }
    }

    var body: some View {
        Text(marketplace)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(marketplaceColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(marketplaceColor.opacity(0.1))
            .cornerRadius(4)
    }
}
// MARK: - Empty State (keeping your original design)

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Scanned Items Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Start scanning items to see your history and track price changes over time")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Text("Ready to start?")
                    .font(.headline)

                Button("Scan Your First Item") {
                    // TODO: Navigate to capture tab
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Button Style (keeping your original style)

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

