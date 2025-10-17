import SwiftUI

struct HistoryView: View {
    let itemSelectionAction: (ScannedItem) -> Void
    let scanFirstItemAction: () -> Void
    @EnvironmentObject var itemStorage: ItemStorageService

    // Search and filter
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var sortOption: SortOption = .newestFirst
    @State private var showingSortMenu = false

    // Sheets and alerts
    @State private var showingAnalytics = false
    @State private var showingExportSheet = false

    // Bulk delete
    @State private var isEditMode = false
    @State private var selectedItems = Set<UUID>()
    @State private var showingBulkDeleteAlert = false

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case readyToList = "Ready"
        case listed = "Listed"
        case sold = "Sold"
    }

    enum SortOption: String, CaseIterable {
        case newestFirst = "Newest First"
        case oldestFirst = "Oldest First"
        case highestValue = "Highest Value"
        case highestProfit = "Highest Profit"
    }

    var filteredAndSortedItems: [ScannedItem] {
        let searchResults = searchText.isEmpty ? itemStorage.scannedItems : itemStorage.searchItems(query: searchText)

        // Filter by status
        let filtered: [ScannedItem]
        switch selectedFilter {
        case .all:
            filtered = searchResults
        case .readyToList:
            filtered = searchResults.filter { $0.listingStatus.status == .readyToList }
        case .listed:
            filtered = searchResults.filter { $0.listingStatus.status == .listed }
        case .sold:
            filtered = searchResults.filter { $0.listingStatus.status == .sold }
        }

        // Sort
        return filtered.sorted { item1, item2 in
            switch sortOption {
            case .newestFirst:
                return item1.timestamp > item2.timestamp
            case .oldestFirst:
                return item1.timestamp < item2.timestamp
            case .highestValue:
                let price1 = item1.priceAnalysis.averagePrices.values.max() ?? 0
                let price2 = item2.priceAnalysis.averagePrices.values.max() ?? 0
                return price1 > price2
            case .highestProfit:
                let profit1 = item1.listingStatus.netProfit ?? 0
                let profit2 = item2.listingStatus.netProfit ?? 0
                return profit1 > profit2
            }
        }
    }

    var allItemsSelected: Bool {
        !filteredAndSortedItems.isEmpty && selectedItems.count == filteredAndSortedItems.count
    }

    var body: some View {
        Group {
            if itemStorage.isEmpty {
                emptyStateView
            } else {
                List {
                    if !isEditMode {
                        Section {
                            VStack(spacing: 0) {
                                statsHeaderSection
                                searchAndFilterSection
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        ForEach(filteredAndSortedItems) { item in
                            ModernHistoryItemCard(
                                item: item,
                                isEditMode: isEditMode,
                                isSelected: selectedItems.contains(item.id)
                            )
                            .environmentObject(itemStorage)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isEditMode {
                                    toggleSelection(for: item)
                                } else {
                                    itemSelectionAction(item)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: isEditMode ? nil : deleteItems)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .safeAreaInset(edge: .bottom) {
            if isEditMode && !selectedItems.isEmpty {
                bulkActionToolbar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isEditMode)
        .sheet(isPresented: $showingAnalytics) {
            NavigationView {
                AnalyticsView()
                    .environmentObject(itemStorage)
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
                .environmentObject(itemStorage)
        }
        .confirmationDialog("Sort By", isPresented: $showingSortMenu) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    sortOption = option
                }
            }
            Button("Cancel", role: .cancel) { }
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
}

// MARK: - View Components
private extension HistoryView {
    @ViewBuilder
    var statsHeaderSection: some View {
        VStack(spacing: 16) {
            // Top row
            HStack(spacing: 12) {
                revenueStatCard
                profitStatCard
            }

            // Bottom row
            HStack(spacing: 12) {
                activeListingsStatCard
                potentialValueStatCard
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    var revenueStatCard: some View {
        StatCard(
            title: "Revenue",
            value: itemStorage.formattedTotalRevenue,
            subtitle: "\(itemStorage.soldItems.count) sold",
            icon: "dollarsign.circle.fill",
            color: .green
        )
    }

    @ViewBuilder
    var profitStatCard: some View {
        let profit = itemStorage.totalProfit
        StatCard(
            title: "Profit",
            value: itemStorage.formattedTotalProfit,
            subtitle: profit >= 0 ? "Net gain" : "Net loss",
            icon: "chart.line.uptrend.xyaxis",
            color: profit >= 0 ? .green : .red
        )
    }

    @ViewBuilder
    var activeListingsStatCard: some View {
        StatCard(
            title: "Active",
            value: "\(itemStorage.listedItems.count)",
            subtitle: "Listed now",
            icon: "tag.fill",
            color: .blue
        )
    }

    @ViewBuilder
    var potentialValueStatCard: some View {
        StatCard(
            title: "Potential",
            value: itemStorage.totalPotentialProfit,
            subtitle: "If sold",
            icon: "sparkles",
            color: .orange
        )
    }

    @ViewBuilder
    var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            searchBar
            filterTabs
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemGroupedBackground))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    var searchBar: some View {
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
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    @ViewBuilder
    var filterTabs: some View {
        HStack(spacing: 8) {
            ForEach(FilterOption.allCases, id: \.self) { filter in
                filterTab(for: filter)
            }
        }
    }

    @ViewBuilder
    func filterTab(for filter: FilterOption) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        } label: {
            Text(filter.rawValue)
                .font(.subheadline)
                .fontWeight(selectedFilter == filter ? .semibold : .medium)
                .foregroundColor(selectedFilter == filter ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selectedFilter == filter ? Color.blue : Color(UIColor.systemBackground))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Methods

    func deleteItems(at offsets: IndexSet) {
        withAnimation(.easeInOut(duration: 0.3)) {
            let itemsToDelete = offsets.map { filteredAndSortedItems[$0] }
            for item in itemsToDelete {
                itemStorage.deleteItem(item)
            }
        }
    }

    @ViewBuilder
    var bulkActionToolbar: some View {
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
            .background(Color(UIColor.systemBackground))
        }
    }

    @ViewBuilder
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "tray.fill")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.5))

            VStack(spacing: 12) {
                Text("No Items Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Start scanning items to track your\ninventory and sales")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                scanFirstItemAction()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Scan Your First Item")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.blue)
                .clipShape(Capsule())
            }
            .padding(.bottom, 50)
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if isEditMode {
                Button(allItemsSelected ? "Deselect All" : "Select All") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if allItemsSelected {
                            selectedItems.removeAll()
                        } else {
                            selectedItems = Set(filteredAndSortedItems.map { $0.id })
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
                    HStack(spacing: 16) {
                        // Analytics button
                        Button {
                            showingAnalytics = true
                        } label: {
                            Image(systemName: "chart.bar.fill")
                        }

                        // Sort button
                        Button {
                            showingSortMenu = true
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }

                        // More menu
                        Menu {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isEditMode = true
                                }
                            } label: {
                                Label("Select Items", systemImage: "checkmark.circle")
                            }

                            Button {
                                showingExportSheet = true
                            } label: {
                                Label("Export Data", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    func toggleSelection(for item: ScannedItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedItems.contains(item.id) {
                selectedItems.remove(item.id)
            } else {
                selectedItems.insert(item.id)
            }
        }
    }

    func performBulkDelete() {
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

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}
