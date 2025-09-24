//
//  Enhanced HomeView with Real-Time AI Intelligence
//  QuickFlip
//

import SwiftUI

struct EnhancedHomeView: View {
    let marketAnalysisAction: (MarketTrends?, PersonalInsights?, Bool, Bool, @escaping () -> Void) -> Void
    let scanItemAction: () -> Void
    let viewAllScansAction: () -> Void
    let viewDealsActions: () -> Void

    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var itemStorage: ItemStorageService
    @EnvironmentObject var authManager: AuthManager

    @StateObject private var marketIntelligence = MarketIntelligenceService()
    @StateObject private var personalAnalytics = PersonalAnalyticsService()

    @State private var showingPersonalDetails = false

    var body: some View {
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
        .refreshable {
            await refreshAllData()
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
        .sheet(isPresented: $showingPersonalDetails) {
            PersonalPerformanceView(
                insights: personalAnalytics.insights,
                userStats: itemStorage.userStats,
                scannedItems: itemStorage.scannedItems,
                isLoading: personalAnalytics.isLoadingInsights,
                onRefresh: {
                    Task {
                        await personalAnalytics.analyzeUserData(itemStorage.scannedItems)
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
                    Text(authManager.userName?.isEmpty == false ? "Welcome back," : "Welcome back")
                        .font(.title2)
                        .foregroundColor(.gray)

                    if let userName = authManager.userName, !userName.isEmpty {
                        Text(userName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
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
                .background(Color(.systemGray6))
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
                    marketAnalysisAction(marketIntelligence.dailyTrends,
                                         personalAnalytics.insights,
                                         marketIntelligence.isLoadingTrends,
                                         personalAnalytics.isLoadingInsights,
                                         {
                        Task {
                            await refreshAllData()
                        }
                    })

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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Performance")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Details") {
                    showingPersonalDetails = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Card 1 - Items Scanned or Loading
                    if personalAnalytics.isLoadingInsights {
                        LoadingPerformanceCard()
                    } else if let insights = personalAnalytics.insights {
                        ItemsScannedCard(count: insights.totalItemsAnalyzed)
                    } else {
                        NoDataPerformanceCard(
                            title: "Items Scanned",
                            subtitle: "Start scanning",
                            icon: "camera.fill",
                            color: .blue
                        )
                    }

                    // Card 2 - Success Rate or Strongest Category
                    if let insights = personalAnalytics.insights {
                        SuccessRateCard(
                            rate: insights.successRate.percentage,
                            level: insights.skillLevel.displayText,
                            color: insights.successRate.color
                        )
                    } else {
                        NoDataPerformanceCard(
                            title: "Success Rate",
                            subtitle: "Track progress",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                    }

                    // Card 3 - Best Category or Daily Value
                    if let insights = personalAnalytics.insights {
                        BestCategoryCard(
                            category: insights.strongestCategory,
                            marketplace: insights.mostProfitableMarketplace
                        )
                    } else {
                        NoDataPerformanceCard(
                            title: "Performance",
                            subtitle: "See insights",
                            icon: "star.fill",
                            color: .purple
                        )
                    }

                    // Card 4 - AI Recommendation (if available)
                    if let insights = personalAnalytics.insights, !insights.nextRecommendation.isEmpty {
                        RecommendationPreviewCard(
                            recommendation: insights.nextRecommendation
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Action button if no insights yet
            if personalAnalytics.insights == nil && !personalAnalytics.isLoadingInsights && !itemStorage.scannedItems.isEmpty {
                Button(action: {
                    Task {
                        await personalAnalytics.analyzeUserData(itemStorage.scannedItems)
                    }
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
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
                    scanItemAction()
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

                SmartQuickActionCard(
                    title: "Find deals",
                    subtitle: "See todays deals for inspiration",
                    icon: "dollarsign.arrow.circlepath",
                    color: .green,
                    isRecommended: itemStorage.scannedItems.count > 3
                ) {
                    viewDealsActions()
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
                Button {
                    viewAllScansAction()
                } label: {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
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
                scanItemAction()
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
        // Check if we have valid cached market data first
        if marketIntelligence.dailyTrends == nil {
            await marketIntelligence.loadDailyTrends(supabaseService: supabaseService)
        } else {
            print("QuickFlip: Using existing market trends data")
        }

        // Only analyze personal data if we have items and no current insights
        if !itemStorage.scannedItems.isEmpty && personalAnalytics.insights == nil {
            await personalAnalytics.analyzeUserData(itemStorage.scannedItems)
        }
    }

    private func refreshAllData() async {
        await marketIntelligence.loadDailyTrends(supabaseService: supabaseService)
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
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
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
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
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
            CachedImageView.listItem(imageUrl: item.imageUrl)
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
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
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
                        .background(Color(.systemGray6))
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
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
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
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
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
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
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
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
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
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
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
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
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
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray6), lineWidth: 1)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Refresh") {
                    onRefresh()
                }
            }
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
        .background(Color(.systemBackground))
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
            .background(Color(.systemGray6))
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
        .shadow(color: Color(.systemGray4), radius: 4, x: 0, y: 2)
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
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Performance Cards (Your Performance Section)

struct ItemsScannedCard: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "camera.fill")
                .foregroundColor(.blue)
                .font(.title2)

            Text("Items Scanned")
                .font(.caption)
                .foregroundColor(.gray)

            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)

            Text("Total analyzed")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
        )
    }
}

struct SuccessRateCard: View {
    let rate: String
    let level: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(color)
                .font(.title2)

            Text("Success Rate")
                .font(.caption)
                .foregroundColor(.gray)

            Text(rate)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(level)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
        )
    }
}

struct BestCategoryCard: View {
    let category: String
    let marketplace: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.purple)
                .font(.title2)

            Text("Top Category")
                .font(.caption)
                .foregroundColor(.gray)

            Text(category)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text("via \(marketplace)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.purple)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
        )
    }
}

struct RecommendationPreviewCard: View {
    let recommendation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)
                .font(.title2)

            Text("AI Tip")
                .font(.caption)
                .foregroundColor(.gray)

            Text(recommendation.prefix(30) + "...")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(3)

            Text("Tap for more")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
        )
    }
}

struct LoadingPerformanceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(0.8)

