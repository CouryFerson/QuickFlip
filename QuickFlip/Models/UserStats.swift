import SwiftUI

struct UserStats: Codable {
    let totalItemsScanned: Int
    let totalPotentialSavings: Double
    let totalPotentialProfit: Double
    let favoriteMarketplace: String
    let averageProfit: Double
    let lastUpdated: Date

    // Add CodingKeys for database column mapping
    enum CodingKeys: String, CodingKey {
        case totalItemsScanned = "total_items_scanned"
        case totalPotentialSavings = "total_potential_savings"
        case totalPotentialProfit = "total_potential_profit"
        case favoriteMarketplace = "favorite_marketplace"
        case averageProfit = "average_profit"
        case lastUpdated = "last_updated"
    }

    init(from items: [ScannedItem]) {
        self.totalItemsScanned = items.count
        self.lastUpdated = Date()

        // Calculate total potential savings (difference between best and worst marketplace)
        var totalSavings = 0.0
        var totalProfit = 0.0
        var bestProfitsSum = 0.0
        var marketplaceCounts: [String: Int] = [:]

        for item in items {
            let prices = Array(item.priceAnalysis.averagePrices.values)
            if let maxPrice = prices.max(), let minPrice = prices.min() {
                totalSavings += (maxPrice - minPrice)
                bestProfitsSum += maxPrice
            }

            // Count marketplace recommendations
            marketplaceCounts[item.priceAnalysis.recommendedMarketplace, default: 0] += 1

            // Calculate profit if we have breakdown data
            if let profitBreakdowns = item.profitBreakdowns, !profitBreakdowns.isEmpty {
                let avgProfit = profitBreakdowns.map(\.netProfit).reduce(0, +) / Double(profitBreakdowns.count)
                totalProfit += avgProfit
            }
        }

        self.totalPotentialSavings = totalSavings
        self.totalPotentialProfit = bestProfitsSum  // NEW
        self.favoriteMarketplace = marketplaceCounts.max(by: { $0.value < $1.value })?.key ?? "eBay"
        self.averageProfit = items.isEmpty ? 0 : totalProfit / Double(items.count)
    }
}

extension UserStats {
    // Database initializer (for loading from Supabase)
    init(
        totalItemsScanned: Int,
        totalPotentialSavings: Double,
        totalPotentialProfit: Double,  // NEW parameter
        favoriteMarketplace: String,
        averageProfit: Double,
        lastUpdated: Date
    ) {
        self.totalItemsScanned = totalItemsScanned
        self.totalPotentialSavings = totalPotentialSavings
        self.totalPotentialProfit = totalPotentialProfit  // NEW
        self.favoriteMarketplace = favoriteMarketplace
        self.averageProfit = averageProfit
        self.lastUpdated = lastUpdated
    }
}
