//
//  Enhanced HomeView with Real-Time AI Intelligence
//  QuickFlip
//

import SwiftUI

struct EnhancedHomeView: View {
    @EnvironmentObject var itemStorage: ItemStorageService
    @StateObject private var marketIntelligence = MarketIntelligenceService()
    @StateObject private var personalAnalytics = PersonalAnalyticsService()

    @State private var userName = UserDefaults.standard.string(forKey: "userName") ?? "Flipper"
    @State private var showingFullInsights = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header with Real Data
                    welcomeHeaderView

                    // Real Performance Stats
                    realPerformanceStatsView

                    // Market Insights Section (Original Design)
                    marketInsightsSectionView

                    // Personal AI Insights
                    if !itemStorage.scannedItems.isEmpty {
                        personalInsightsView
                    }

                    // Smart Quick Actions
                    smartQuickActionsView

                    // Recent Activity with Real Data
                    if !itemStorage.scannedItems.isEmpty {
                        recentActivityView
                    } else {
                        getStartedView
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .refreshable {
                await refreshAllData()
            }
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
        .sheet(isPresented: $showingFullInsights) {
            FullMarketInsightsView(
                trends: marketIntelligence.dailyTrends,
                personalInsights: personalAnalytics.insights,
                isLoadingTrends: marketIntelligence.isLoadingTrends,
                isLoadingPersonal: personalAnalytics.isLoadingInsights,
                onRefresh: {
                    Task {
                        await refreshAllData()
                    }
                }
            )
        }
    }

    // MARK: - View Components

