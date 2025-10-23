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
                salesMomentumSection
                performanceInsightsSection
                inventoryHealthSection
                inventoryVelocitySection
                revenueAndProfitChartSection
                timeToSellSection
                roiAndProfitabilitySection
                marketplaceBreakdownSection
                categoryBreakdownSection
                actionableInsightsSection
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
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
    var salesMomentumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Sales Momentum", icon: "arrow.up.right.circle.fill")

            VStack(spacing: 12) {
                if let momentum = salesMomentumData {
                    momentumCard(
                        label: "Month-over-Month Growth",
                        value: momentum.momGrowth,
                        trend: momentum.growthTrend,
                        icon: "chart.line.uptrend.xyaxis"
                    )

                    momentumCard(
                        label: "Current Month Projection",
                        value: momentum.projectedRevenue,
                        trend: .stable,
                        icon: "calendar.circle.fill"
                    )

                    momentumCard(
                        label: "Sales Velocity",
                        value: momentum.salesVelocity,
                        trend: momentum.velocityTrend,
                        icon: "speedometer"
                    )
                } else {
                    emptyStateCard(message: "Need more sales history for momentum analysis")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
        }
    }

    @ViewBuilder
    func momentumCard(label: String, value: String, trend: TrendDirection, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(trend.color)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            HStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(trend.color)

                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
        }
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

                performanceMetric(
                    label: "Listing Efficiency",
                    value: listingEfficiencyText,
                    color: .purple,
                    icon: "checkmark.circle.fill"
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
    var revenueAndProfitChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Revenue & Profit Trends", icon: "chart.xyaxis.line")

            if !itemStorage.soldItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Chart {
                        ForEach(revenueByMonth) { dataPoint in
                            LineMark(
                                x: .value("Month", dataPoint.month),
                                y: .value("Amount", dataPoint.revenue)
                            )
                            .foregroundStyle(Color.green)
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())

                            AreaMark(
                                x: .value("Month", dataPoint.month),
                                y: .value("Amount", dataPoint.revenue)
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

                        ForEach(profitByMonth) { dataPoint in
                            LineMark(
                                x: .value("Month", dataPoint.month),
                                y: .value("Amount", dataPoint.profit)
                            )
                            .foregroundStyle(Color.blue)
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                        }
                    }
                    .frame(height: 220)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }

                    HStack(spacing: 20) {
                        chartLegendItem(color: .green, label: "Revenue")
                        chartLegendItem(color: .blue, label: "Profit")
                    }
                    .padding(.top, 8)
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
    func chartLegendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    var timeToSellSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Time to Sell Analysis", icon: "clock.fill")

            if !itemStorage.soldItems.isEmpty {
                VStack(spacing: 12) {
                    if let avgDays = averageDaysToSell {
                        performanceMetric(
                            label: "Average Days to Sell",
                            value: "\(avgDays) days",
                            color: avgDays < 14 ? .green : avgDays < 30 ? .orange : .red,
                            icon: "clock.badge.checkmark"
                        )
                    }

                    if let fastestCategory = fastestSellingCategory {
                        performanceMetric(
                            label: "Fastest Selling Category",
                            value: "\(fastestCategory.category) (\(fastestCategory.avgDays)d)",
                            color: .green,
                            icon: "hare.fill"
                        )
                    }

                    if let slowestCategory = slowestSellingCategory {
                        performanceMetric(
                            label: "Slowest Selling Category",
                            value: "\(slowestCategory.category) (\(slowestCategory.avgDays)d)",
                            color: .orange,
                            icon: "tortoise.fill"
                        )
                    }

                    if let avgTimeToList = averageDaysToList {
                        performanceMetric(
                            label: "Avg Time to List After Scan",
                            value: "\(avgTimeToList) days",
                            color: avgTimeToList < 3 ? .green : avgTimeToList < 7 ? .orange : .red,
                            icon: "calendar.badge.clock"
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                )
            } else {
                emptyStateCard(message: "No sales data for time analysis")
            }
        }
    }

    @ViewBuilder
    var roiAndProfitabilitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "ROI & Profitability by Category", icon: "chart.pie.fill")

            if !categoryROIStats.isEmpty {
                VStack(spacing: 8) {
                    ForEach(categoryROIStats.prefix(5), id: \.category) { stat in
                        categoryROIRow(stat: stat)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                )
            } else {
                emptyStateCard(message: "Need cost basis data for ROI analysis")
            }
        }
    }

    @ViewBuilder
    func categoryROIRow(stat: CategoryROIStat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stat.category)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(stat.soldCount) sold")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg ROI")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", stat.avgROI))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(stat.avgROI >= 50 ? .green : stat.avgROI >= 25 ? .orange : .red)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg Margin")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", stat.avgMargin))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(stat.avgMargin >= 30 ? .green : .orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Profit")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.0f", stat.totalProfit))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                Spacer()
            }
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    var inventoryHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Inventory Health", icon: "shippingbox.fill")

            if itemStorage.unsoldItems.isEmpty {
                emptyStateCard(message: "No items in inventory")
            } else {
                VStack(spacing: 12) {
                    // Fresh / Active / Stale breakdown
                    HStack(spacing: 12) {
                        healthCard(
                            title: "Fresh",
                            subtitle: "0-7 days",
                            count: itemStorage.freshItems.count,
                            color: .green,
                            icon: "leaf.fill"
                        )
                        healthCard(
                            title: "Active",
                            subtitle: "8-30 days",
                            count: itemStorage.activeItems.count,
                            color: .orange,
                            icon: "clock.fill"
                        )
                        healthCard(
                            title: "Stale",
                            subtitle: "30+ days",
                            count: itemStorage.staleItems.count,
                            color: .red,
                            icon: "exclamationmark.triangle.fill"
                        )
                    }

                    // Total value tied up
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Value Tied Up")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(itemStorage.formattedTotalInventoryValue)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Items in Inventory")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(itemStorage.unsoldItems.count)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                )
            }
        }
    }

    @ViewBuilder
    var inventoryVelocitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Inventory Velocity", icon: "speedometer")

            if itemStorage.soldItems.isEmpty {
                emptyStateCard(message: "No sales data yet")
            } else {
                VStack(spacing: 12) {
                    // Cycle time metrics
                    if let avgToList = itemStorage.averageDaysToList {
                        velocityMetric(
                            label: "Avg Days to List",
                            value: String(format: "%.0f days", avgToList),
                            icon: "clock.arrow.circlepath",
                            color: avgToList <= 7 ? .green : avgToList <= 14 ? .orange : .red
                        )
                    }

                    if let avgToSell = itemStorage.averageDaysToSell {
                        velocityMetric(
                            label: "Avg Days to Sell",
                            value: String(format: "%.0f days", avgToSell),
                            icon: "tag.fill",
                            color: avgToSell <= 14 ? .green : avgToSell <= 30 ? .orange : .red
                        )
                    }

                    if let avgCycle = itemStorage.averageCycleTime {
                        velocityMetric(
                            label: "Total Cycle Time",
                            value: String(format: "%.0f days", avgCycle),
                            icon: "arrow.triangle.2.circlepath",
                            color: avgCycle <= 30 ? .green : avgCycle <= 60 ? .orange : .red
                        )
                    }

                    // Fastest / Slowest flips
                    if !itemStorage.fastestFlips.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Fastest Flips")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)

                            ForEach(itemStorage.fastestFlips.prefix(3)) { item in
                                flipRow(item: item, isFast: true)
                            }
                        }
                    }

                    if !itemStorage.slowestFlips.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Slowest Flips")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)

                            ForEach(itemStorage.slowestFlips.prefix(3)) { item in
                                flipRow(item: item, isFast: false)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                )
            }
        }
    }

    @ViewBuilder
    func healthCard(title: String, subtitle: String, count: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }

    @ViewBuilder
    func velocityMetric(label: String, value: String, icon: String, color: Color) -> some View {
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
    func flipRow(item: ScannedItem, isFast: Bool) -> some View {
        HStack(spacing: 8) {
            Text(item.itemName)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            if let dateSold = item.listingStatus.dateSold {
                let days = Calendar.current.dateComponents([.day], from: item.timestamp, to: dateSold).day ?? 0
                Text("\(days) days")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isFast ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
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
}

// MARK: - Computed Properties
private extension AnalyticsView {
    var conversionRateText: String {
        let totalItems = itemStorage.totalItemCount
        let soldItems = itemStorage.soldItems.count

        if totalItems == 0 { return "0%" }
        let rate = (Double(soldItems) / Double(totalItems)) * 100
        return String(format: "%.1f%%", rate)
    }

    var listingEfficiencyText: String {
        let totalScanned = itemStorage.scannedItems.count
        let totalListed = itemStorage.listedItems.count + itemStorage.soldItems.count

        if totalScanned == 0 { return "0%" }
        let rate = (Double(totalListed) / Double(totalScanned)) * 100
        return String(format: "%.1f%%", rate)
    }

    var salesMomentumData: SalesMomentum? {
        let soldItems = itemStorage.soldItems
        guard soldItems.count >= 2 else { return nil }

        let calendar = Calendar.current
        let now = Date()

        // Get current and previous month sales
        let currentMonthSales = soldItems.filter { item in
            guard let dateSold = item.listingStatus.dateSold else { return false }
            return calendar.isDate(dateSold, equalTo: now, toGranularity: .month)
        }

        let previousMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let previousMonthSales = soldItems.filter { item in
            guard let dateSold = item.listingStatus.dateSold else { return false }
            return calendar.isDate(dateSold, equalTo: previousMonth, toGranularity: .month)
        }

        // Calculate MoM growth
        let currentRevenue = currentMonthSales.compactMap { $0.listingStatus.soldPrice }.reduce(0, +)
        let previousRevenue = previousMonthSales.compactMap { $0.listingStatus.soldPrice }.reduce(0, +)

        let momGrowthRate: Double
        let growthTrend: TrendDirection
        if previousRevenue > 0 {
            momGrowthRate = ((currentRevenue - previousRevenue) / previousRevenue) * 100
            if momGrowthRate > 10 {
                growthTrend = .up
            } else if momGrowthRate < -10 {
                growthTrend = .down
            } else {
                growthTrend = .stable
            }
        } else {
            momGrowthRate = 0
            growthTrend = .stable
        }

        // Project current month
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let currentDay = calendar.component(.day, from: now)
        let projectedMonthRevenue = currentRevenue * (Double(daysInMonth) / Double(currentDay))

        // Sales velocity (items per week)
        let last30Days = calendar.date(byAdding: .day, value: -30, to: now)!
        let recentSales = soldItems.filter { item in
            guard let dateSold = item.listingStatus.dateSold else { return false }
            return dateSold >= last30Days
        }
        let salesPerWeek = Double(recentSales.count) / 4.3

        let velocityTrend: TrendDirection
        if salesPerWeek > 5 {
            velocityTrend = .up
        } else if salesPerWeek < 2 {
            velocityTrend = .down
        } else {
            velocityTrend = .stable
        }

        return SalesMomentum(
            momGrowth: String(format: "%+.1f%%", momGrowthRate),
            growthTrend: growthTrend,
            projectedRevenue: String(format: "$%.2f", projectedMonthRevenue),
            salesVelocity: String(format: "%.1f/week", salesPerWeek),
            velocityTrend: velocityTrend
        )
    }

    var averageDaysToSell: Int? {
        let soldItems = itemStorage.soldItems.filter { item in
            item.listingStatus.dateListed != nil && item.listingStatus.dateSold != nil
        }

        guard !soldItems.isEmpty else { return nil }

        let totalDays = soldItems.compactMap { item -> Int? in
            guard let listed = item.listingStatus.dateListed,
                  let sold = item.listingStatus.dateSold else { return nil }
            return Calendar.current.dateComponents([.day], from: listed, to: sold).day
        }.reduce(0, +)

        return totalDays / soldItems.count
    }

    var averageDaysToList: Int? {
        let listedItems = itemStorage.listedItems + itemStorage.soldItems
        let itemsWithBothDates = listedItems.filter { item in
            item.listingStatus.dateListed != nil
        }

        guard !itemsWithBothDates.isEmpty else { return nil }

        let totalDays = itemsWithBothDates.compactMap { item -> Int? in
            guard let listed = item.listingStatus.dateListed else { return nil }
            let scanned = item.timestamp
            return Calendar.current.dateComponents([.day], from: scanned, to: listed).day
        }.reduce(0, +)

        return totalDays / itemsWithBothDates.count
    }

    var fastestSellingCategory: (category: String, avgDays: Int)? {
        let soldItems = itemStorage.soldItems.filter { item in
            item.listingStatus.dateListed != nil && item.listingStatus.dateSold != nil
        }

        let grouped = Dictionary(grouping: soldItems) { $0.categoryName ?? "Unknown" }

        let categoryAvgs = grouped.compactMap { category, items -> (String, Int)? in
            let days = items.compactMap { item -> Int? in
                guard let listed = item.listingStatus.dateListed,
                      let sold = item.listingStatus.dateSold else { return nil }
                return Calendar.current.dateComponents([.day], from: listed, to: sold).day
            }
            guard !days.isEmpty else { return nil }
            let avg = days.reduce(0, +) / days.count
            return (category, avg)
        }

        return categoryAvgs.min(by: { $0.1 < $1.1 })
    }

    var slowestSellingCategory: (category: String, avgDays: Int)? {
        let soldItems = itemStorage.soldItems.filter { item in
            item.listingStatus.dateListed != nil && item.listingStatus.dateSold != nil
        }

        let grouped = Dictionary(grouping: soldItems) { $0.categoryName ?? "Unknown" }

        let categoryAvgs = grouped.compactMap { category, items -> (String, Int)? in
            let days = items.compactMap { item -> Int? in
                guard let listed = item.listingStatus.dateListed,
                      let sold = item.listingStatus.dateSold else { return nil }
                return Calendar.current.dateComponents([.day], from: listed, to: sold).day
            }
            guard !days.isEmpty else { return nil }
            let avg = days.reduce(0, +) / days.count
            return (category, avg)
        }

        return categoryAvgs.max(by: { $0.1 < $1.1 })
    }

    var categoryROIStats: [CategoryROIStat] {
        let soldItems = itemStorage.soldItems.filter { item in
            item.listingStatus.soldPrice != nil && item.listingStatus.costBasis != nil
        }

        guard !soldItems.isEmpty else { return [] }

        let grouped = Dictionary(grouping: soldItems) { $0.categoryName ?? "Unknown" }

        return grouped.compactMap { category, items -> CategoryROIStat? in
            let rois = items.compactMap { item -> Double? in
                guard let soldPrice = item.listingStatus.soldPrice,
                      let costBasis = item.listingStatus.costBasis,
                      costBasis > 0 else { return nil }
                return ((soldPrice - costBasis) / costBasis) * 100
            }

            let margins = items.compactMap { item -> Double? in
                guard let soldPrice = item.listingStatus.soldPrice,
                      let profit = item.listingStatus.netProfit,
                      soldPrice > 0 else { return nil }
                return (profit / soldPrice) * 100
            }

            let totalProfit = items.compactMap { $0.listingStatus.netProfit }.reduce(0, +)

            guard !rois.isEmpty, !margins.isEmpty else { return nil }

            return CategoryROIStat(
                category: category,
                soldCount: items.count,
                avgROI: rois.reduce(0, +) / Double(rois.count),
                avgMargin: margins.reduce(0, +) / Double(margins.count),
                totalProfit: totalProfit
            )
        }
        .sorted { $0.avgROI > $1.avgROI }
    }

    var averageInventoryAge: String {
        let unsoldItems = itemStorage.scannedItems.filter { item in
            item.listingStatus.status != .sold
        }

        guard !unsoldItems.isEmpty else { return "N/A" }

        let totalDays = unsoldItems.compactMap { item -> Int? in
            let timestamp = item.timestamp
            return Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day
        }.reduce(0, +)

        let avgDays = totalDays / unsoldItems.count
        return "\(avgDays) days"
    }

    var inventoryTurnoverRate: Double? {
        guard let avgDaysToSell = averageDaysToSell,
              avgDaysToSell > 0 else { return nil }
        return Double(avgDaysToSell)
    }

    var deadStockCount: Int {
        let now = Date()
        return itemStorage.listedItems.filter { item in
            guard let dateListed = item.listingStatus.dateListed else { return false }
            let days = Calendar.current.dateComponents([.day], from: dateListed, to: now).day ?? 0
            return days > 90
        }.count
    }

    var totalInventoryValue: String {
        let activeItems = itemStorage.listedItems + itemStorage.readyToListItems
        let totalValue = activeItems.compactMap { item -> Double? in
            if let costBasis = item.listingStatus.costBasis {
                return costBasis
            } else if let userCost = item.userCostBasis {
                return userCost
            }
            return nil
        }.reduce(0, +)

        return String(format: "$%.2f", totalValue)
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

    var profitByMonth: [ProfitDataPoint] {
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
            let profit = items.compactMap { $0.listingStatus.netProfit }.reduce(0, +)
            return ProfitDataPoint(month: monthKey, profit: profit)
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

        // Best ROI category
        if let bestROICategory = categoryROIStats.first {
            insights.append(Insight(
                title: "\(bestROICategory.category) has best ROI",
                message: String(format: "%.0f%% average ROI - consider sourcing more!", bestROICategory.avgROI),
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                color: .green
            ))
        }

        // Fast selling insight
        if let fastest = fastestSellingCategory, fastest.avgDays < 14 {
            insights.append(Insight(
                title: "\(fastest.category) sells quickly",
                message: "Average \(fastest.avgDays) days to sell - great category to focus on",
                icon: "bolt.fill",
                color: .green
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

        // Dead stock alert
        if deadStockCount > 0 {
            insights.append(Insight(
                title: "\(deadStockCount) dead stock items (>90 days)",
                message: "Consider aggressive repricing or bundling these items",
                icon: "exclamationmark.octagon.fill",
                color: .red
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

        // Time to list insight
        if let avgDaysToList = averageDaysToList, avgDaysToList > 7 {
            insights.append(Insight(
                title: "Slow listing process",
                message: "Items take \(avgDaysToList) days to list after scanning - try to list faster",
                icon: "timer",
                color: .orange
            ))
        }

        // Sales momentum
        if let momentum = salesMomentumData {
            if momentum.growthTrend == .up {
                insights.append(Insight(
                    title: "Sales momentum is strong!",
                    message: "Revenue is growing month-over-month - you're on the right track",
                    icon: "arrow.up.right.circle.fill",
                    color: .green
                ))
            } else if momentum.growthTrend == .down {
                insights.append(Insight(
                    title: "Sales momentum declining",
                    message: "Revenue is down from last month - consider listing more items",
                    icon: "arrow.down.right.circle.fill",
                    color: .red
                ))
            }
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

struct ProfitDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let profit: Double
}

struct CategoryStat {
    let category: String
    let count: Int
}

struct CategoryROIStat {
    let category: String
    let soldCount: Int
    let avgROI: Double
    let avgMargin: Double
    let totalProfit: Double
}

struct SalesMomentum {
    let momGrowth: String
    let growthTrend: TrendDirection
    let projectedRevenue: String
    let salesVelocity: String
    let velocityTrend: TrendDirection
}

enum TrendDirection {
    case up, down, stable

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .orange
        }
    }
}

struct Insight {
    let title: String
    let message: String
    let icon: String
    let color: Color
}
