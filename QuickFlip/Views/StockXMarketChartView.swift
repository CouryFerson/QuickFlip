import SwiftUI

// MARK: - StockX Market Chart View
struct StockXMarketChartView: View {
    let product: StockXProduct
    let variant: StockXVariant
    let marketData: StockXMarketData
    let displayMode: ChartDisplayMode

    // StockX Theme Colors
    private let bgDark = Color(UIColor.systemBackground)
    private let bgCard = Color(UIColor.secondarySystemBackground)
    private let textPrimary = Color.primary
    private let textSecondary = Color.secondary
    private let accentGreen = Color(red: 0.0, green: 0.8, blue: 0.4)
    private let accentRed = Color(red: 0.9, green: 0.2, blue: 0.2)

    var body: some View {
        VStack(spacing: displayMode == .compact ? 12 : 16) {
            if displayMode == .full {
                headerSection
            }

            priceStatsSection

            // Show quick strategy tip in compact mode
            if displayMode == .compact {
                quickStrategyTip
            }

            if displayMode == .full {
                marketInsightsSection
                sellingStrategySection
            }
        }
        .padding(displayMode == .compact ? 16 : 20)
        .background(bgDark)
        .cornerRadius(displayMode == .compact ? 12 : 16)
    }
}

// MARK: - View Components
private extension StockXMarketChartView {

