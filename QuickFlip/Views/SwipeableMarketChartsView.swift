import SwiftUI

// MARK: - Swipeable Market Charts View
struct SwipeableMarketChartsView: View {
    let ebayData: MarketPriceData?
    let stockxData: MarketPriceData?
    let etsyData: MarketPriceData?
    let isLoadingEbay: Bool
    let isLoadingStockX: Bool
    let isLoadingEtsy: Bool
    let ebayLoadFailed: Bool
    let stockxLoadFailed: Bool
    let etsyLoadFailed: Bool
    let recommendedMarketplace: Marketplace
    let onRetryEbay: () -> Void
    let onRetryStockX: () -> Void
    let onRetryEtsy: () -> Void

    @State private var selectedMarketplace: Marketplace
    @State private var expandedChartData: ExpandedChartData?

    struct ExpandedChartData: Identifiable {
        let id = UUID()
        let marketplace: Marketplace
        let data: MarketPriceData
    }

    init(
        ebayData: MarketPriceData?,
        stockxData: MarketPriceData?,
        etsyData: MarketPriceData?,
        isLoadingEbay: Bool = false,
        isLoadingStockX: Bool = false,
        isLoadingEtsy: Bool = false,
        ebayLoadFailed: Bool = false,
        stockxLoadFailed: Bool = false,
        etsyLoadFailed: Bool = false,
        recommendedMarketplace: Marketplace = .ebay,
        onRetryEbay: @escaping () -> Void = {},
        onRetryStockX: @escaping () -> Void = {},
        onRetryEtsy: @escaping () -> Void = {}
    ) {
        self.ebayData = ebayData
        self.stockxData = stockxData
        self.etsyData = etsyData
        self.isLoadingEbay = isLoadingEbay
        self.isLoadingStockX = isLoadingStockX
        self.isLoadingEtsy = isLoadingEtsy
        self.ebayLoadFailed = ebayLoadFailed
        self.stockxLoadFailed = stockxLoadFailed
        self.etsyLoadFailed = etsyLoadFailed
        self.recommendedMarketplace = recommendedMarketplace
        self.onRetryEbay = onRetryEbay
        self.onRetryStockX = onRetryStockX
        self.onRetryEtsy = onRetryEtsy

        // Start on recommended marketplace
        _selectedMarketplace = State(initialValue: recommendedMarketplace)
    }

    var body: some View {
        VStack(spacing: 16) {
            chartCardsSection
            pageIndicator
        }
        .sheet(item: $expandedChartData) { chartData in
            expandedChartSheet(marketplace: chartData.marketplace, data: chartData.data)
        }
    }
}

// MARK: - Private Components
private extension SwipeableMarketChartsView {

    @ViewBuilder
    var chartCardsSection: some View {
        // Only show eBay for now - StockX and Etsy coming in future update
        VStack(spacing: 0) {
            // eBay Card
            marketChartCard(
                marketplace: .ebay,
                data: ebayData,
                isLoading: isLoadingEbay,
                loadFailed: ebayLoadFailed,
                onRetry: onRetryEbay
            )
        }
        .frame(height: 300)
    }

    @ViewBuilder
    func marketChartCard(
        marketplace: Marketplace,
        data: MarketPriceData?,
        isLoading: Bool,
        loadFailed: Bool,
        onRetry: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            // Marketplace badge if recommended
            if marketplace == recommendedMarketplace {
                recommendedBadge
            }

            // Chart content
            chartContent(marketplace: marketplace, data: data, isLoading: isLoading, loadFailed: loadFailed, onRetry: onRetry)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            if let data = data, data.hasData {
                expandedChartData = ExpandedChartData(marketplace: marketplace, data: data)
            }
        }
    }

    @ViewBuilder
    var recommendedBadge: some View {
        HStack {
            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                Text("RECOMMENDED")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
    }

    @ViewBuilder
    func chartContent(
        marketplace: Marketplace,
        data: MarketPriceData?,
        isLoading: Bool,
        loadFailed: Bool,
        onRetry: @escaping () -> Void
    ) -> some View {
        if isLoading {
            // Loading state - show spinner
            MarketPriceLoadingView(displayMode: .compact)
        } else if let data = data {
            // We have data - check if it has content
            if data.hasData {
                MarketPriceChartView(marketData: data, displayMode: .compact)
            } else {
                // Data loaded but no listings found
                noListingsFound(marketplace: marketplace)
            }
        } else if loadFailed {
            // Only show error/retry if we actually tried and failed
            MarketPriceErrorView(
                errorMessage: "Couldn't load data",
                retryAction: onRetry,
                displayMode: .compact
            )
        } else {
            // Initial state - haven't loaded yet, show waiting state
            waitingToLoad(marketplace: marketplace)
        }
    }

    @ViewBuilder
    func waitingToLoad(marketplace: Marketplace) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 30))
                .foregroundColor(.secondary.opacity(0.6))

            Text("\(marketplace.displayName) Data")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("Will load when unlocked")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    func noListingsFound(marketplace: Marketplace) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30))
                .foregroundColor(.secondary)

            Text("No \(marketplace.displayName) listings")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("Not enough data available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    var pageIndicator: some View {
        // Hidden for now since we only show eBay
        // Will return when StockX and Etsy are added
        EmptyView()
    }

    @ViewBuilder
    func expandedChartSheet(marketplace: Marketplace, data: MarketPriceData) -> some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    MarketPriceChartView(marketData: data, displayMode: .full)
                        .padding()

                    // List on marketplace button
                    listOnMarketplaceButton(marketplace: marketplace)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("\(marketplace.displayName) Market Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        expandedChartData = nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    func listOnMarketplaceButton(marketplace: Marketplace) -> some View {
        Button(action: {
            // This will be handled by parent view
            expandedChartData = nil
        }) {
            HStack {
                Image(systemName: marketplace.systemImage)
                    .font(.headline)

                Text("List on \(marketplace.displayName)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(marketplace.color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview
#Preview("With Data") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Swipeable Market Charts")
                .font(.title2)
                .fontWeight(.bold)

            SwipeableMarketChartsView(
                ebayData: .mock,
                stockxData: .mock,
                etsyData: .mock,
                recommendedMarketplace: .ebay
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Loading States") {
    ScrollView {
        SwipeableMarketChartsView(
            ebayData: nil,
            stockxData: nil,
            etsyData: nil,
            isLoadingEbay: true,
            isLoadingStockX: true,
            isLoadingEtsy: true,
            recommendedMarketplace: .stockx
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Mixed States") {
    ScrollView {
        SwipeableMarketChartsView(
            ebayData: .mock,
            stockxData: nil,
            etsyData: .mockNoData,
            isLoadingEbay: false,
            isLoadingStockX: true,
            isLoadingEtsy: false,
            recommendedMarketplace: .ebay
        )
    }
    .background(Color(.systemGroupedBackground))
}
