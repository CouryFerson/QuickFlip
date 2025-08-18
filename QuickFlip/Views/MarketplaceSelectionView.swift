import SwiftUI

struct MarketplaceSelectionView: View {
    let itemAnalysis: ItemAnalysis
    let capturedImage: UIImage
    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var isAnalyzingPrices = false
    @State private var priceAnalysisResult: MarketplacePriceAnalysis?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("Choose Marketplace")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Where would you like to list this item?")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    // Item Preview
                    VStack(spacing: 8) {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 120)
                            .cornerRadius(8)

                        Text(itemAnalysis.itemName)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        Text(itemAnalysis.estimatedValue)
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Smart Recommendation Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                        Text("SMART RECOMMENDATION")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)

                    if let priceAnalysis = priceAnalysisResult {
                        // Show price analysis results
                        PriceAnalysisResultView(
                            analysis: priceAnalysis,
                            itemAnalysis: itemAnalysis,
                            capturedImage: capturedImage
                        ) { marketplace in
                            // Save item and navigate to webview to see similar listings
                            saveScannedItem(marketplace: marketplace, priceAnalysis: priceAnalysis)
                        }
                    } else {
                        // Find Best Marketplace Button
                        Button(action: {
                            findBestMarketplace()
                        }) {
                            HStack {
                                if isAnalyzingPrices {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "magnifyingglass.circle.fill")
                                        .font(.title2)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isAnalyzingPrices ? "Analyzing Prices..." : "Find Best Marketplace")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    Text(isAnalyzingPrices ? "Searching all platforms" : "We'll find where this sells for the most")
                                        .font(.caption)
                                        .opacity(0.9)
                                }

                                Spacer()

                                if !isAnalyzingPrices {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .disabled(isAnalyzingPrices || !canAnalyzePrices())
                        .padding(.horizontal)

                        if !canAnalyzePrices() {
                            Text("💡 Price analysis works best with specific brand items")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }

                // Show price analysis results
                if let priceAnalysis = priceAnalysisResult {
                    priceAnalyticsView(analysis: priceAnalysis)
                }

                // OR divider
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)

                    Text("OR CHOOSE MANUALLY")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal)

                // Marketplace Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(Marketplace.allCases) { marketplace in
                        NavigationLink(
                            destination: ListingPreparationView(
                                itemAnalysis: itemAnalysis,
                                capturedImage: capturedImage,
                                selectedMarketplace: marketplace
                            )
                            .onAppear {
                                // Save the item when user selects a marketplace manually
                                saveScannedItem(marketplace: marketplace)
                            }
                        ) {
                            MarketplaceCard(
                                marketplace: marketplace,
                                isRecommended: getRecommendedMarketplaces().contains(marketplace)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Choose Marketplace")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func canAnalyzePrices() -> Bool {
        let itemName = itemAnalysis.itemName.lowercased()

        // Check if item is specific enough for price analysis
        let genericTerms = ["unknown", "item", "object", "thing", "device", "electronic device"]

        for term in genericTerms {
            if itemName.contains(term) {
                return false
            }
        }

        return true
    }

    private func findBestMarketplace() {
        isAnalyzingPrices = true

        Task {
            do {
                let priceService = OpenAIPriceResearchService()
                let analysis = try await priceService.researchPrices(
                    for: itemAnalysis.itemName,
                    category: itemAnalysis.category
                )

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

    // MARK: - Storage Integration
    private func saveScannedItem(marketplace: Marketplace, priceAnalysis: MarketplacePriceAnalysis? = nil) {
        let analysis = priceAnalysis ?? createDefaultAnalysis(for: marketplace)

        let newItem = ScannedItem(
            itemName: itemAnalysis.itemName,
            category: itemAnalysis.category,
            condition: itemAnalysis.condition,
            description: itemAnalysis.description,
            estimatedValue: itemAnalysis.estimatedValue,
            image: capturedImage,
            priceAnalysis: analysis
        )

        // Update existing item or create new one
        itemStorage.updateItem(matching: { item in
            item.itemName == itemAnalysis.itemName &&
            abs(item.timestamp.timeIntervalSinceNow) < 300 // Within 5 minutes
        }, with: newItem)
    }

    private func createDefaultAnalysis(for marketplace: Marketplace) -> MarketplacePriceAnalysis {
        // Create a simple analysis if we don't have AI price data
        let basePrice = extractPrice(from: itemAnalysis.estimatedValue)

        // Create base prices for common marketplaces
        var prices: [Marketplace: Double] = [
            .ebay: basePrice * 0.9,
            .mercari: basePrice * 0.8,
            .facebook: basePrice * 0.75,
            .amazon: basePrice * 1.1,
            .stockx: basePrice * 1.2
        ]

        // Ensure the selected marketplace has the base price (and avoid duplicates)
        prices[marketplace] = basePrice

        return MarketplacePriceAnalysis(
            recommendedMarketplace: marketplace,
            confidence: .medium,
            averagePrices: prices,
            reasoning: "User selected marketplace"
        )
    }
    private func extractPrice(from value: String) -> Double {
        // Extract a number from "$40-$60" format
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "45") ?? 45.0
    }

    // Keep existing helper methods...
    private func getRecommendedMarketplaces() -> [Marketplace] {
        let itemName = itemAnalysis.itemName.lowercased()
        let category = itemAnalysis.category.lowercased()

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
}

private extension MarketplaceSelectionView {
    @ViewBuilder
    private func priceAnalyticsView(analysis: MarketplacePriceAnalysis) -> some View {
        // Add Profit Calculator Button
        NavigationLink(
            destination: ProfitCalculatorView(
                priceAnalysis: analysis,
                itemAnalysis: itemAnalysis,
                capturedImage: capturedImage
            )
        ) {
            HStack {
                Image(systemName: "calculator.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Calculate Real Profit")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("See profit after fees and costs")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}