    @ViewBuilder
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Market Data")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(accentGreen)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentGreen)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accentGreen.opacity(0.15))
                .cornerRadius(12)
            }

            HStack(spacing: 8) {
                Text(product.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textSecondary)
                    .lineLimit(1)

                Text("•")
                    .foregroundColor(textSecondary.opacity(0.5))

                Text("Size \(variant.sizeDisplay)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textSecondary)
            }
        }
    }

    @ViewBuilder
    var priceStatsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                priceStatCard(
                    title: "Lowest Ask",
                    price: marketData.lowestAsk,
                    color: accentRed
                )

                priceStatCard(
                    title: "Highest Bid",
                    price: marketData.highestBid,
                    color: accentGreen
                )
            }

            // Show additional stats in compact mode
            if displayMode == .compact {
                HStack(spacing: 12) {
                    compactInsightCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Spread",
                        value: "$\(Int(marketData.lowestAsk - marketData.highestBid))"
                    )

                    compactInsightCard(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Activity",
                        value: marketActivity
                    )
                }
            }

            if displayMode == .full {
                HStack(spacing: 12) {
                    priceStatCard(
                        title: "Sell Faster",
                        price: marketData.sellFaster,
                        color: accentGreen.opacity(0.8)
                    )

                    priceStatCard(
                        title: "Earn More",
                        price: marketData.earnMore,
                        color: accentGreen
                    )
                }
            }
        }
    }

    @ViewBuilder
    func compactInsightCard(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(accentGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(textSecondary)
                    .textCase(.uppercase)

                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textPrimary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(bgCard)
        .cornerRadius(8)
    }

    @ViewBuilder
    func priceStatCard(title: String, price: Double, color: Color) -> some View {
        VStack(spacing: displayMode == .compact ? 6 : 8) {
            Text(title)
                .font(.system(size: displayMode == .compact ? 11 : 12, weight: .medium))
                .foregroundColor(textSecondary)
                .textCase(.uppercase)

            Text("$\(Int(price))")
                .font(.system(size: displayMode == .compact ? 20 : 24, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, displayMode == .compact ? 12 : 16)
        .background(bgCard)
        .cornerRadius(8)
    }

    @ViewBuilder
    var marketInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Insights")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(textPrimary)

            VStack(spacing: 8) {
                insightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Price Spread",
                    value: "$\(Int(marketData.lowestAsk - marketData.highestBid))"
                )

                insightRow(
                    icon: "percent",
                    title: "Potential Profit",
                    value: "\(Int(((marketData.lowestAsk - marketData.highestBid) / marketData.highestBid) * 100))%"
                )

                insightRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Market Activity",
                    value: marketActivity
                )

                // Show number of active asks if available from market data
                if let askCount = estimatedAskCount {
                    insightRow(
                        icon: "tag.fill",
                        title: "Active Listings",
                        value: "\(askCount)+ sellers"
                    )
                }
            }
        }
        .padding(16)
        .background(bgCard)
        .cornerRadius(12)
    }

    @ViewBuilder
    func insightRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(accentGreen)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textPrimary)
        }
    }

    @ViewBuilder
    var sellingStrategySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selling Strategy")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(textPrimary)

                Spacer()

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 10) {
                strategyCard(
                    title: "Quick Sale",
                    description: "List at Sell Faster price to compete with active sellers",
                    price: marketData.sellFaster,
                    icon: "bolt.fill",
                    recommended: marketData.sellFaster < marketData.lowestAsk
                )

                strategyCard(
                    title: "Maximum Profit",
                    description: "List at Earn More to maximize your payout",
                    price: marketData.earnMore,
                    icon: "dollarsign.circle.fill",
                    recommended: marketData.earnMore >= marketData.lowestAsk
                )

                strategyCard(
                    title: "Beat Market",
                    description: "Price just below lowest ask for instant visibility",
                    price: marketData.lowestAsk - 1,
                    icon: "star.fill",
                    recommended: false
                )
            }
        }
        .padding(16)
        .background(bgCard)
        .cornerRadius(12)
    }

    @ViewBuilder
    func strategyCard(title: String, description: String, price: Double, icon: String, recommended: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(recommended ? accentGreen : textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textPrimary)

                    if recommended {
                        Text("BEST")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(accentGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentGreen.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Text("$\(Int(price))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(recommended ? accentGreen : textPrimary)
        }
        .padding(12)
        .background(recommended ? accentGreen.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(recommended ? accentGreen.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // Computed property for market activity
    var marketActivity: String {
        let spread = marketData.lowestAsk - marketData.highestBid
        let spreadPercent = (spread / marketData.highestBid) * 100

        if spreadPercent < 5 {
            return "Very Active"
        } else if spreadPercent < 15 {
            return "Active"
        } else if spreadPercent < 30 {
            return "Moderate"
        } else {
            return "Low Activity"
        }
    }

    // Estimated ask count based on market activity
    var estimatedAskCount: Int? {
        let spread = marketData.lowestAsk - marketData.highestBid
        let spreadPercent = (spread / marketData.highestBid) * 100

        // Estimate based on spread - tighter spread usually means more sellers
        if spreadPercent < 5 {
            return 50  // Very competitive
        } else if spreadPercent < 15 {
            return 25  // Active market
        } else if spreadPercent < 30 {
            return 10  // Moderate
        } else {
            return 5   // Lower competition
        }
    }

    @ViewBuilder
    var quickStrategyTip: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Quick Tip")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.orange)

                Text(strategyRecommendation)
                    .font(.system(size: 12))
                    .foregroundColor(textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    var strategyRecommendation: String {
        let spread = marketData.lowestAsk - marketData.highestBid
        let spreadPercent = (spread / marketData.highestBid) * 100

        if spreadPercent < 5 {
            return "Price at $\(Int(marketData.sellFaster)) for quick sale in competitive market"
        } else if marketData.earnMore < marketData.lowestAsk {
            return "List at $\(Int(marketData.earnMore)) to maximize profit"
        } else {
            return "Beat lowest ask at $\(Int(marketData.lowestAsk - 1)) for visibility"
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleProduct = StockXProduct(
        productId: "test-id",
        brand: "Nike",
        productType: "sneakers",
        styleId: "DZ5485-612",
        urlKey: "air-jordan-4-retro-craft-medium-olive",
        title: "Air Jordan 4 Retro Craft Medium Olive",
        productAttributes: ProductAttributes(
            color: "Medium Olive",
            colorway: "Medium Olive/Pale Vanilla",
            gender: "men",
            releaseDate: "2024-01-20",
            retailPrice: 210,
            season: nil
        )
    )

    let sampleVariant = StockXVariant(
        productId: "test-id",
        variantId: "variant-id",
        variantName: "10.5",
        variantValue: "10.5",
        sizeChart: VariantSizeChart(
            availableConversions: [],
            defaultConversion: SizeDetail(size: "10.5", type: "us m")
        ),
        gtins: nil,
        isFlexEligible: true,
        isDirectEligible: false
    )

    let sampleMarketData = StockXMarketData(
        productId: "test-id",
        variantId: "variant-id",
        currencyCode: "USD",
        lowestAskAmount: "215",
        highestBidAmount: "195",
        sellFasterAmount: "210",
        earnMoreAmount: "220",
        flexLowestAskAmount: nil,
        standardMarketData: nil,
        flexMarketData: nil,
        directMarketData: nil
    )

    ScrollView {
        VStack(spacing: 20) {
            StockXMarketChartView(
                product: sampleProduct,
                variant: sampleVariant,
                marketData: sampleMarketData,
                displayMode: .full
            )

            StockXMarketChartView(
                product: sampleProduct,
                variant: sampleVariant,
                marketData: sampleMarketData,
                displayMode: .compact
            )
        }
        .padding()
    }
    .background(Color.black)
}
