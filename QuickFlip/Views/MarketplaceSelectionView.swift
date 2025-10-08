import SwiftUI

struct MarketplaceSelectionView: View {
    let scannedItem: ScannedItem
    let capturedImage: UIImage
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var itemStorage: ItemStorageService
    @EnvironmentObject var imageAnalysisService: ImageAnalysisService
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var supabaseService: SupabaseService

    // Services
    @StateObject private var ebayMarketPriceService: eBayMarketPriceService

    // Market Intelligence State
    @State private var marketIntelligenceUnlocked = false
    @State private var isUnlockingIntelligence = false
    @State private var priceAnalysisResult: MarketplacePriceAnalysis?

    // Market Data State
    @State private var ebayMarketData: MarketPriceData?
    @State private var stockxMarketData: MarketPriceData?
    @State private var etsyMarketData: MarketPriceData?

    // Loading States
    @State private var isLoadingEbay = false
    @State private var isLoadingStockX = false
    @State private var isLoadingEtsy = false

    // Error tracking - to know if we should show retry
    @State private var ebayLoadFailed = false
    @State private var stockxLoadFailed = false
    @State private var etsyLoadFailed = false

    // Alerts
    @State private var showingTokenAlert = false
    @State private var showPricingDisclaimer = false

    init(scannedItem: ScannedItem, capturedImage: UIImage, supabaseService: SupabaseService) {
        self.scannedItem = scannedItem
        self.capturedImage = capturedImage
        _ebayMarketPriceService = StateObject(wrappedValue: eBayMarketPriceService(supabaseService: supabaseService))
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                itemPreviewSection

                marketIntelligenceSection

                marketplaceGridSection
            }
        }
        .alert("No tokens left", isPresented: $showingTokenAlert) {
            Button("Done", role: .cancel) { }
        } message: {
            Text(subscriptionManager.addTokensMessage)
        }
        .sheet(isPresented: $showPricingDisclaimer) {
            PricingDisclaimerView()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Choose Marketplace")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Main Sections
private extension MarketplaceSelectionView {

    @ViewBuilder
    var itemPreviewSection: some View {
        VStack(spacing: 16) {
            itemImageView
            itemDetailsView
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    var marketIntelligenceSection: some View {
        MarketIntelligenceSection(
            scannedItem: scannedItem,
            capturedImage: capturedImage,
            isUnlocked: $marketIntelligenceUnlocked,
            isUnlocking: $isUnlockingIntelligence,
            priceAnalysisResult: $priceAnalysisResult,
            ebayMarketData: $ebayMarketData,
            stockxMarketData: $stockxMarketData,
            etsyMarketData: $etsyMarketData,
            isLoadingEbay: isLoadingEbay,
            isLoadingStockX: isLoadingStockX,
            isLoadingEtsy: isLoadingEtsy,
            ebayLoadFailed: ebayLoadFailed,
            stockxLoadFailed: stockxLoadFailed,
            etsyLoadFailed: etsyLoadFailed,
            onUnlock: unlockMarketIntelligence,
            onRetryEbay: fetchEbayData,
            onRetryStockX: fetchStockXData,
            onRetryEtsy: fetchEtsyData,
            onShowPricingDisclaimer: { showPricingDisclaimer = true }
        )
    }

    @ViewBuilder
    var marketplaceGridSection: some View {
        VStack(spacing: 16) {
            sectionDivider
            marketplaceGrid
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Item Preview Components
private extension MarketplaceSelectionView {

    @ViewBuilder
    var itemImageView: some View {
        Image(uiImage: capturedImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
    }

    @ViewBuilder
    var itemDetailsView: some View {
        VStack(spacing: 8) {
            Text(scannedItem.itemName)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(scannedItem.estimatedValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)

            Text("AI Estimated Price")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Grid Components
private extension MarketplaceSelectionView {

    @ViewBuilder
    var sectionDivider: some View {
        HStack {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)

            Text("All Platforms")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)

            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    var marketplaceGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 16
        ) {
            ForEach(Marketplace.allCases) { marketplace in
                marketplaceCard(for: marketplace)
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    func marketplaceCard(for marketplace: Marketplace) -> some View {
        NavigationLink {
            destinationView(for: marketplace)
        } label: {
            VStack(spacing: 12) {
                // Platform Icon
                ZStack {
                    Circle()
                        .fill(marketplace.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: marketplace.systemImage)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(marketplace.color)
                }

                // Platform Info
                VStack(spacing: 4) {
                    Text(marketplace.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    priceLabel(for: marketplace)

                    if getRecommendedMarketplaces().contains(marketplace) {
                        recommendedBadge
                    }

                    // Real data badge for markets with live data
                    if marketIntelligenceUnlocked && hasRealData(for: marketplace) {
                        realDataBadge
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        marketIntelligenceUnlocked && hasRealData(for: marketplace)
                            ? Color.blue.opacity(0.3)
                            : Color(.systemGray5),
                        lineWidth: marketIntelligenceUnlocked && hasRealData(for: marketplace) ? 2 : 1
                    )
            )
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(MarketplaceCardButtonStyle())
    }

    @ViewBuilder
    func priceLabel(for marketplace: Marketplace) -> some View {
        VStack(spacing: 2) {
            Text(specificMarketplacePrice(for: marketplace))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)

            if marketIntelligenceUnlocked && hasRealData(for: marketplace) {
                Text("Live Data")
                    .font(.caption2)
                    .foregroundColor(.blue)
            } else {
                Text("AI Estimate")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    var recommendedBadge: some View {
        Text("RECOMMENDED")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
    }

    @ViewBuilder
    var realDataBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "chart.bar.fill")
                .font(.caption2)
            Text("LIVE")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    func destinationView(for marketplace: Marketplace) -> some View {
        switch marketplace {
        case .ebay:
            eBayUploadView(listing: EbayListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage, supabaseService: supabaseService)
        case .facebook:
            FacebookMarketplaceView(listing: FacebookListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
        case .amazon:
            AmazonPrepView(listing: AmazonListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
        case .stockx:
            StockXUploadView(scannedItem: scannedItem, capturedImage: capturedImage, supabaseService: supabaseService)
        case .etsy:
            EtsyUploadView(listing: EtsyListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
        case .mercari:
            MercariPrepView(listing: MercariListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
        case .poshmark:
            PoshmarkPrepView(listing: PoshmarkListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
        case .depop:
            DepopPrepView(listing: DepopListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
        }
    }
}

// MARK: - Business Logic
private extension MarketplaceSelectionView {

    func unlockMarketIntelligence() {
        guard authManager.hasTokens() else {
            showingTokenAlert = true
            return
        }

        isUnlockingIntelligence = true

        // Set loading states for all marketplaces
        isLoadingEbay = true
        isLoadingStockX = true
        isLoadingEtsy = true

        Task {
            do {
                // Run AI analysis
                let analysis = try await imageAnalysisService.researchPrices(
                    for: scannedItem.itemName,
                    category: scannedItem.category
                )

                await MainActor.run {
                    self.priceAnalysisResult = analysis
                }

                // Fetch market data for each marketplace independently
                await fetchEbayDataAsync()
                await fetchStockXDataAsync()
                await fetchEtsyDataAsync()

                await MainActor.run {
                    self.marketIntelligenceUnlocked = true
                    self.isUnlockingIntelligence = false
                }

            } catch {
                print("QuickFlip: Market intelligence error: \(error)")
                await MainActor.run {
                    self.isUnlockingIntelligence = false
                    self.isLoadingEbay = false
                    self.isLoadingStockX = false
                    self.isLoadingEtsy = false
                }
            }
        }
    }

    func fetchEbayDataAsync() async {
        do {
            let data = try await fetchMarketData(for: .ebay)
            await MainActor.run {
                self.ebayMarketData = data
                self.isLoadingEbay = false
            }
        } catch {
            print("QuickFlip: eBay data error: \(error)")
            await MainActor.run {
                // Set to nil to trigger error state
                self.ebayMarketData = nil
                self.isLoadingEbay = false
            }
        }
    }

    func fetchStockXDataAsync() async {
        do {
            let data = try await fetchMarketData(for: .stockx)
            await MainActor.run {
                self.stockxMarketData = data
                self.isLoadingStockX = false
            }
        } catch {
            print("QuickFlip: StockX data error: \(error)")
            await MainActor.run {
                self.stockxMarketData = nil
                self.isLoadingStockX = false
            }
        }
    }

    func fetchEtsyDataAsync() async {
        do {
            let data = try await fetchMarketData(for: .etsy)
            await MainActor.run {
                self.etsyMarketData = data
                self.isLoadingEtsy = false
            }
        } catch {
            print("QuickFlip: Etsy data error: \(error)")
            await MainActor.run {
                self.etsyMarketData = nil
                self.isLoadingEtsy = false
            }
        }
    }

    func fetchMarketData(for marketplace: Marketplace) async throws -> MarketPriceData? {
        switch marketplace {
        case .ebay:
            return try await ebayMarketPriceService.fetchMarketPrices(
                for: scannedItem.itemName,
                category: scannedItem.category
            )
        case .stockx:
            // TODO: Add StockX service when credentials are available
            // return try await stockxMarketPriceService.fetchMarketPrices(for: scannedItem.itemName)
            return nil
        case .etsy:
            // TODO: Add Etsy service when credentials are available
            // return try await etsyMarketPriceService.fetchMarketPrices(for: scannedItem.itemName)
            return nil
        default:
            return nil
        }
    }

    func fetchEbayData() {
        ebayLoadFailed = false
        isLoadingEbay = true
        Task {
            await fetchEbayDataAsync()
        }
    }

    func fetchStockXData() {
        stockxLoadFailed = false
        isLoadingStockX = true
        Task {
            await fetchStockXDataAsync()
        }
    }

    func fetchEtsyData() {
        etsyLoadFailed = false
        isLoadingEtsy = true
        Task {
            await fetchEtsyDataAsync()
        }
    }

    func hasRealData(for marketplace: Marketplace) -> Bool {
        switch marketplace {
        case .ebay:
            return ebayMarketData != nil && ebayMarketData!.hasData
        case .stockx:
            return stockxMarketData != nil && stockxMarketData!.hasData
        case .etsy:
            return etsyMarketData != nil && etsyMarketData!.hasData
        default:
            return false
        }
    }

    func getRecommendedMarketplaces() -> [Marketplace] {
        // If we have AI recommendation, use that
        if let priceAnalysis = priceAnalysisResult {
            return [priceAnalysis.recommendedMarketplace]
        }

        // Otherwise, use the existing logic
        let itemName = scannedItem.itemName.lowercased()
        let category = scannedItem.category.lowercased()

        var recommended: [Marketplace] = [.ebay]

        if itemName.contains("nike") || itemName.contains("jordan") || itemName.contains("yeezy") ||
           itemName.contains("sneaker") || category.contains("shoes") {
            recommended.append(.stockx)
        }

        if category.contains("clothing") || category.contains("fashion") || itemName.contains("vintage") {
            recommended.append(.poshmark)
            recommended.append(.depop)
        }

        if category.contains("handmade") || category.contains("vintage") || category.contains("craft") {
            recommended.append(.etsy)
        }

        if category.contains("electronics") || category.contains("home") {
            recommended.append(.facebook)
            recommended.append(.amazon)
        }

        recommended.append(.mercari)

        return Array(Set(recommended))
    }

    func specificMarketplacePrice(for marketplace: Marketplace) -> String {
        // If intelligence is unlocked and we have real data, use it
        if marketIntelligenceUnlocked {
            switch marketplace {
            case .ebay:
                if let data = ebayMarketData, data.hasData {
                    return data.formattedAveragePrice
                }
            case .stockx:
                if let data = stockxMarketData, data.hasData {
                    return data.formattedAveragePrice
                }
            case .etsy:
                if let data = etsyMarketData, data.hasData {
                    return data.formattedAveragePrice
                }
            default:
                break
            }

            // If we have AI price analysis, use those prices
            if let priceAnalysisResult,
               let marketplacePrice = priceAnalysisResult.averagePrices[marketplace] {
                return "$\(Int(marketplacePrice))"
            }
        }

        // Fall back to original AI estimated value
        return scannedItem.estimatedValue
    }
}

// MARK: - Custom Button Style
struct MarketplaceCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
