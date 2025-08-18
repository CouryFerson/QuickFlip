//
//  HistoryView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var searchText = ""
    @State private var selectedFilter: HistoryFilter = .all
    @State private var showingExportSheet = false

    var filteredItems: [ScannedItem] {
        let searchResults = searchText.isEmpty ? itemStorage.scannedItems : itemStorage.searchItems(query: searchText)

        switch selectedFilter {
        case .all:
            return searchResults
        case .recent:
            return Array(searchResults.prefix(10))
        case .profitable:
            return searchResults.filter { item in
                item.profitBreakdowns?.first?.netProfit ?? 0 > 0
            }
        case .marketplace(let name):
            return searchResults.filter { $0.priceAnalysis.recommendedMarketplace == name }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if itemStorage.isEmpty {
                    EmptyHistoryView()
                } else {
                    // Stats Header
                    HistoryStatsHeader()
                        .environmentObject(itemStorage)

                    // Search and Filter
                    VStack(spacing: 12) {
                        SearchBar(text: $searchText)

                        FilterScrollView(selectedFilter: $selectedFilter)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))

                    // Items List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                HistoryItemCard(item: item)
                                    .environmentObject(itemStorage)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !itemStorage.isEmpty {
                        Button {
                            showingExportSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
                .environmentObject(itemStorage)
        }
    }
}

// MARK: - Filter Types
enum HistoryFilter: Hashable {
    case all
    case recent
    case profitable
    case marketplace(String)

    var displayName: String {
        switch self {
        case .all: return "All"
        case .recent: return "Recent"
        case .profitable: return "Profitable"
        case .marketplace(let name): return name
        }
    }
}

// MARK: - Empty State
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

            // Quick action button
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

// MARK: - Stats Header
struct HistoryStatsHeader: View {
    @EnvironmentObject var itemStorage: ItemStorageService

    var body: some View {
        HStack {
            StatCard(
                title: "Total Scanned",
                value: "\(itemStorage.totalItemCount)",
                icon: "camera.fill",
                color: .blue
            )

            StatCard(
                title: "Potential Savings",
                value: itemStorage.totalSavings,
                icon: "dollarsign.circle.fill",
                color: .green
            )

            StatCard(
                title: "Top Platform",
                value: itemStorage.topMarketplace,
                icon: "crown.fill",
                color: .orange
            )
        }
        .padding()
        .background(Color.white)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search items...", text: $text)

            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
    }
}

// MARK: - Filter Scroll View
struct FilterScrollView: View {
    @Binding var selectedFilter: HistoryFilter

    let filters: [HistoryFilter] = [
        .all, .recent, .profitable,
        .marketplace("eBay"), .marketplace("StockX"),
        .marketplace("Mercari"), .marketplace("Etsy")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Custom Button Style
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
