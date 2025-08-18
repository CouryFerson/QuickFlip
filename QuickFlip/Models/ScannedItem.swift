
import Foundation
import UIKit
import SwiftUI

// MARK: - Scanned Item Model
struct ScannedItem: Codable, Identifiable {
    let id: UUID
    let itemName: String
    let category: String
    let condition: String
    let description: String
    let estimatedValue: String
    let timestamp: Date
    let imageData: Data?
    let priceAnalysis: StorableMarketplacePriceAnalysis
    let userCostBasis: Double?
    let userNotes: String?
    let profitBreakdowns: [StorableProfitBreakdown]?

    init(
        itemName: String,
        category: String,
        condition: String,
        description: String,
        estimatedValue: String,
        image: UIImage?,
        priceAnalysis: MarketplacePriceAnalysis,
        userCostBasis: Double? = nil,
        userNotes: String? = nil,
        profitBreakdowns: [ProfitBreakdown]? = nil
    ) {
        self.id = UUID()
        self.itemName = itemName
        self.category = category
        self.condition = condition
        self.description = description
        self.estimatedValue = estimatedValue
        self.timestamp = Date()
        self.imageData = image?.jpegData(compressionQuality: 0.8)
        self.priceAnalysis = StorableMarketplacePriceAnalysis(from: priceAnalysis)
        self.userCostBasis = userCostBasis
        self.userNotes = userNotes
        self.profitBreakdowns = profitBreakdowns?.map { StorableProfitBreakdown(from: $0) }
    }

    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }

    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var daysSinceScanned: Int {
        Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
    }
}

// MARK: - Storable Price Analysis (Codable version)
struct StorableMarketplacePriceAnalysis: Codable {
    let recommendedMarketplace: String
    let confidence: String
    let averagePrices: [String: Double] // [marketplace name: price]
    let reasoning: String

    init(from analysis: MarketplacePriceAnalysis) {
        self.recommendedMarketplace = analysis.recommendedMarketplace.rawValue
        self.confidence = analysis.confidence.displayText
        self.averagePrices = Dictionary(uniqueKeysWithValues:
            analysis.averagePrices.map { ($0.key.rawValue, $0.value) }
        )
        self.reasoning = analysis.reasoning
    }

    func toMarketplacePriceAnalysis() -> MarketplacePriceAnalysis {
        let marketplace = Marketplace.allCases.first { $0.rawValue == recommendedMarketplace } ?? .ebay
        let confidenceEnum: AnalysisConfidence = {
            switch confidence {
            case "High Confidence": return .high
            case "Low Confidence": return .low
            default: return .medium
            }
        }()

        // Fix: Use reduce to build the dictionary
        let marketplacePrices: [Marketplace: Double] = averagePrices.reduce(into: [:]) { result, element in
            let (key, value) = element
            if let marketplace = Marketplace.allCases.first(where: { $0.rawValue == key }) {
                result[marketplace] = value
            }
        }

        return MarketplacePriceAnalysis(
            recommendedMarketplace: marketplace,
            confidence: confidenceEnum,
            averagePrices: marketplacePrices,
            reasoning: reasoning
        )
    }
}

// MARK: - Storable Profit Breakdown (Codable version)
struct StorableProfitBreakdown: Codable {
    let marketplace: String
    let sellingPrice: Double
    let costBasis: Double
    let shippingCost: Double
    let totalFees: Double
    let feesDescription: String
    let netProfit: Double
    let profitMargin: Double

    init(from breakdown: ProfitBreakdown) {
        self.marketplace = breakdown.marketplace.rawValue
        self.sellingPrice = breakdown.sellingPrice
        self.costBasis = breakdown.costBasis
        self.shippingCost = breakdown.shippingCost
        self.totalFees = breakdown.fees.totalFees
        self.feesDescription = breakdown.fees.description
        self.netProfit = breakdown.netProfit
        self.profitMargin = breakdown.profitMargin
    }

    var formattedNetProfit: String {
        return String(format: "$%.2f", netProfit)
    }

    var profitColor: Color {
        if netProfit > 0 { return .green }
        if netProfit == 0 { return .orange }
        return .red
    }
}

// MARK: - User Stats (for dashboard)
struct UserStats: Codable {
    let totalItemsScanned: Int
    let totalPotentialSavings: Double
    let favoriteMarketplace: String
    let averageProfit: Double
    let lastUpdated: Date

    init(from items: [ScannedItem]) {
        self.totalItemsScanned = items.count
        self.lastUpdated = Date()

        // Calculate total potential savings (difference between best and worst marketplace)
        var totalSavings = 0.0
        var totalProfit = 0.0
        var marketplaceCounts: [String: Int] = [:]

        for item in items {
            let prices = Array(item.priceAnalysis.averagePrices.values)
            if let maxPrice = prices.max(), let minPrice = prices.min() {
                totalSavings += (maxPrice - minPrice)
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
        self.favoriteMarketplace = marketplaceCounts.max(by: { $0.value < $1.value })?.key ?? "eBay"
        self.averageProfit = items.isEmpty ? 0 : totalProfit / Double(items.count)
    }
}
