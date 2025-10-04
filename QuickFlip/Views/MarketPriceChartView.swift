import SwiftUI
import Charts

// MARK: - Market Price Chart View
struct MarketPriceChartView: View {
    let marketData: MarketPriceData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection

            if marketData.hasData {
                chartSection
                statisticsSection
                insightsSection
            } else {
                noDataView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Private View Components
private extension MarketPriceChartView {

    @ViewBuilder
    var headerSection: some View {
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
            Text("Price Distribution")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

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
                                .font(.system(size: 9))
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                }
            }
            .frame(height: 200)
            .padding(.bottom, 8)
        }
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
                statisticItem(title: "Listings", value: "\(marketData.totalListings)")
            }
        }
    }

    @ViewBuilder
    var insightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            Text("Market Insights")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                insightBadge(
                    icon: "chart.line.uptrend.xyaxis",
                    text: marketData.marketSaturation,
                    color: marketData.totalListings > 30 ? .orange : .green
                )

                insightBadge(
                    icon: "tag.fill",
                    text: "List at \(marketData.suggestedPricing)",
                    color: .blue
                )
            }
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
    func insightBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }

    @ViewBuilder
    var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No active listings found")
                .font(.headline)
                .foregroundColor(.primary)

            Text("There aren't enough similar items listed right now to show market data")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Loading State View
struct MarketPriceLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading market data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Error State View
struct MarketPriceErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Unable to load market data")
                .font(.headline)
                .foregroundColor(.primary)

            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: retryAction) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview("With Data") {
    MarketPriceChartView(marketData: .mock)
        .padding()
}

#Preview("No Data") {
    MarketPriceChartView(marketData: .mockNoData)
        .padding()
}

#Preview("Loading") {
    MarketPriceLoadingView()
        .padding()
}

#Preview("Error") {
    MarketPriceErrorView(errorMessage: "Network connection failed") {
        print("Retry tapped")
    }
    .padding()
}
