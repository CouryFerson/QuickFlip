//
//  PriceHistoryChartView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/2/25.
//

import SwiftUI
import Charts

// MARK: - Price History Chart View
struct PriceHistoryChartView: View {
    let priceHistory: PriceHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection

            if priceHistory.hasData {
                chartSection
                statisticsSection
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
private extension PriceHistoryChartView {

    @ViewBuilder
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("90-Day Price History")
                    .font(.headline)
                    .foregroundColor(.primary)

                if priceHistory.hasData {
                    HStack(spacing: 8) {
                        trendIndicator
                        Text(priceHistory.trendDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if priceHistory.hasData {
                averagePriceLabel
            }
        }
    }

    @ViewBuilder
    var trendIndicator: some View {
        Image(systemName: priceHistory.isPriceIncreasing ? "arrow.up.right" :
              priceHistory.isPriceDecreasing ? "arrow.down.right" : "arrow.right")
            .font(.caption)
            .foregroundColor(priceHistory.isPriceIncreasing ? .green :
                           priceHistory.isPriceDecreasing ? .red : .orange)
    }

    @ViewBuilder
    var averagePriceLabel: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(priceHistory.formattedAveragePrice)
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
        Chart {
            ForEach(priceHistory.dataPoints) { dataPoint in
                // Price range area
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    yStart: .value("Min", dataPoint.minPrice),
                    yEnd: .value("Max", dataPoint.maxPrice)
                )
                .foregroundStyle(Color.blue.opacity(0.1))

                // Average price line
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Price", dataPoint.averagePrice)
                )
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))

                // Data point
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Price", dataPoint.averagePrice)
                )
                .foregroundStyle(Color.blue)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption)
                    }
                    AxisGridLine()
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let price = value.as(Double.self) {
                    AxisValueLabel {
                        Text("$\(Int(price))")
                            .font(.caption)
                    }
                    AxisGridLine()
                }
            }
        }
        .frame(height: 200)
    }

    @ViewBuilder
    var statisticsSection: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 16) {
                statisticItem(title: "Range", value: priceHistory.priceRange)
                Spacer()
                statisticItem(title: "Sales", value: "\(priceHistory.totalSales)")
                Spacer()
                statisticItem(
                    title: "Change",
                    value: priceHistory.formattedPriceChange,
                    valueColor: priceHistory.isPriceIncreasing ? .green :
                               priceHistory.isPriceDecreasing ? .red : .primary
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
    var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No recent sales data")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Not enough completed sales in the last 90 days to show trends")
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
struct PriceHistoryLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading price history...")
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
struct PriceHistoryErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Unable to load price history")
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
    PriceHistoryChartView(priceHistory: .mock)
        .padding()
}

#Preview("No Data") {
    PriceHistoryChartView(priceHistory: .mockNoData)
        .padding()
}

#Preview("Loading") {
    PriceHistoryLoadingView()
        .padding()
}

#Preview("Error") {
    PriceHistoryErrorView(errorMessage: "Network connection failed") {
        print("Retry tapped")
    }
    .padding()
}
