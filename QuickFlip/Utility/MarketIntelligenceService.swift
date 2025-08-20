//
//  MarketIntelligenceService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI
import Foundation

// MARK: - Market Intelligence Service
class MarketIntelligenceService: ObservableObject {
    @Published var dailyTrends: MarketTrends?
    @Published var isLoadingTrends = false
    @Published var lastUpdated: Date?

    private let cacheKey = "dailyMarketTrends"
    private let cacheExpiryHours = 1 // Refresh every 6 hours

    func loadDailyTrends() async {
        // Check cache first
        if let cachedTrends = loadFromCache() {
            await MainActor.run {
                self.dailyTrends = cachedTrends
                self.lastUpdated = UserDefaults.standard.object(forKey: "\(cacheKey)_timestamp") as? Date
            }
            return
        }

        await MainActor.run {
            self.isLoadingTrends = true
        }

        do {
            let trends = try await fetchMarketTrendsFromAI()
            await MainActor.run {
                self.dailyTrends = trends
                self.lastUpdated = Date()
                self.isLoadingTrends = false
            }
            saveToCache(trends)
        } catch {
            print("QuickFlip: Failed to load market trends: \(error)")
            await MainActor.run {
                self.isLoadingTrends = false
            }
        }
    }

    private func fetchMarketTrendsFromAI() async throws -> MarketTrends {
        let currentDate = DateFormatter().string(from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentDay = Calendar.current.component(.weekday, from: Date())

        let prompt = """
        You are a resale market expert. Analyze current market trends for \(currentDate).
        
        Consider:
        - Seasonal patterns (current month: \(currentMonth))
        - Day of week effects (today is weekday \(currentDay))
        - Recent economic conditions
        - Popular culture trends
        - Holiday proximity
        
        Respond in this EXACT format:
        
        HOT_CATEGORIES:
        1. [Category Name] - [+X%] - [Brief reason]
        2. [Category Name] - [+X%] - [Brief reason] 
        3. [Category Name] - [+X%] - [Brief reason]
        
        COOLING_CATEGORIES:
        1. [Category Name] - [-X%] - [Brief reason]
        2. [Category Name] - [-X%] - [Brief reason]
        
        BEST_LISTING_TIME: [Time of day/day of week recommendation]
        
        MARKET_SENTIMENT: [BULLISH/NEUTRAL/BEARISH]
        
        TOP_INSIGHT: [One actionable insight for resellers today]
        
        SEASONAL_OPPORTUNITY: [What to focus on this time of year]
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 400,
            "temperature": 0.4
        ]

        guard let url = URL(string: OpenAIConfig.apiURL) else {
            throw MarketIntelligenceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw MarketIntelligenceError.parsingError
        }

        return parseMarketTrends(from: content)
    }

    private func parseMarketTrends(from content: String) -> MarketTrends {
        let lines = content.components(separatedBy: .newlines)
        var hotCategories: [TrendingCategory] = []
        var coolingCategories: [TrendingCategory] = []
        var bestListingTime = "Weekend evenings"
        var marketSentiment: MarketSentiment = .neutral
        var topInsight = "Focus on seasonal items for maximum profit"
        var seasonalOpportunity = "Back-to-school items are gaining momentum"

        var currentSection = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("HOT_CATEGORIES:") {
                currentSection = "hot"
            } else if trimmed.hasPrefix("COOLING_CATEGORIES:") {
                currentSection = "cooling"
            } else if trimmed.hasPrefix("BEST_LISTING_TIME:") {
                bestListingTime = String(trimmed.dropFirst(19)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("MARKET_SENTIMENT:") {
                let sentiment = String(trimmed.dropFirst(18)).trimmingCharacters(in: .whitespacesAndNewlines)
                marketSentiment = MarketSentiment.from(sentiment)
            } else if trimmed.hasPrefix("TOP_INSIGHT:") {
                topInsight = String(trimmed.dropFirst(13)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("SEASONAL_OPPORTUNITY:") {
                seasonalOpportunity = String(trimmed.dropFirst(22)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("1.") || trimmed.hasPrefix("2.") || trimmed.hasPrefix("3.") {
                if let category = parseTrendingCategory(from: trimmed) {
                    if currentSection == "hot" {
                        hotCategories.append(category)
                    } else if currentSection == "cooling" {
                        coolingCategories.append(category)
                    }
                }
            }
        }

        return MarketTrends(
            hotCategories: hotCategories,
            coolingCategories: coolingCategories,
            bestListingTime: bestListingTime,
            marketSentiment: marketSentiment,
            topInsight: topInsight,
            seasonalOpportunity: seasonalOpportunity,
            timestamp: Date()
        )
    }

    private func parseTrendingCategory(from line: String) -> TrendingCategory? {
        // Parse "1. Electronics - +15% - Back to school demand"
        let parts = line.components(separatedBy: " - ")
        guard parts.count >= 3 else { return nil }

        let nameWithNumber = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let name = String(nameWithNumber.dropFirst(3)) // Remove "1. "
        let changeStr = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let reason = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract percentage
        let percentageChange = extractPercentage(from: changeStr)

        return TrendingCategory(
            name: name,
            percentageChange: percentageChange,
            reason: reason,
            isPositive: percentageChange > 0
        )
    }

    private func extractPercentage(from text: String) -> Double {
        let pattern = #"[+-]?(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return 0
        }

        let numberStr = String(text[range])
        let number = Double(numberStr) ?? 0
        return text.hasPrefix("-") ? -number : number
    }

    private func saveToCache(_ trends: MarketTrends) {
        do {
            let cacheData = CachedMarketTrends(trends: trends, timestamp: Date())
            let data = try JSONEncoder().encode(cacheData)
            UserDefaults.standard.set(data, forKey: cacheKey)

            // Also save the timestamp separately for easier access
            UserDefaults.standard.set(Date(), forKey: "\(cacheKey)_timestamp")

            print("QuickFlip: Cached market trends with timestamp")
        } catch {
            print("QuickFlip: Failed to cache trends: \(error)")
        }
    }

    private func loadFromCache() -> MarketTrends? {
        // Check if we have both data and timestamp
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let timestamp = UserDefaults.standard.object(forKey: "\(cacheKey)_timestamp") as? Date else {
            print("QuickFlip: No cached data or timestamp found")
            return nil
        }

        // Check if cache is still valid (within 1 hour)
        let hoursSinceCache = Date().timeIntervalSince(timestamp) / 3600
        if hoursSinceCache > Double(cacheExpiryHours) {
            print("QuickFlip: Cache expired (\(String(format: "%.1f", hoursSinceCache)) hours old)")
            return nil
        }

        do {
            let cachedData = try JSONDecoder().decode(CachedMarketTrends.self, from: data)
            print("QuickFlip: Using cached trends (\(String(format: "%.1f", hoursSinceCache)) hours old)")
            return cachedData.trends
        } catch {
            print("QuickFlip: Failed to decode cached trends: \(error)")
            return nil
        }
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: "\(cacheKey)_timestamp")
        print("QuickFlip: Market trends cache cleared")
    }

    func getCacheAge() -> TimeInterval? {
        guard let timestamp = UserDefaults.standard.object(forKey: "\(cacheKey)_timestamp") as? Date else {
            return nil
        }
        return Date().timeIntervalSince(timestamp)
    }
}

// MARK: - Personal Analytics Service
class PersonalAnalyticsService: ObservableObject {
    @Published var insights: PersonalInsights?
    @Published var isLoadingInsights = false

    func analyzeUserData(_ items: [ScannedItem]) async {
        return
        guard !items.isEmpty else { return }

        await MainActor.run {
            self.isLoadingInsights = true
        }

        do {
            let insights = try await generatePersonalInsights(from: items)
            await MainActor.run {
                self.insights = insights
                self.isLoadingInsights = false
            }
        } catch {
            print("QuickFlip: Failed to analyze user data: \(error)")
            await MainActor.run {
                self.isLoadingInsights = false
            }
        }
    }

    private func generatePersonalInsights(from items: [ScannedItem]) async throws -> PersonalInsights {
        let itemSummary = createItemSummary(from: items)

        let prompt = """
        Analyze this user's QuickFlip scanning history and provide personalized insights:
        
        SCANNING HISTORY:
        Total Items: \(items.count)
        \(itemSummary)
        
        Provide insights in this EXACT format:
        
        STRONGEST_CATEGORY: [Category name they scan most]
        PROFIT_OPPORTUNITY: [Category/strategy with highest profit potential]
        SCANNING_PATTERN: [When/how often they scan - daily/weekly/etc]
        SUCCESS_RATE: [HIGH/MEDIUM/LOW based on variety and frequency]
        NEXT_RECOMMENDATION: [Specific actionable advice]
        MARKET_TIMING: [Best time for them to list based on their items]
        SKILL_LEVEL: [BEGINNER/INTERMEDIATE/ADVANCED]
        FOCUS_AREA: [What they should focus on to maximize profit]
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.3
        ]

        guard let url = URL(string: OpenAIConfig.apiURL) else {
            throw PersonalAnalyticsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw PersonalAnalyticsError.parsingError
        }

        return parsePersonalInsights(from: content, items: items)
    }

