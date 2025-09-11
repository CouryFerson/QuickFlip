import SwiftUI

struct MarketplaceSelectionView: View {
    let scannedItem: ScannedItem
    let capturedImage: UIImage
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var itemStorage: ItemStorageService
    @EnvironmentObject var imageAnalysisService: ImageAnalysisService
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isAnalyzingPrices = false
    @State private var priceAnalysisResult: MarketplacePriceAnalysis?
    @State private var showingTokenAlert = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                itemPreviewSection
                smartRecommendationSection
                marketplaceGridSection
            }
        }
        .alert("No tokens left", isPresented: $showingTokenAlert) {
            Button("Done", role: .cancel) { }
        } message: {
            Text(subscriptionManager.addTokensMessage)
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
    var smartRecommendationSection: some View {
        VStack(spacing: 0) {
            sectionHeader

            if let priceAnalysis = priceAnalysisResult {
                priceAnalysisContent(analysis: priceAnalysis)
            } else {
                priceAnalysisButton
            }

            if let priceAnalysis = priceAnalysisResult {
                profitCalculatorButton(analysis: priceAnalysis)
                    .padding(.top, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 12)
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
        }
    }
}

// MARK: - Smart Recommendation Components
private extension MarketplaceSelectionView {

    @ViewBuilder
    var sectionHeader: some View {
        HStack {
            Label("Smart Recommendation", systemImage: "sparkles")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)

            Spacer()
        }
    }

    @ViewBuilder
    var priceAnalysisButton: some View {
        Button(action: findBestMarketplace) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 44, height: 44)

                    if isAnalyzingPrices {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(isAnalyzingPrices ? "Analyzing Prices..." : "Find Best Marketplace")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(isAnalyzingPrices ? "Searching all platforms" : "We'll find where this sells best")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !isAnalyzingPrices {
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .disabled(isAnalyzingPrices || !canAnalyzePrices())
        .opacity((isAnalyzingPrices || !canAnalyzePrices()) ? 0.6 : 1.0)

        if !canAnalyzePrices() {
            Text("💡 Price analysis works best with specific brand items")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    func priceAnalysisContent(analysis: MarketplacePriceAnalysis) -> some View {
        PriceAnalysisResultView(analysis: analysis, scannedItem: scannedItem) { marketplace in
            saveScannedItem(marketplace: marketplace, priceAnalysis: analysis)
        }
    }

    @ViewBuilder
    func profitCalculatorButton(analysis: MarketplacePriceAnalysis) -> some View {
        NavigationLink(destination: ProfitCalculatorView(priceAnalysis: analysis, capturedImage: capturedImage)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "dollarsign.arrow.circlepath")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Calculate Real Profit")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("See profit after fees and costs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    var sectionDivider: some View {
        HStack {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)

            Text("Choose Platform")
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
}

// MARK: - Marketplace Grid Components
private extension MarketplaceSelectionView {

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

                    Text(specificMarketplacePrice(for: marketplace))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)

                    if getRecommendedMarketplaces().contains(marketplace) {
                        Text("RECOMMENDED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140) // Uniform height
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(MarketplaceCardButtonStyle())
    }

    @ViewBuilder
    func destinationView(for marketplace: Marketplace) -> some View {
        switch marketplace {
        case .ebay:
            eBayUploadView(listing: EbayListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
        case .facebook:
            FacebookMarketplaceView(listing: FacebookListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
        case .amazon:
            AmazonPrepView(listing: AmazonListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
        case .stockx:
            StockXPrepView(listing: StockXListing(from: scannedItem, image: capturedImage), capturedImage: capturedImage)
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

    func canAnalyzePrices() -> Bool {
        let itemName = scannedItem.itemName.lowercased()
        let genericTerms = ["unknown", "item", "object", "thing", "device", "electronic device"]

        return !genericTerms.contains { itemName.contains($0) }
    }

    func findBestMarketplace() {
        guard authManager.hasTokens() else {
            showingTokenAlert = true
            return
        }

        isAnalyzingPrices = true

        Task {
            do {
                let analysis = try await imageAnalysisService.researchPrices(for: scannedItem.itemName, category: scannedItem.category)

                await MainActor.run {
                    self.priceAnalysisResult = analysis
                    self.isAnalyzingPrices = false
                }

            } catch {
                print("QuickFlip: Price analysis error: \(error)")
                await MainActor.run {
                    self.isAnalyzingPrices = false
                }
            }
        }
    }

    func saveScannedItem(marketplace: Marketplace, priceAnalysis: MarketplacePriceAnalysis? = nil) {
        let analysis = priceAnalysis ?? createDefaultAnalysis(for: marketplace)

        let newItem = ScannedItem(
            itemName: scannedItem.itemName,
            category: scannedItem.category,
            condition: scannedItem.condition,
            description: scannedItem.description,
            estimatedValue: scannedItem.estimatedValue,
            priceAnalysis: analysis
        )

        itemStorage.updateItem(matching: { item in
            item.itemName == scannedItem.itemName &&
            abs(item.timestamp.timeIntervalSinceNow) < 300
        }, with: newItem)
    }

    func createDefaultAnalysis(for marketplace: Marketplace) -> MarketplacePriceAnalysis {
        let basePrice = extractPrice(from: scannedItem.estimatedValue)

        var prices: [Marketplace: Double] = [
            .ebay: basePrice * 0.9,
            .mercari: basePrice * 0.8,
            .facebook: basePrice * 0.75,
            .amazon: basePrice * 1.1,
            .stockx: basePrice * 1.2
        ]

        prices[marketplace] = basePrice

        return MarketplacePriceAnalysis(
            recommendedMarketplace: marketplace,
            confidence: .medium,
            averagePrices: prices,
            reasoning: "User selected marketplace"
        )
    }

    func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-—"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "45") ?? 45.0
    }

    func getRecommendedMarketplaces() -> [Marketplace] {
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
        if let priceAnalysisResult,
           let marketplacePrice = priceAnalysisResult.averagePrices.first(where: { $0.key == marketplace })?.value {
            return "$\(Int(marketplacePrice))"
        } else {
            return scannedItem.estimatedValue
        }
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
