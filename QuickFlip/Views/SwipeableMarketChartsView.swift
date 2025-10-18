import SwiftUI

// MARK: - Swipeable Market Charts View
struct SwipeableMarketChartsView: View {
    let scannedItem: ScannedItem
    let supabaseService: SupabaseService
    let ebayData: MarketPriceData?
    let etsyData: MarketPriceData?
    let isLoadingEbay: Bool
    let isLoadingEtsy: Bool
    let ebayLoadFailed: Bool
    let etsyLoadFailed: Bool
    let recommendedMarketplace: Marketplace
    let onRetryEbay: () -> Void
    let onRetryEtsy: () -> Void

    @State private var selectedMarketplace: Marketplace
    @State private var expandedChartData: ExpandedChartData?

    struct ExpandedChartData: Identifiable {
        let id = UUID()
        let marketplace: Marketplace
        let data: MarketPriceData
    }

    init(
        scannedItem: ScannedItem,
        supabaseService: SupabaseService,
        ebayData: MarketPriceData?,
        stockxData: MarketPriceData?, // Keep for compatibility
        etsyData: MarketPriceData?,
        isLoadingEbay: Bool = false,
        isLoadingStockX: Bool = false, // Keep for compatibility
        isLoadingEtsy: Bool = false,
        ebayLoadFailed: Bool = false,
        stockxLoadFailed: Bool = false, // Keep for compatibility
        etsyLoadFailed: Bool = false,
        recommendedMarketplace: Marketplace = .ebay,
        onRetryEbay: @escaping () -> Void = {},
        onRetryStockX: @escaping () -> Void = {}, // Keep for compatibility
        onRetryEtsy: @escaping () -> Void = {}
    ) {
        self.scannedItem = scannedItem
        self.supabaseService = supabaseService
        self.ebayData = ebayData
        // Note: stockxData is ignored since StockX uses search card
        self.etsyData = etsyData
        self.isLoadingEbay = isLoadingEbay
        // Note: isLoadingStockX is ignored since StockX uses search card
        self.isLoadingEtsy = isLoadingEtsy
        self.ebayLoadFailed = ebayLoadFailed
        // Note: stockxLoadFailed is ignored since StockX uses search card
        self.etsyLoadFailed = etsyLoadFailed
        self.recommendedMarketplace = recommendedMarketplace
        self.onRetryEbay = onRetryEbay
        // Note: onRetryStockX is ignored since StockX uses search card
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
        TabView(selection: $selectedMarketplace) {
            // eBay Card
            marketChartCard(
                marketplace: .ebay,
                data: ebayData,
                isLoading: isLoadingEbay,
                loadFailed: ebayLoadFailed,
                onRetry: onRetryEbay
            )
            .tag(Marketplace.ebay)

            // StockX Search Card
            stockXSearchCard
                .tag(Marketplace.stockx)

            // Etsy Card (placeholder for future)
            marketChartCard(
                marketplace: .etsy,
                data: etsyData,
                isLoading: isLoadingEtsy,
                loadFailed: etsyLoadFailed,
                onRetry: onRetryEtsy
            )
            .tag(Marketplace.etsy)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 400)
    }

    @ViewBuilder
    var stockXSearchCard: some View {
        VStack(spacing: 0) {
            // Recommended badge if applicable
            if recommendedMarketplace == .stockx {
                recommendedBadge
            }

            // StockX search card
            StockXMarketSearchCard(
                scannedItem: scannedItem,
                supabaseService: supabaseService
            )
        }
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

            Text("Coming soon")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
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
        .frame(height: 340)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach([Marketplace.ebay, .stockx, .etsy], id: \.self) { marketplace in
                Circle()
                    .fill(selectedMarketplace == marketplace ? marketplace.color : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: selectedMarketplace)
            }
        }
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
