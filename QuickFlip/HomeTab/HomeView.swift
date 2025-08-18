//
//  HomeView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct HomeView: View {
    @State private var userName = "User" // Could be stored in UserDefaults later
    @State private var totalScanned = 23 // Mock data for now
    @State private var totalSaved = 347.50 // Mock savings data
    @State private var topMarketplace = "StockX" // Mock trending data

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
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

                            // Profile/notification button
                            Button(action: {
                                // TODO: Profile action
                            }) {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.blue)
                                    )
                            }
                        }

                        Text("Ready to find your next profitable flip?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Quick Stats Cards
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StatsCard(
                                title: "Items Scanned",
                                value: "\(totalScanned)",
                                subtitle: "This month",
                                icon: "camera.fill",
                                color: .blue
                            )

                            StatsCard(
                                title: "Fees Saved",
                                value: "$\(String(format: "%.0f", totalSaved))",
                                subtitle: "Smart choices",
                                icon: "dollarsign.circle.fill",
                                color: .green
                            )
                        }

                        StatsCard(
                            title: "Top Marketplace",
                            value: topMarketplace,
                            subtitle: "Best for your items",
                            icon: "crown.fill",
                            color: .orange,
                            isWide: true
                        )
                    }
                    .padding(.horizontal)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Quick Actions")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            QuickActionCard(
                                title: "Scan New Item",
                                subtitle: "Take a photo to analyze",
                                icon: "camera.fill",
                                color: .blue
                            ) {
                                // TODO: Navigate to capture tab
                            }

                            QuickActionCard(
                                title: "Upload from Gallery",
                                subtitle: "Analyze existing photos",
                                icon: "photo.fill",
                                color: .purple
                            ) {
                                // TODO: Image picker
                            }

                            QuickActionCard(
                                title: "Barcode Scanner",
                                subtitle: "Quick lookup for products",
                                icon: "barcode.viewfinder",
                                color: .orange
                            ) {
                                // TODO: Barcode scanner
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Market Insights
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Market Insights")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Button("See All") {
                                // TODO: Full insights view
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                InsightCard(
                                    title: "Trending Up",
                                    subtitle: "Vintage Electronics",
                                    content: "+15%",
                                    icon: "arrow.up.circle.fill",
                                    color: .green
                                )

                                InsightCard(
                                    title: "Hot Category",
                                    subtitle: "Designer Handbags",
                                    content: "🔥 Popular",
                                    icon: "flame.fill",
                                    color: .red
                                )

                                InsightCard(
                                    title: "Best Time",
                                    subtitle: "Weekend Listings",
                                    content: "+23% sales",
                                    icon: "clock.fill",
                                    color: .blue
                                )
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Recent Activity (if we had data)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Scans")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Button("View All") {
                                // TODO: Navigate to history tab
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            RecentItemCard(
                                itemName: "Apple TV Remote",
                                bestPrice: "$67.50",
                                marketplace: "StockX",
                                timeAgo: "2 hours ago"
                            )

                            RecentItemCard(
                                itemName: "Nike Air Force 1",
                                bestPrice: "$120.00",
                                marketplace: "StockX",
                                timeAgo: "Yesterday"
                            )

                            RecentItemCard(
                                itemName: "Vintage Pyrex Bowl",
                                bestPrice: "$45.99",
                                marketplace: "Etsy",
                                timeAgo: "3 days ago"
                            )
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 100) // Extra space at bottom
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Supporting Views

struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var isWide: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
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
        .if(!isWide) { view in
            view.frame(maxWidth: .infinity)
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.title2)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

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

struct InsightCard: View {
    let title: String
    let subtitle: String?
    let content: String
    let icon: String?
    let color: Color

    init(title: String, subtitle: String? = nil, content: String, icon: String? = nil, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.icon = icon
        self.color = color
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(content)
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

struct RecentItemCard: View {
    let itemName: String
    let bestPrice: String
    let marketplace: String
    let timeAgo: String

    var body: some View {
        HStack {
            // Placeholder for item image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(itemName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Best on \(marketplace)")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(bestPrice)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}


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
    @State private var showingInsights = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header with Real Data
                    welcomeHeaderView

                    // Real Performance Stats
                    realPerformanceStatsView

                    // AI Market Intelligence
                    if marketIntelligence.isLoadingTrends {
                        aiLoadingView
                    } else if let trends = marketIntelligence.dailyTrends {
                        marketIntelligenceView(trends: trends)
                    } else {
                        loadMarketDataView
                    }

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
        .sheet(isPresented: $showingInsights) {
            PersonalInsightsDetailView(insights: personalAnalytics.insights)
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

    private var loadMarketDataView: some View {
        Button(action: {
            Task {
                await marketIntelligence.loadDailyTrends()
            }
        }) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Get AI Market Insights")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Real-time analysis of what's trending")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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
                    showingInsights = true
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
