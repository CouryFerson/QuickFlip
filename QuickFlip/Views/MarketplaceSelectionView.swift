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

    // Market Intelligence State (for existing unlock system)
    @State private var marketIntelligenceUnlocked = false
    @State private var isUnlockingIntelligence = false
    @State private var priceAnalysisResult: MarketplacePriceAnalysis?

    // Advanced AI State (new premium feature)
    @State private var advancedAIAnalysis: MarketplacePriceAnalysis?
    @State private var isGeneratingAdvancedAI = false

    // Market Data State
    @State private var ebayMarketData: MarketPriceData?
    @State private var stockxMarketData: MarketPriceData?
    @State private var etsyMarketData: MarketPriceData?

    // Loading States
    @State private var isLoadingEbay = false
    @State private var isLoadingStockX = false
    @State private var isLoadingEtsy = false

    // Error tracking
    @State private var ebayLoadFailed = false
    @State private var stockxLoadFailed = false
    @State private var etsyLoadFailed = false

    // Alerts
    @State private var showingTokenAlert = false
    @State private var showingSubscriptionView = false
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

                // Show appropriate intelligence section based on subscription
                if subscriptionManager.hasStarterOrProAccess {
                    premiumIntelligenceSection
                } else {
                    freeUserIntelligenceSection
                }

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
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
                .environmentObject(subscriptionManager)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Choose Marketplace")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadInitialData()
        }
        .onChange(of: subscriptionManager.hasStarterOrProAccess) { oldValue, newValue in

            // If user just upgraded to premium and charts aren't loaded yet
            if newValue && !marketIntelligenceUnlocked {
                marketIntelligenceUnlocked = true
                loadMarketDataForPremiumUsers()
            }
        }
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
    var premiumIntelligenceSection: some View {
        VStack(spacing: 16) {
            // New Advanced AI Button
            advancedAIButton
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if let analysis = advancedAIAnalysis {
                advancedAIInsightsCard(analysis: analysis)
                    .padding(.horizontal, 16)
            }

            // Original Market Intelligence Section (auto-unlocked for premium)
            MarketIntelligenceSection(
                scannedItem: scannedItem,
                capturedImage: capturedImage,
                supabaseService: supabaseService,
                isUnlocked: .constant(true), // ← Auto-unlocked for premium
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
                onUnlock: { }, // ← No-op since auto-unlocked
                onRetryEbay: fetchEbayData,
                onRetryStockX: fetchStockXData,
                onRetryEtsy: fetchEtsyData,
                onShowPricingDisclaimer: { showPricingDisclaimer = true }
            )
        }
    }

    @ViewBuilder
    var freeUserIntelligenceSection: some View {
        VStack(spacing: 0) {
            // Show the locked charts preview (the teaser)
            MarketIntelligenceSection(
                scannedItem: scannedItem,
                capturedImage: capturedImage,
                supabaseService: supabaseService,
                isUnlocked: .constant(false), // ← Always locked for free users
                isUnlocking: .constant(false),
                priceAnalysisResult: .constant(nil),
                ebayMarketData: .constant(nil),
                stockxMarketData: .constant(nil),
                etsyMarketData: .constant(nil),
                isLoadingEbay: false,
                isLoadingStockX: false,
                isLoadingEtsy: false,
                ebayLoadFailed: false,
                stockxLoadFailed: false,
                etsyLoadFailed: false,
                onUnlock: { showingSubscriptionView = true }, // ← Show upgrade prompt
                onRetryEbay: { },
                onRetryStockX: { },
                onRetryEtsy: { },
                onShowPricingDisclaimer: { showPricingDisclaimer = true }
            )
        }
    }

    @ViewBuilder
    var marketplaceGridSection: some View {
        VStack(spacing: 16) {
            quikListButton
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

// MARK: - Advanced AI Components
private extension MarketplaceSelectionView {

    @ViewBuilder
    var advancedAIButton: some View {
        Button(action: handleAdvancedAITap) {
            HStack(spacing: 12) {
                Image(systemName: isGeneratingAdvancedAI ? "arrow.triangle.2.circlepath" : "sparkles")
                    .font(.title3)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isGeneratingAdvancedAI ? 360 : 0))
                    .animation(isGeneratingAdvancedAI ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isGeneratingAdvancedAI)

                VStack(alignment: .leading, spacing: 2) {
                    Text(advancedAIButtonTitle)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(advancedAIButtonSubtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Button(action: { showPricingDisclaimer = true }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isGeneratingAdvancedAI || isLoadingEbay)
    }

    var advancedAIButtonTitle: String {
        if scannedItem.hasAdvancedAIAnalysis {
            return "Refresh AI Insights"
        } else {
            return "Get Advanced AI Insights"
        }
    }

    var advancedAIButtonSubtitle: String {
        if scannedItem.hasAdvancedAIAnalysis {
            if let timestamp = scannedItem.formattedAIAnalysisTimestamp {
                return "Generated \(timestamp) • 1 token to refresh"
            }
            return "1 token to refresh"
        } else {
            return "Free for this item • Powered by live eBay data"
        }
    }

    @ViewBuilder
    func advancedAIInsightsCard(analysis: MarketplacePriceAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("AI Market Insights")
                    .font(.headline)

                Spacer()

                if let timestamp = scannedItem.formattedAIAnalysisTimestamp {
                    Text(timestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(analysis.reasoning)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Recommended marketplace badge
            HStack {
                Label(analysis.recommendedMarketplace.displayName, systemImage: "star.fill")
                    .font(.subheadline)
                    .foregroundColor(.orange)

                Spacer()

                Text(analysis.confidence.displayText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor(analysis.confidence).opacity(0.15))
                    .foregroundColor(confidenceColor(analysis.confidence))
                    .clipShape(Capsule())
            }

            // All marketplace prices sorted highest to lowest
            if !analysis.averagePrices.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                VStack(spacing: 8) {
                    Text("Price Comparison")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(sortedMarketplacePrices(from: analysis.averagePrices), id: \.0) { marketplace, price in
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: marketplace.systemImage)
                                    .font(.caption)
                                    .foregroundColor(marketplace.color)
                                    .frame(width: 16)

                                Text(marketplace.displayName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Text("$\(Int(price))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(marketplace == analysis.recommendedMarketplace ? .orange : .secondary)

                                // Show star for recommended
                                if marketplace == analysis.recommendedMarketplace {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func unlockMarketIntelligence() {
        // For premium users, charts are automatically unlocked
        // No token charge, just load the data
        isUnlockingIntelligence = true

        // Set loading states for all marketplaces
        isLoadingEbay = true
        isLoadingStockX = true
        isLoadingEtsy = true

        Task {
            // Fetch market data for each marketplace independently
            await fetchEbayDataAsync()
            await fetchStockXDataAsync()
            await fetchEtsyDataAsync()

            await MainActor.run {
                self.marketIntelligenceUnlocked = true
                self.isUnlockingIntelligence = false
            }
        }
    }

    // Helper function to sort prices highest to lowest
    private func sortedMarketplacePrices(from prices: [Marketplace: Double]) -> [(Marketplace, Double)] {
        return prices
            .sorted { $0.value > $1.value } // Highest to lowest
            .map { ($0.key, $0.value) }
    }

    func confidenceColor(_ confidence: AnalysisConfidence) -> Color {
        switch confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

// MARK: - Grid Components
private extension MarketplaceSelectionView {

    @ViewBuilder
    var quikListButton: some View {
        NavigationLink {
            QuikListView(
                supabaseService: supabaseService,
                scannedItem: scannedItem,
                capturedImage: capturedImage
            )
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "bolt.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Quik List")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("List to eBay & StockX at once")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .purple.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }

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
                .multilineTextAlignment(.center)

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
                ZStack {
                    Circle()
                        .fill(marketplace.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: marketplace.systemImage)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(marketplace.color)
                }

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

                    if subscriptionManager.hasStarterOrProAccess && hasRealData(for: marketplace) {
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
                        subscriptionManager.hasStarterOrProAccess && hasRealData(for: marketplace)
                            ? Color.blue.opacity(0.3)
                            : Color(.systemGray5),
                        lineWidth: subscriptionManager.hasStarterOrProAccess && hasRealData(for: marketplace) ? 2 : 1
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

            if subscriptionManager.hasStarterOrProAccess && hasRealData(for: marketplace) {
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

    func loadInitialData() {

        // Load cached advanced AI analysis if exists
        if let cachedAnalysis = scannedItem.advancedAIAnalysis {
            advancedAIAnalysis = cachedAnalysis.toMarketplacePriceAnalysis()
        }

        // Auto-load charts for premium users
        if subscriptionManager.hasStarterOrProAccess {
            marketIntelligenceUnlocked = true
            loadMarketDataForPremiumUsers()
        }
    }

    func loadMarketDataForPremiumUsers() {
        isLoadingEbay = true
        isLoadingStockX = true
        isLoadingEtsy = true

        Task {
            await fetchEbayDataAsync()
            await fetchStockXDataAsync()
            await fetchEtsyDataAsync()
        }
    }

    func handleAdvancedAITap() {
        let isFirstGeneration = !scannedItem.hasAdvancedAIAnalysis

        // If it's a refresh, check for tokens
        if !isFirstGeneration {
            guard authManager.hasTokens() else {
                showingTokenAlert = true
                return
            }
        }

        // Must have eBay data first
        guard let ebayData = ebayMarketData, ebayData.hasData else {
            // If eBay data not loaded yet, wait for it
            if isLoadingEbay {
                return
            }
            // Try to load eBay data first
            fetchEbayData()
            return
        }

        isGeneratingAdvancedAI = true

        Task {
            do {
                let analysis = try await imageAnalysisService.generateAdvancedAnalysis(
                    for: scannedItem.itemName,
                    category: scannedItem.category,
                    ebayData: ebayData,
                    isFirstGeneration: isFirstGeneration
                )

                await MainActor.run {
                    self.advancedAIAnalysis = analysis
                    self.isGeneratingAdvancedAI = false

                    // Save to database
                    saveAdvancedAnalysisToItem(analysis)
                }

            } catch {
                print("QuickFlip: Advanced AI generation error: \(error)")
                await MainActor.run {
                    self.isGeneratingAdvancedAI = false
                }
            }
        }
    }

    func saveAdvancedAnalysisToItem(_ analysis: MarketplacePriceAnalysis) {
        var updatedItem = scannedItem
        updatedItem.advancedAIAnalysis = StorableMarketplacePriceAnalysis(from: analysis)
        updatedItem.aiAnalysisGeneratedAt = Date()

        Task {
            await itemStorage.updateItem(matching: { $0.id == scannedItem.id }, with: updatedItem)
        }
    }

    func fetchEbayDataAsync() async {
        print("QuickFlip: Starting eBay data fetch for: \(scannedItem.itemName)")
        do {
            let data = try await fetchMarketData(for: .ebay)
            print("QuickFlip: eBay data fetched successfully. Has data: \(data?.hasData ?? false)")
            await MainActor.run {
                self.ebayMarketData = data
                self.isLoadingEbay = false
                self.ebayLoadFailed = (data == nil)
                print("QuickFlip: eBay state updated - Loading: false, Failed: \(data == nil)")
            }
        } catch {
            print("QuickFlip: eBay data error: \(error)")
            await MainActor.run {
                self.ebayMarketData = nil
                self.isLoadingEbay = false
                self.ebayLoadFailed = true
                print("QuickFlip: eBay state updated - Loading: false, Failed: true")
            }
        }
    }

    func fetchStockXDataAsync() async {
        do {
            let data = try await fetchMarketData(for: .stockx)
            await MainActor.run {
                self.stockxMarketData = data
                self.isLoadingStockX = false
                self.stockxLoadFailed = (data == nil)
            }
        } catch {
            print("QuickFlip: StockX data error: \(error)")
            await MainActor.run {
                self.stockxMarketData = nil
                self.isLoadingStockX = false
                self.stockxLoadFailed = true
            }
        }
    }

    func fetchEtsyDataAsync() async {
        do {
            let data = try await fetchMarketData(for: .etsy)
            await MainActor.run {
                self.etsyMarketData = data
                self.isLoadingEtsy = false
                self.etsyLoadFailed = (data == nil)
            }
        } catch {
            print("QuickFlip: Etsy data error: \(error)")
            await MainActor.run {
                self.etsyMarketData = nil
                self.isLoadingEtsy = false
                self.etsyLoadFailed = true
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
            return nil
        case .etsy:
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
        // If we have advanced AI recommendation, use that
        if let analysis = advancedAIAnalysis {
            return [analysis.recommendedMarketplace]
        }

        // If we have price analysis from the charts, use that
        if let priceAnalysis = priceAnalysisResult {
            return [priceAnalysis.recommendedMarketplace]
        }

        // Otherwise use basic logic
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
        // If we have advanced AI analysis, use those prices
        if let analysis = advancedAIAnalysis,
           let price = analysis.averagePrices[marketplace] {
            return "$\(Int(price))"
        }

        // If premium and we have real data, use it
        if subscriptionManager.hasStarterOrProAccess {
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

            // Check price analysis result
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