    private func createItemSummary(from items: [ScannedItem]) -> String {
        let recentItems = items.prefix(10)
        return recentItems.map { "- \($0.itemName) (\($0.category)) - \($0.estimatedValue)" }
            .joined(separator: "\n")
    }

    private func parsePersonalInsights(from content: String, items: [ScannedItem]) -> PersonalInsights {
        let lines = content.components(separatedBy: .newlines)
        var strongestCategory = "Electronics"
        var profitOpportunity = "Focus on branded items"
        var scanningPattern = "Weekly scanner"
        var successRate: SuccessRate = .medium
        var nextRecommendation = "Try scanning vintage items"
        var marketTiming = "Weekend evenings"
        var skillLevel: SkillLevel = .intermediate
        var focusArea = "Diversify categories"

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("STRONGEST_CATEGORY:") {
                strongestCategory = String(trimmed.dropFirst(19)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("PROFIT_OPPORTUNITY:") {
                profitOpportunity = String(trimmed.dropFirst(20)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("SCANNING_PATTERN:") {
                scanningPattern = String(trimmed.dropFirst(18)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("SUCCESS_RATE:") {
                let rate = String(trimmed.dropFirst(14)).trimmingCharacters(in: .whitespacesAndNewlines)
                successRate = SuccessRate.from(rate)
            } else if trimmed.hasPrefix("NEXT_RECOMMENDATION:") {
                nextRecommendation = String(trimmed.dropFirst(21)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("MARKET_TIMING:") {
                marketTiming = String(trimmed.dropFirst(15)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("SKILL_LEVEL:") {
                let level = String(trimmed.dropFirst(13)).trimmingCharacters(in: .whitespacesAndNewlines)
                skillLevel = SkillLevel.from(level)
            } else if trimmed.hasPrefix("FOCUS_AREA:") {
                focusArea = String(trimmed.dropFirst(12)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return PersonalInsights(
            strongestCategory: strongestCategory,
            profitOpportunity: profitOpportunity,
            scanningPattern: scanningPattern,
            successRate: successRate,
            nextRecommendation: nextRecommendation,
            marketTiming: marketTiming,
            skillLevel: skillLevel,
            focusArea: focusArea,
            totalItemsAnalyzed: items.count,
            averageDailyValue: calculateAverageDailyValue(from: items),
            mostProfitableMarketplace: findMostProfitableMarketplace(from: items)
        )
    }

    private func calculateAverageDailyValue(from items: [ScannedItem]) -> Double {
        guard !items.isEmpty else { return 0 }

        let totalValue = items.compactMap { extractValue(from: $0.estimatedValue) }
            .reduce(0, +)

        let daySpan = Calendar.current.dateComponents([.day],
            from: items.last?.timestamp ?? Date(),
            to: items.first?.timestamp ?? Date()).day ?? 1

        return totalValue / Double(max(daySpan, 1))
    }

    private func findMostProfitableMarketplace(from items: [ScannedItem]) -> String {
        let marketplaceCounts = items.reduce(into: [String: Int]()) { counts, item in
            counts[item.priceAnalysis.recommendedMarketplace, default: 0] += 1
        }

        return marketplaceCounts.max(by: { $0.value < $1.value })?.key ?? "eBay"
    }

    private func extractValue(from valueString: String) -> Double {
        let cleanString = valueString.replacingOccurrences(of: "$", with: "")
        let components = cleanString.components(separatedBy: "-")
        if let firstValue = components.first?.trimmingCharacters(in: .whitespacesAndNewlines),
           let value = Double(firstValue) {
            return value
        }
        return 0
    }
}

// MARK: - Data Models
struct MarketTrends: Codable {
    let hotCategories: [TrendingCategory]
    let coolingCategories: [TrendingCategory]
    let bestListingTime: String
    let marketSentiment: MarketSentiment
    let topInsight: String
    let seasonalOpportunity: String
    let timestamp: Date
}

struct TrendingCategory: Codable {
    let name: String
    let percentageChange: Double
    let reason: String
    let isPositive: Bool

    var formattedChange: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(Int(percentageChange))%"
    }

    var color: Color {
        return isPositive ? .green : .red
    }
}

enum MarketSentiment: String, Codable {
    case bullish = "BULLISH"
    case neutral = "NEUTRAL"
    case bearish = "BEARISH"

    static func from(_ string: String) -> MarketSentiment {
        switch string.uppercased() {
        case "BULLISH": return .bullish
        case "BEARISH": return .bearish
        default: return .neutral
        }
    }

    var color: Color {
        switch self {
        case .bullish: return .green
        case .neutral: return .orange
        case .bearish: return .red
        }
    }

    var emoji: String {
        switch self {
        case .bullish: return "📈"
        case .neutral: return "📊"
        case .bearish: return "📉"
        }
    }
}

struct PersonalInsights {
    let strongestCategory: String
    let profitOpportunity: String
    let scanningPattern: String
    let successRate: SuccessRate
    let nextRecommendation: String
    let marketTiming: String
    let skillLevel: SkillLevel
    let focusArea: String
    let totalItemsAnalyzed: Int
    let averageDailyValue: Double
    let mostProfitableMarketplace: String
}

enum SuccessRate {
    case high, medium, low

    static func from(_ string: String) -> SuccessRate {
        switch string.uppercased() {
        case "HIGH": return .high
        case "LOW": return .low
        default: return .medium
        }
    }

    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }

    var percentage: String {
        switch self {
        case .high: return "85%"
        case .medium: return "65%"
        case .low: return "40%"
        }
    }
}

enum SkillLevel {
    case beginner, intermediate, advanced

    static func from(_ string: String) -> SkillLevel {
        switch string.uppercased() {
        case "BEGINNER": return .beginner
        case "ADVANCED": return .advanced
        default: return .intermediate
        }
    }

    var displayText: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var color: Color {
        switch self {
        case .beginner: return .blue
        case .intermediate: return .orange
        case .advanced: return .purple
        }
    }
}

// MARK: - Error Types
enum MarketIntelligenceError: Error {
    case invalidURL
    case parsingError
}

enum PersonalAnalyticsError: Error {
    case invalidURL
    case parsingError
}
