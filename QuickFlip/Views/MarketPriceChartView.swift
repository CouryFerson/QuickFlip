import SwiftUI
import Charts

// MARK: - Display Mode
enum ChartDisplayMode {
    case compact
    case full
}

// MARK: - Market Price Chart View
struct MarketPriceChartView: View {
    let marketData: MarketPriceData
    var displayMode: ChartDisplayMode = .full

    var body: some View {
        VStack(alignment: .leading, spacing: displayMode == .compact ? 12 : 16) {
            headerSection

            if marketData.hasData {
                chartSection

                if displayMode == .full {
                    statisticsSection
                    marketInsightsSection

                    if let strategy = marketData.sellingStrategy {
                        sellingStrategySection(strategy: strategy)
                    }
                } else {
                    compactStatisticsSection
                }
            } else {
                noDataView
            }
        }
        .padding(displayMode == .compact ? 12 : 16)
        .padding(.bottom, displayMode == .compact ? 8 : 0)
        .background(Color(.systemBackground))
    }
}

// MARK: - Private View Components
private extension MarketPriceChartView {

    @ViewBuilder
    var headerSection: some View {
        if displayMode == .full {
            fullHeaderSection
        } else {
            compactHeaderSection
        }
    }

    @ViewBuilder
    var fullHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current eBay Market Prices")
                    .font(.headline)
                    .foregroundColor(.primary)

                if marketData.hasData {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(marketData.totalListings) active listings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if marketData.hasData {
                averagePriceLabel
            }
        }
    }

    @ViewBuilder
    var compactHeaderSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("eBay")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if marketData.hasData {
                    Text("\(marketData.totalListings) listings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if marketData.hasData {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(marketData.formattedAveragePrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    HStack(spacing: 4) {
                        Text("avg price")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Image(systemName: "chevron.right.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.blue.opacity(0.6))
                    }
                }
            }
        }
    }

    @ViewBuilder
    var averagePriceLabel: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(marketData.formattedAveragePrice)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("avg price")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if displayMode == .full {
                Text("Price Distribution")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Chart {
                ForEach(marketData.priceRanges) { range in
                    BarMark(
                        x: .value("Price Range", range.rangeLabel),
                        y: .value("Listings", range.listingCount)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let count = value.as(Int.self) {
                        AxisValueLabel {
                            Text("\(count)")
                                .font(.caption)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: displayMode == .compact ? 8 : 9))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                }
            }
            .frame(height: displayMode == .compact ? 120 : 200)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    var compactStatisticsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                compactStatItem(title: "Range", value: marketData.priceRange)

                Divider()
                    .frame(height: 30)

                compactStatItem(
                    title: "Competition",
                    value: marketData.marketSaturation,
                    valueColor: marketData.totalListings > 30 ? .orange : .green
                )
            }
            .padding(.top, 4)

            // Tap hint
            HStack(spacing: 4) {
                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                Text("Tap for selling strategy")
                    .font(.caption2)
            }
            .foregroundColor(.blue.opacity(0.7))
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    func compactStatItem(title: String, value: String, valueColor: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var statisticsSection: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 16) {
                statisticItem(title: "Range", value: marketData.priceRange)
                Spacer()
                statisticItem(title: "Median", value: marketData.formattedMedianPrice)
                Spacer()
                statisticItem(title: "Competition", value: marketData.marketSaturation, valueColor: marketData.totalListings > 30 ? .orange : .green)
            }
        }
    }

    @ViewBuilder
    var marketInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Market Insights")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                if marketData.marketInsights.freeShippingPercentage > 0 {
                    insightRow(
                        icon: "shippingbox.fill",
                        label: "Offer Free Shipping",
                        value: marketData.marketInsights.formattedFreeShipping,
                        color: .blue
                    )
                }

                if marketData.marketInsights.bestOfferPercentage > 0 {
                    insightRow(
                        icon: "hand.raised.fill",
                        label: "Accept Best Offer",
                        value: marketData.marketInsights.formattedBestOffer,
                        color: .green
                    )
                }

                if marketData.marketInsights.topRatedPercentage > 0 {
                    insightRow(
                        icon: "star.fill",
                        label: "Top-Rated Sellers",
                        value: marketData.marketInsights.formattedTopRated,
                        color: .orange
                    )
                }

                if marketData.marketInsights.hasTopRatedPremium {
                    insightRow(
                        icon: "arrow.up.circle.fill",
                        label: "Top-Rated Premium",
                        value: marketData.marketInsights.formattedTopRatedPremium,
                        color: .purple
                    )
                }
            }
        }
    }

    @ViewBuilder
    func sellingStrategySection(strategy: SellingStrategy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Your Selling Strategy")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Suggested List Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(strategy.formattedSuggestedPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        if strategy.enableBestOffer {
                            strategyBadge(icon: "hand.raised.fill", text: "Enable Offers", color: .blue)
                        }
                        if strategy.offerFreeShipping {
                            strategyBadge(icon: "shippingbox.fill", text: "Free Ship", color: .green)
                        }
                    }
                }

                if !strategy.tips.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(strategy.tips.enumerated()), id: \.offset) { index, tip in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(10)
        }
    }

    @ViewBuilder
    func statisticItem(title: String, value: String, valueColor: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }

    @ViewBuilder
    func insightRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
                .font(.body)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    func strategyBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }

    @ViewBuilder
    var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: displayMode == .compact ? 30 : 40))
                .foregroundColor(.secondary)

            Text("No active listings found")
                .font(displayMode == .compact ? .subheadline : .headline)
                .foregroundColor(.primary)

            if displayMode == .full {
                Text("There aren't enough similar items listed right now to show market data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, displayMode == .compact ? 30 : 40)
    }
}

// MARK: - Loading State View
struct MarketPriceLoadingView: View {
    var displayMode: ChartDisplayMode = .full

    var body: some View {
        VStack(spacing: displayMode == .compact ? 12 : 16) {
            ProgressView()
                .scaleEffect(displayMode == .compact ? 1.0 : 1.2)

            Text("Loading market data...")
                .font(displayMode == .compact ? .caption : .subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, displayMode == .compact ? 40 : 60)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error State View
struct MarketPriceErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void
    var displayMode: ChartDisplayMode = .full

    var body: some View {
        VStack(spacing: displayMode == .compact ? 12 : 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: displayMode == .compact ? 30 : 40))
                .foregroundColor(.orange)

            Text("Unable to load market data")
                .font(displayMode == .compact ? .subheadline : .headline)
                .foregroundColor(.primary)

            if displayMode == .full {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: retryAction) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(displayMode == .compact ? .caption : .subheadline)
                    .padding(.horizontal, displayMode == .compact ? 16 : 20)
                    .padding(.vertical, displayMode == .compact ? 8 : 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, displayMode == .compact ? 30 : 40)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview
#Preview("Full Mode - With Data") {
    ScrollView {
        MarketPriceChartView(marketData: .mock, displayMode: .full)
            .padding()
    }
}

#Preview("Compact Mode - With Data") {
    MarketPriceChartView(marketData: .mock, displayMode: .compact)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Compact Mode - No Data") {
    MarketPriceChartView(marketData: .mockNoData, displayMode: .compact)
        .padding()
}

#Preview("Compact Loading") {
    MarketPriceLoadingView(displayMode: .compact)
        .padding()
}

#Preview("Compact Error") {
    MarketPriceErrorView(errorMessage: "Network connection failed", retryAction: {}, displayMode: .compact)
        .padding()
}
