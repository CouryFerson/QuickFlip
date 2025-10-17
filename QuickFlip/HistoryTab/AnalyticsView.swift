//
//  AnalyticsView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/16/25.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var itemStorage: ItemStorageService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                overviewSection
                performanceInsightsSection
                marketplaceBreakdownSection
                revenueChartSection
                categoryBreakdownSection
                actionableInsightsSection
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
// MARK: - View Components
private extension AnalyticsView {
    @ViewBuilder
    var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Overview", icon: "chart.bar.fill")

            HStack(spacing: 12) {
                overviewCard(
                    title: "Total Items",
                    value: "\(itemStorage.totalItemCount)",
                    color: .blue
                )

                overviewCard(
                    title: "Items Sold",
                    value: "\(itemStorage.soldItems.count)",
                    color: .green
                )

                overviewCard(
                    title: "Active Listings",
                    value: "\(itemStorage.listedItems.count)",
                    color: .orange
                )
            }
        }
    }

    @ViewBuilder
    func overviewCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
        )
    }

    @ViewBuilder
    var performanceInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Performance", icon: "chart.line.uptrend.xyaxis")

            VStack(spacing: 12) {
                performanceMetric(
                    label: "Total Revenue",
                    value: itemStorage.formattedTotalRevenue,
                    color: .green,
                    icon: "dollarsign.circle.fill"
                )

                performanceMetric(
                    label: "Net Profit",
                    value: itemStorage.formattedTotalProfit,
                    color: itemStorage.totalProfit >= 0 ? .green : .red,
                    icon: "chart.line.uptrend.xyaxis"
                )

                if itemStorage.soldItems.count > 0 {
                    let avgProfit = itemStorage.totalProfit / Double(itemStorage.soldItems.count)
                    performanceMetric(
                        label: "Avg Profit per Sale",
                        value: String(format: "$%.2f", avgProfit),
                        color: avgProfit >= 0 ? .green : .red,
                        icon: "chart.bar.fill"
                    )
                }

                if itemStorage.soldItems.count > 0 && itemStorage.totalRevenue > 0 {
                    let margin = (itemStorage.totalProfit / itemStorage.totalRevenue) * 100
                    performanceMetric(
                        label: "Profit Margin",
                        value: String(format: "%.1f%%", margin),
                        color: margin >= 30 ? .green : margin >= 15 ? .orange : .red,
                        icon: "percent"
                    )
                }

                performanceMetric(
                    label: "Conversion Rate",
                    value: conversionRateText,
                    color: .blue,
                    icon: "arrow.triangle.2.circlepath"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
        }
    }

    @ViewBuilder
    func performanceMetric(label: String, value: String, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }

    @ViewBuilder
    var marketplaceBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Marketplace Performance", icon: "storefront.fill")

            if !itemStorage.soldItems.isEmpty {
                VStack(spacing: 12) {
                    ForEach(marketplaceStats, id: \.marketplace) { stat in
                        marketplaceRow(stat: stat)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                )
            } else {
                emptyStateCard(message: "No sales data yet")
            }
        }
    }

    @ViewBuilder
    func marketplaceRow(stat: MarketplaceStat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stat.marketplace)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(stat.count) sold")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Revenue")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", stat.totalRevenue))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg Profit")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", stat.avgProfit))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(stat.avgProfit >= 0 ? .green : .red)
                }

                Spacer()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * stat.percentage, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    var revenueChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Revenue Over Time", icon: "chart.xyaxis.line")

            if !itemStorage.soldItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Chart(revenueByMonth) { dataPoint in
                        LineMark(
                            x: .value("Month", dataPoint.month),
                            y: .value("Revenue", dataPoint.revenue)
                        )
                        .foregroundStyle(Color.green)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Month", dataPoint.month),
                            y: .value("Revenue", dataPoint.revenue)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                )
            } else {
                emptyStateCard(message: "No sales data to display")
            }
        }
    }

    @ViewBuilder
    var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Top Categories", icon: "square.grid.2x2.fill")

            if !itemStorage.scannedItems.isEmpty {
                VStack(spacing: 8) {
                    ForEach(topCategories.prefix(5), id: \.category) { stat in
                        categoryRow(stat: stat)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                )
            } else {
                emptyStateCard(message: "No items scanned yet")
            }
        }
    }

    @ViewBuilder
    func categoryRow(stat: CategoryStat) -> some View {
        HStack {
            Text(stat.category)
                .font(.subheadline)

            Spacer()

            Text("\(stat.count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    var actionableInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Insights & Recommendations", icon: "lightbulb.fill")

            VStack(spacing: 12) {
                ForEach(actionableInsights, id: \.title) { insight in
                    insightCard(insight: insight)
                }
            }
        }
    }

    @ViewBuilder
    func insightCard(insight: Insight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundColor(insight.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(insight.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(insight.color.opacity(0.1))
        )
    }

    @ViewBuilder
    func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
        }
    }

    @ViewBuilder
    func emptyStateCard(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
        )
    }

    // MARK: - Computed Properties

    var conversionRateText: String {
        let totalItems = itemStorage.totalItemCount
        let soldItems = itemStorage.soldItems.count

        if totalItems == 0 { return "0%" }
        let rate = (Double(soldItems) / Double(totalItems)) * 100
        return String(format: "%.1f%%", rate)
    }

    var marketplaceStats: [MarketplaceStat] {
        let soldItems = itemStorage.soldItems
        guard !soldItems.isEmpty else { return [] }

        let grouped = Dictionary(grouping: soldItems) { item in
            item.listingStatus.soldMarketplace ?? "Unknown"
        }

        let totalSold = soldItems.count

        return grouped.map { marketplace, items in
            let revenue = items.compactMap { $0.listingStatus.soldPrice }.reduce(0, +)
            let profits = items.compactMap { $0.listingStatus.netProfit }
            let avgProfit = profits.isEmpty ? 0 : profits.reduce(0, +) / Double(profits.count)

            return MarketplaceStat(
                marketplace: marketplace,
                count: items.count,
                totalRevenue: revenue,
                avgProfit: avgProfit,
                percentage: Double(items.count) / Double(totalSold)
            )
        }
        .sorted { $0.totalRevenue > $1.totalRevenue }
    }

    var revenueByMonth: [RevenueDataPoint] {
        let soldItems = itemStorage.soldItems
        guard !soldItems.isEmpty else { return [] }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: soldItems) { item in
            guard let dateSold = item.listingStatus.dateSold else { return "" }
            let components = calendar.dateComponents([.year, .month], from: dateSold)
            return "\(components.year ?? 0)-\(String(format: "%02d", components.month ?? 0))"
        }

        return grouped.compactMap { monthKey, items in
            guard !monthKey.isEmpty else { return nil }
            let revenue = items.compactMap { $0.listingStatus.soldPrice }.reduce(0, +)
            return RevenueDataPoint(month: monthKey, revenue: revenue)
        }
        .sorted { $0.month < $1.month }
    }

    var topCategories: [CategoryStat] {
        let grouped = Dictionary(grouping: itemStorage.scannedItems) { item in
            item.categoryName ?? "Unknown"
        }

        return grouped.map { category, items in
            CategoryStat(category: category, count: items.count)
        }
        .sorted { $0.count > $1.count }
    }

    var actionableInsights: [Insight] {
        var insights: [Insight] = []

        // Ready to list items
        let readyCount = itemStorage.readyToListItems.count
        if readyCount > 0 {
            insights.append(Insight(
                title: "\(readyCount) item\(readyCount == 1 ? "" : "s") ready to list",
                message: "You have items that are ready to be posted to marketplaces",
                icon: "clock.fill",
                color: .orange
            ))
        }

        // Best marketplace
        if let bestMarketplace = marketplaceStats.first {
            insights.append(Insight(
                title: "\(bestMarketplace.marketplace) is your top performer",
                message: String(format: "$%.2f revenue from %d sales", bestMarketplace.totalRevenue, bestMarketplace.count),
                icon: "star.fill",
                color: .yellow
            ))
        }

        // Stale listings
        let staleListings = itemStorage.listedItems.filter { item in
            guard let dateListed = item.listingStatus.dateListed else { return false }
            let days = Calendar.current.dateComponents([.day], from: dateListed, to: Date()).day ?? 0
            return days > 30
        }

        if !staleListings.isEmpty {
            insights.append(Insight(
                title: "\(staleListings.count) listing\(staleListings.count == 1 ? "" : "s") over 30 days old",
                message: "Consider repricing or relisting these items",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            ))
        }

        // Profit margin insight
        if itemStorage.soldItems.count > 0 && itemStorage.totalRevenue > 0 {
            let margin = (itemStorage.totalProfit / itemStorage.totalRevenue) * 100
            if margin >= 30 {
                insights.append(Insight(
                    title: "Great profit margins!",
                    message: String(format: "You're averaging %.1f%% profit - keep it up!", margin),
                    icon: "checkmark.circle.fill",
                    color: .green
                ))
            } else if margin < 15 {
                insights.append(Insight(
                    title: "Low profit margins",
                    message: String(format: "Your %.1f%% margin could be improved with better sourcing", margin),
                    icon: "chart.line.downtrend.xyaxis",
                    color: .red
                ))
            }
        }

        // Inventory turnover
        if itemStorage.listedItems.count > itemStorage.soldItems.count * 2 {
            insights.append(Insight(
                title: "High inventory levels",
                message: "You have more listings than sales - focus on selling existing inventory",
                icon: "shippingbox.fill",
                color: .blue
            ))
        }

        return insights
    }
}

// MARK: - Data Models

struct MarketplaceStat {
    let marketplace: String
    let count: Int
    let totalRevenue: Double
    let avgProfit: Double
    let percentage: Double
}

struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let revenue: Double
}

struct CategoryStat {
    let category: String
    let count: Int
}

struct Insight {
    let title: String
    let message: String
    let icon: String
    let color: Color
}