            Text("Analyzing")
                .font(.caption)
                .foregroundColor(.gray)

            Text("Performance")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Please wait...")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
        )
    }
}

struct NoDataPerformanceCard: View {
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

            Text("Tap Details")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray6), lineWidth: 1)
                )
        )
    }
}

// MARK: - Personal Performance Detail View

struct PersonalPerformanceView: View {
    let insights: PersonalInsights?
    let userStats: UserStats
    let scannedItems: [ScannedItem]
    let isLoading: Bool
    let onRefresh: () -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        loadingSection
                    } else if let insights = insights {
                        performanceMetricsSection(insights: insights)
                        trendsAndPatternsSection(insights: insights)
                        recommendationsSection(insights: insights)
                        recentActivitySection
                    } else {
                        noDataSection
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Your Performance")
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

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(1.5)

            Text("Analyzing Your Performance")
                .font(.title2)
                .fontWeight(.bold)

            Text("AI is analyzing your scanning patterns, success rates, and opportunities...")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }

    private func performanceMetricsSection(insights: PersonalInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(title: "Items Scanned", value: "\(insights.totalItemsAnalyzed)", color: .blue, icon: "camera.fill")
                MetricCard(title: "Success Rate", value: insights.successRate.percentage, color: insights.successRate.color, icon: "chart.line.uptrend.xyaxis")
                MetricCard(title: "Skill Level", value: insights.skillLevel.displayText, color: insights.skillLevel.color, icon: "star.fill")
                MetricCard(title: "Daily Value", value: "$\(String(format: "%.0f", insights.averageDailyValue))", color: .green, icon: "dollarsign.circle.fill")
            }

            // Additional metrics
            VStack(spacing: 12) {
                DetailMetricRow(title: "Strongest Category", value: insights.strongestCategory, icon: "tag.fill")
                DetailMetricRow(title: "Best Marketplace", value: insights.mostProfitableMarketplace, icon: "crown.fill")
                DetailMetricRow(title: "Scanning Pattern", value: insights.scanningPattern, icon: "calendar.circle.fill")
                DetailMetricRow(title: "Optimal Timing", value: insights.marketTiming, icon: "clock.fill")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func trendsAndPatternsSection(insights: PersonalInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends & Patterns")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                TrendCard(
                    title: "Category Performance",
                    insight: "Your strongest area is \(insights.strongestCategory)",
                    color: .blue
                )

                TrendCard(
                    title: "Marketplace Success",
                    insight: "\(insights.mostProfitableMarketplace) gives you the best results",
                    color: .purple
                )

                TrendCard(
                    title: "Activity Pattern",
                    insight: insights.scanningPattern,
                    color: .orange
                )
            }
        }
    }

    private func recommendationsSection(insights: PersonalInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Recommendations")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ActionableRecommendationCard(
                    title: "Next Steps",
                    content: insights.nextRecommendation,
                    actionText: "Start Scanning",
                    color: .green
                )

                ActionableRecommendationCard(
                    title: "Focus Area",
                    content: insights.focusArea,
                    actionText: "Learn More",
                    color: .blue
                )

                ActionableRecommendationCard(
                    title: "Profit Opportunity",
                    content: insights.profitOpportunity,
                    actionText: "Explore",
                    color: .orange
                )
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                ForEach(scannedItems.prefix(5)) { item in
                    RecentActivityRow(item: item)
                }
            }
        }
    }

    private var noDataSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))

            Text("No Performance Data")
                .font(.title2)
                .fontWeight(.bold)

            Text("Start scanning items to see your performance insights")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button("Analyze Performance") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Performance Detail Components

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
    }
}

struct DetailMetricRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

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

struct TrendCard: View {
    let title: String
    let insight: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(insight)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ActionableRecommendationCard: View {
    let title: String
    let content: String
    let actionText: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(color)

                    Text(content)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(actionText) {
                    // Action implementation
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.2))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
    }
}

struct RecentActivityRow: View {
    let item: ScannedItem

    var body: some View {
        HStack {
            // Item image placeholder
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.caption)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(item.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(item.estimatedValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
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
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}