    private var welcomeHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.title2)
                        .foregroundColor(.gray)

                    Text(userName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Spacer()

                // AI Status Indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(marketIntelligence.dailyTrends != nil ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)

                    Text("AI")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }

            Text(getPersonalizedGreeting())
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    private var realPerformanceStatsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                RealStatsCard(
                    title: "Items Scanned",
                    value: "\(itemStorage.userStats.totalItemsScanned)",
                    subtitle: "All time",
                    icon: "camera.fill",
                    color: .blue,
                    trend: getTrendForScanning()
                )

                RealStatsCard(
                    title: "Potential Profit",
                    value: "$\(String(format: "%.0f", calculateTotalPotentialProfit()))",
                    subtitle: "Smart choices",
                    icon: "dollarsign.circle.fill",
                    color: .green,
                    trend: .up
                )
            }

            RealStatsCard(
                title: "Best Marketplace",
                value: itemStorage.userStats.favoriteMarketplace,
                subtitle: "Most recommended",
                icon: "crown.fill",
                color: .orange,
                isWide: true,
                trend: .neutral
            )
        }
    }

    private var aiLoadingView: some View {
        VStack(spacing: 12) {
            HStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.8)

                Text("AI Market Analysis Loading...")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()
            }

            Text("Analyzing real-time market trends for you")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Market Insights Section (Original Design)

    private var marketInsightsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Market Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("See All") {
                    showingFullInsights = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // First card - Trending category or loading
                    if marketIntelligence.isLoadingTrends {
                        LoadingInsightCard()
                    } else if let trends = marketIntelligence.dailyTrends,
                              let hotCategory = trends.hotCategories.first {
                        TrendingInsightCard(
                            title: "Trending Up",
                            subtitle: hotCategory.name,
                            change: hotCategory.formattedChange,
                            icon: "arrow.up.circle.fill",
                            color: .green
                        )
                    } else {
                        NoDataInsightCard(
                            title: "Market Trends",
                            subtitle: "Tap 'See All' to load",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .blue
                        )
                    }

                    // Second card - Personal insight or market sentiment
                    if let insights = personalAnalytics.insights {
                        PersonalInsightCard(
                            title: "Your Strength",
                            subtitle: insights.strongestCategory,
                            change: "Top category",
                            icon: "person.crop.circle.fill.badge.checkmark",
                            color: .purple
                        )
                    } else if let trends = marketIntelligence.dailyTrends {
                        MarketSentimentCard(
                            title: "Market Mood",
                            subtitle: trends.marketSentiment.rawValue.capitalized,
                            change: trends.marketSentiment.emoji,
                            icon: "brain.head.profile",
                            color: trends.marketSentiment.color
                        )
                    } else {
                        NoDataInsightCard(
                            title: "Personal Stats",
                            subtitle: "Analyze your data",
                            icon: "person.crop.circle.badge.checkmark",
                            color: .purple
                        )
                    }

                    // Third card - Best timing or seasonal opportunity
                    if let trends = marketIntelligence.dailyTrends {
                        if !trends.seasonalOpportunity.isEmpty {
                            SeasonalInsightCard(
                                title: "Seasonal Pick",
                                subtitle: trends.seasonalOpportunity.prefix(20) + "...",
                                change: "Hot now",
                                icon: "calendar.circle.fill",
                                color: .orange
                            )
                        } else {
                            TimingInsightCard(
                                title: "Best Time",
                                subtitle: trends.bestListingTime,
                                change: "Optimal timing",
                                icon: "clock.fill",
                                color: .blue
                            )
                        }
                    } else {
                        NoDataInsightCard(
                            title: "AI Insights",
                            subtitle: "Loading smart tips",
                            icon: "lightbulb.fill",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func marketIntelligenceView(trends: MarketTrends) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("AI MARKET INTELLIGENCE")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(trends.marketSentiment.emoji)
                    Text(trends.marketSentiment.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(trends.marketSentiment.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(trends.marketSentiment.color.opacity(0.1))
                .cornerRadius(8)
            }

            // Top Insight
            InsightCard(
                title: "💡 TODAY'S TOP INSIGHT",
                content: trends.topInsight,
                color: .blue
            )

            // Hot Categories
            VStack(alignment: .leading, spacing: 8) {
                Text("🔥 TRENDING UP")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                ForEach(trends.hotCategories.prefix(3), id: \.name) { category in
                    TrendingCategoryRow(category: category)
                }
            }

            // Seasonal Opportunity
            if !trends.seasonalOpportunity.isEmpty {
                InsightCard(
                    title: "🌟 SEASONAL OPPORTUNITY",
                    content: trends.seasonalOpportunity,
                    color: .orange
                )
            }

            // Best Listing Time
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.purple)
                Text("Best listing time: \(trends.bestListingTime)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
    }

    private var personalInsightsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .foregroundColor(.green)
                Text("YOUR PERFORMANCE")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button("Details") {
                    showingFullInsights = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            if personalAnalytics.isLoadingInsights {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        .scaleEffect(0.7)
                    Text("Analyzing your patterns...")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else if let insights = personalAnalytics.insights {
                VStack(spacing: 8) {
                    PersonalInsightRow(
                        title: "Strongest Category",
                        value: insights.strongestCategory,
                        color: .blue
                    )

                    PersonalInsightRow(
                        title: "Success Rate",
                        value: insights.successRate.percentage,
                        color: insights.successRate.color
                    )

                    PersonalInsightRow(
                        title: "Skill Level",
                        value: insights.skillLevel.displayText,
                        color: insights.skillLevel.color
                    )
                }

                // Next Recommendation
                if !insights.nextRecommendation.isEmpty {
                    InsightCard(
                        title: "🎯 NEXT RECOMMENDATION",
                        content: insights.nextRecommendation,
                        color: .green
                    )
                }
            } else {
                Button(action: {
                    Task {
                        await personalAnalytics.analyzeUserData(itemStorage.scannedItems)
                    }
                }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                        Text("Analyze My Performance")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }

    private var smartQuickActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart Actions")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                SmartQuickActionCard(
                    title: "Scan New Item",
                    subtitle: getSmartScanSubtitle(),
                    icon: "camera.fill",
                    color: .blue,
                    isRecommended: true
                ) {
                    // Navigate to camera
                }

                SmartQuickActionCard(
                    title: "Check Price Updates",
                    subtitle: "See if your items' values changed",
                    icon: "arrow.clockwise.circle.fill",
                    color: .orange,
                    isRecommended: hasItemsToUpdate()
                ) {
                    Task {
                        await checkPriceUpdates()
                    }
                }

                SmartQuickActionCard(
                    title: "Optimize Listings",
                    subtitle: "AI suggestions for better profits",
                    icon: "wand.and.stars",
                    color: .purple,
                    isRecommended: itemStorage.scannedItems.count > 3
                ) {
                    // Navigate to optimization view
                }
            }
        }
    }

    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Scans")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink("View All") {
                    // Navigate to history view
                    Text("History View")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            LazyVStack(spacing: 12) {
                ForEach(itemStorage.getRecentItems(limit: 5)) { item in
                    EnhancedRecentItemCard(item: item)
                }
            }
        }
    }

    private var getStartedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Start Your Flipping Journey")
                .font(.title2)
                .fontWeight(.bold)

            Text("Scan your first item to see powerful AI insights")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button(action: {
                // Navigate to camera
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Take Your First Photo")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Helper Methods

    private func loadInitialData() async {
        await marketIntelligence.loadDailyTrends()

        if !itemStorage.scannedItems.isEmpty {
            await personalAnalytics.analyzeUserData(itemStorage.scannedItems)
        }
    }

    private func refreshAllData() async {
        await marketIntelligence.loadDailyTrends()
        await personalAnalytics.analyzeUserData(itemStorage.scannedItems)
    }

    private func getPersonalizedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let itemCount = itemStorage.scannedItems.count

        if itemCount == 0 {
            return "Ready to find your first profitable flip?"
        } else if itemCount < 5 {
            return "Great start! Let's find more profitable items."
        } else {
            let timeGreeting = hour < 12 ? "morning" : (hour < 17 ? "afternoon" : "evening")
            return "Good \(timeGreeting)! Ready for more profitable finds?"
        }
    }

    private func getTrendForScanning() -> StatsTrend {
        let recentScans = itemStorage.scannedItems.filter {
            $0.daysSinceScanned <= 7
        }.count
        let previousWeekScans = itemStorage.scannedItems.filter {
            $0.daysSinceScanned > 7 && $0.daysSinceScanned <= 14
        }.count

        if recentScans > previousWeekScans {
            return .up
        } else if recentScans < previousWeekScans {
            return .down
        } else {
            return .neutral
        }
    }

    private func calculateTotalPotentialProfit() -> Double {
        return itemStorage.scannedItems.reduce(0) { total, item in
            if let profitBreakdowns = item.profitBreakdowns,
               let bestProfit = profitBreakdowns.max(by: { $0.netProfit < $1.netProfit }) {
                return total + bestProfit.netProfit
            }
            return total
        }
    }

    private func getSmartScanSubtitle() -> String {
        if let trends = marketIntelligence.dailyTrends,
           let hotCategory = trends.hotCategories.first {
            return "Try \(hotCategory.name) - trending \(hotCategory.formattedChange)"
        }
        return "AI will identify profitable items"
    }

    private func hasItemsToUpdate() -> Bool {
        return itemStorage.scannedItems.contains { $0.daysSinceScanned >= 7 }
    }

    private func checkPriceUpdates() async {
        // Implementation for checking price updates
        print("Checking price updates for items...")
    }
}

