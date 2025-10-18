import SwiftUI

// MARK: - Market Intelligence Section
struct MarketIntelligenceSection: View {
    let scannedItem: ScannedItem
    let capturedImage: UIImage
    let supabaseService: SupabaseService

    // State
    @Binding var isUnlocked: Bool
    @Binding var isUnlocking: Bool
    @Binding var priceAnalysisResult: MarketplacePriceAnalysis?
    @Binding var ebayMarketData: MarketPriceData?
    @Binding var stockxMarketData: MarketPriceData?
    @Binding var etsyMarketData: MarketPriceData?
    @State private var showPricingDisclaimer = false

    // Loading states
    let isLoadingEbay: Bool
    let isLoadingStockX: Bool
    let isLoadingEtsy: Bool

    // Error states
    let ebayLoadFailed: Bool
    let stockxLoadFailed: Bool
    let etsyLoadFailed: Bool

    // Actions
    let onUnlock: () -> Void
    let onRetryEbay: () -> Void
    let onRetryStockX: () -> Void
    let onRetryEtsy: () -> Void
    let onShowPricingDisclaimer: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader

            if isUnlocked {
                unlockedContent
            } else {
                lockedContent
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
}

// MARK: - Private Components
private extension MarketIntelligenceSection {

    @ViewBuilder
    var sectionHeader: some View {
        HStack {
            Label("Market Intelligence", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)

            if !isUnlocked {
                Button(action: onShowPricingDisclaimer) {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()

            if isUnlocked {
                unlockedBadge
            }
        }
        .padding(.bottom, isUnlocked ? 16 : 0)
    }

    @ViewBuilder
    var unlockedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
            Text("UNLOCKED")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.green)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.15))
        .clipShape(Capsule())
    }

    @ViewBuilder
    var lockedContent: some View {
        VStack(spacing: 0) {
            lockedPreview
            unlockButton
        }
    }

    @ViewBuilder
    var lockedPreview: some View {
        ZStack {
            // Blurred background with fake chart
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("eBay")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("24 listings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$127")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("avg price")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Fake chart bars
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<6) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: CGFloat.random(in: 40...80))
                    }
                }
                .frame(height: 100)

                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Text("Range")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("$80-$180")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 30)

                    VStack(spacing: 2) {
                        Text("Competition")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Moderate")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .blur(radius: 4)
            .opacity(0.5)

            // Lock overlay
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                VStack(spacing: 8) {
                    Text("Unlock Market Intelligence")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Get complete market analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 20)
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    var unlockButton: some View {
        Button(action: onUnlock) {
            VStack(spacing: 16) {
                Divider()
                    .padding(.top, 8)

                // Value propositions
                VStack(spacing: 10) {
                    valuePropositionRow(icon: "sparkles", text: "AI marketplace recommendation", color: .orange)
                    valuePropositionRow(icon: "chart.bar.fill", text: "Real-time data for eBay", color: .blue)
                    valuePropositionRow(icon: "dollarsign.circle.fill", text: "Profit calculator access", color: .green)
                }

                // Unlock button
                HStack(spacing: 12) {
                    if isUnlocking {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.headline)
                    }

                    Text(isUnlocking ? "Unlocking..." : "Unlock for 1 Token")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .disabled(isUnlocking)
        .opacity(isUnlocking ? 0.7 : 1.0)
    }

    @ViewBuilder
    func valuePropositionRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundColor(.green.opacity(0.6))
        }
    }

    @ViewBuilder
    var unlockedContent: some View {
        VStack(spacing: 16) {
            // Swipeable charts - NOW WITH STOCKX!
            SwipeableMarketChartsView(
                scannedItem: scannedItem,
                supabaseService: supabaseService, // Need to pass this from parent
                ebayData: ebayMarketData,
                stockxData: stockxMarketData,
                etsyData: etsyMarketData,
                isLoadingEbay: isLoadingEbay,
                isLoadingEtsy: isLoadingEtsy,
                ebayLoadFailed: ebayLoadFailed,
                etsyLoadFailed: etsyLoadFailed,
                recommendedMarketplace: priceAnalysisResult?.recommendedMarketplace ?? .ebay,
                onRetryEbay: onRetryEbay,
                onRetryEtsy: onRetryEtsy
            )

            // AI Recommendation card (if available)
            if let priceAnalysis = priceAnalysisResult {
                aiRecommendationCard(analysis: priceAnalysis)
            }

            // Profit Calculator button (if AI analysis available)
            if let priceAnalysis = priceAnalysisResult {
                profitCalculatorButton(analysis: priceAnalysis)
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    func aiRecommendationCard(analysis: MarketplacePriceAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)

                Text("AI Recommendation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            // Top recommended marketplace
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(analysis.recommendedMarketplace.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: analysis.recommendedMarketplace.systemImage)
                        .font(.title3)
                        .foregroundColor(analysis.recommendedMarketplace.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.recommendedMarketplace.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let price = analysis.averagePrices[analysis.recommendedMarketplace] {
                        Text("$\(Int(price))")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }

                    confidenceBadge(confidence: analysis.confidence)
                }

                Spacer()
            }

            if !analysis.reasoning.isEmpty {
                Text(analysis.reasoning)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Top 3 price comparison
            if analysis.averagePrices.count > 1 {
                Divider()
                    .padding(.vertical, 4)

                VStack(spacing: 8) {
                    Text("Price Comparison")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(topThreeMarketplaces(from: analysis.averagePrices), id: \.0) { marketplace, price in
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

                            Text("$\(Int(price))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(marketplace == analysis.recommendedMarketplace ? .green : .secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }

    func topThreeMarketplaces(from prices: [Marketplace: Double]) -> [(Marketplace, Double)] {
        return prices
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key, $0.value) }
    }

    @ViewBuilder
    func confidenceBadge(confidence: AnalysisConfidence) -> some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon(for: confidence))
                .font(.caption2)
            Text(confidence.displayText.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(confidenceColor(for: confidence))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(confidenceColor(for: confidence).opacity(0.15))
        .clipShape(Capsule())
    }

    func confidenceIcon(for confidence: AnalysisConfidence) -> String {
        switch confidence {
        case .high: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "questionmark.circle.fill"
        }
    }

    func confidenceColor(for confidence: AnalysisConfidence) -> Color {
        switch confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
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
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