// MARK: - Supporting Views

struct RealStatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var isWide: Bool = false
    var trend: StatsTrend = .neutral

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()

                if trend != .neutral {
                    Image(systemName: trend == .up ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(trend == .up ? .green : .red)
                        .font(.caption)
                }
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

enum StatsTrend {
    case up, down, neutral
}

struct TrendingCategoryRow: View {
    let category: TrendingCategory

    var body: some View {
        HStack {
            Text(category.name)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Text(category.formattedChange)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(category.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(category.color.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 2)
    }
}

//struct InsightCard: View {
//    let title: String
//    let content: String
//    let color: Color
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title)
//                .font(.caption)
//                .fontWeight(.bold)
//                .foregroundColor(color)
//
//            Text(content)
//                .font(.subheadline)
//                .foregroundColor(.primary)
//        }
//        .padding()
//        .background(color.opacity(0.1))
//        .cornerRadius(8)
//    }
//}

struct PersonalInsightRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct SmartQuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)

                    if isRecommended {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                            .offset(x: 18, y: -18)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedRecentItemCard: View {
    let item: ScannedItem

    var body: some View {
        HStack {
            // Item image or placeholder
            Group {
                if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("Best on \(item.priceAnalysis.recommendedMarketplace)")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text(item.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.estimatedValue)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                if let profitBreakdowns = item.profitBreakdowns,
                   let bestProfit = profitBreakdowns.max(by: { $0.netProfit < $1.netProfit }) {
                    Text("Profit: \(bestProfit.formattedNetProfit)")
                        .font(.caption)
                        .foregroundColor(bestProfit.profitColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct PersonalInsightsDetailView: View {
    let insights: PersonalInsights?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                if let insights = insights {
                    VStack(alignment: .leading, spacing: 20) {
                        // Performance Overview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Performance Overview")
                                .font(.title2)
                                .fontWeight(.bold)

                            VStack(spacing: 8) {
                                DetailInsightRow(title: "Total Items Analyzed", value: "\(insights.totalItemsAnalyzed)")
                                DetailInsightRow(title: "Average Daily Value", value: "$\(String(format: "%.2f", insights.averageDailyValue))")
                                DetailInsightRow(title: "Success Rate", value: insights.successRate.percentage)
                                DetailInsightRow(title: "Skill Level", value: insights.skillLevel.displayText)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)

                        // Recommendations
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI Recommendations")
                                .font(.title2)
                                .fontWeight(.bold)

                            InsightCard(title: "NEXT STEPS", content: insights.nextRecommendation, color: .blue)
                            InsightCard(title: "FOCUS AREA", content: insights.focusArea, color: .green)
                            InsightCard(title: "PROFIT OPPORTUNITY", content: insights.profitOpportunity, color: .orange)
                        }

                        Spacer()
                    }
                    .padding()
                } else {
                    Text("No insights available")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationTitle("Personal Insights")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Market Insight Cards (Original Style)

struct TrendingInsightCard: View {
    let title: String
    let subtitle: String
    let change: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(subtitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Text(change)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct PersonalInsightCard: View {
    let title: String
    let subtitle: String
    let change: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(subtitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Text(change)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct MarketSentimentCard: View {
    let title: String
    let subtitle: String
    let change: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(change)
                    .font(.title2)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(subtitle)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Market analysis")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct SeasonalInsightCard: View {
    let title: String
    let subtitle: String
    let change: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(subtitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Text(change)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct TimingInsightCard: View {
    let title: String
    let subtitle: String
    let change: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(subtitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Text(change)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct LoadingInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(0.8)

            Text("Loading")
                .font(.caption)
                .foregroundColor(.gray)

            Text("AI Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Please wait...")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct NoDataInsightCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color.opacity(0.6))
                .font(.title2)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(subtitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .lineLimit(2)

            Text("Tap See All")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Full Market Insights View

struct FullMarketInsightsView: View {
    let trends: MarketTrends?
    let personalInsights: PersonalInsights?
    let isLoadingTrends: Bool
    let isLoadingPersonal: Bool
    let onRefresh: () -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Market Intelligence Section
                    if isLoadingTrends {
                        aiLoadingSection
                    } else if let trends = trends {
                        marketTrendsSection(trends: trends)
                    } else {
                        noMarketDataSection
                    }

                    // Personal Analytics Section
                    if isLoadingPersonal {
                        personalLoadingSection
                    } else if let insights = personalInsights {
                        personalAnalyticsSection(insights: insights)
                    } else {
                        noPersonalDataSection
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Market Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Refresh") {
                    onRefresh()
                }
            )
        }
    }

    private var aiLoadingSection: some View {
        VStack(spacing: 16) {
            HStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                Text("AI Market Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            Text("Analyzing real-time market trends, hot categories, and seasonal opportunities...")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }

    private func marketTrendsSection(trends: MarketTrends) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with sentiment
            HStack {
                VStack(alignment: .leading) {
                    Text("Market Intelligence")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("AI-powered insights")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(trends.marketSentiment.emoji)
                    Text(trends.marketSentiment.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(trends.marketSentiment.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(trends.marketSentiment.color.opacity(0.1))
                .cornerRadius(8)
            }

            // Top insight
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 KEY INSIGHT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text(trends.topInsight)
                    .font(.subheadline)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }

            // Hot categories
            VStack(alignment: .leading, spacing: 12) {
                Text("🔥 TRENDING CATEGORIES")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                ForEach(trends.hotCategories, id: \.name) { category in
                    DetailedTrendingRow(category: category)
                }
            }

            // Cooling categories
            if !trends.coolingCategories.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("❄️ COOLING CATEGORIES")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)

                    ForEach(trends.coolingCategories, id: \.name) { category in
                        DetailedTrendingRow(category: category)
                    }
                }
            }

            // Seasonal opportunity
            if !trends.seasonalOpportunity.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🌟 SEASONAL OPPORTUNITY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Text(trends.seasonalOpportunity)
                        .font(.subheadline)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Best listing time
            VStack(alignment: .leading, spacing: 8) {
                Text("⏰ OPTIMAL TIMING")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)

                Text("Best time to list: \(trends.bestListingTime)")
                    .font(.subheadline)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var noMarketDataSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 50))
                .foregroundColor(.purple.opacity(0.6))

            Text("Market Intelligence Unavailable")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Tap refresh to load AI-powered market insights")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(16)
    }

    private var personalLoadingSection: some View {
        VStack(spacing: 16) {
            HStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                Text("Personal Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            Text("Analyzing your scanning patterns and performance...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    private func personalAnalyticsSection(insights: PersonalInsights) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Personal Analytics")
                .font(.title2)
                .fontWeight(.bold)

            // Performance metrics
            VStack(spacing: 12) {
                DetailInsightRow(title: "Items Scanned", value: "\(insights.totalItemsAnalyzed)")
                DetailInsightRow(title: "Success Rate", value: insights.successRate.percentage)
                DetailInsightRow(title: "Skill Level", value: insights.skillLevel.displayText)
                DetailInsightRow(title: "Strongest Category", value: insights.strongestCategory)
                DetailInsightRow(title: "Best Marketplace", value: insights.mostProfitableMarketplace)
                DetailInsightRow(title: "Avg Daily Value", value: "$\(String(format: "%.2f", insights.averageDailyValue))")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            // Recommendations
            VStack(alignment: .leading, spacing: 12) {
                Text("🎯 AI RECOMMENDATIONS")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                RecommendationCard(title: "Next Steps", content: insights.nextRecommendation, color: .blue)
                RecommendationCard(title: "Focus Area", content: insights.focusArea, color: .green)
                RecommendationCard(title: "Profit Opportunity", content: insights.profitOpportunity, color: .orange)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var noPersonalDataSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))

            Text("No Personal Data")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Scan some items to see personalized insights")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
}

struct DetailedTrendingRow: View {
    let category: TrendingCategory

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(category.reason)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(category.formattedChange)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(category.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(category.color.opacity(0.1))
                .cornerRadius(6)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct DetailInsightRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct RecommendationCard: View {
    let title: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(content)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
