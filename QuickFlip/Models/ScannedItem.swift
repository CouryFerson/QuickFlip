import Foundation
import UIKit
import SwiftUI

// MARK: - Scanned Item Model
struct ScannedItem: Codable, Identifiable, Equatable {
    let id: UUID
    let itemName: String
    let category: String
    let condition: String
    let description: String
    let estimatedValue: String
    let timestamp: Date
    let imageUrl: String?
    let priceAnalysis: StorableMarketplacePriceAnalysis
    let userCostBasis: Double?
    let userNotes: String?
    let profitBreakdowns: [StorableProfitBreakdown]?
    var listingStatus: ListingStatus
    var advancedAIAnalysis: StorableMarketplacePriceAnalysis?
    var aiAnalysisGeneratedAt: Date?

    // MARK: - Database CodingKeys (maps Swift names to database columns)
    enum CodingKeys: String, CodingKey {
        case id
        case itemName = "item_name"
        case category
        case condition
        case description
        case estimatedValue = "estimated_value"
        case timestamp
        case imageUrl = "image_url"
        case priceAnalysis = "price_analysis"
        case userCostBasis = "user_cost_basis"
        case userNotes = "user_notes"
        case profitBreakdowns = "profit_breakdowns"
        case listingStatus = "listing_status"
        case advancedAIAnalysis = "advanced_ai_analysis"
        case aiAnalysisGeneratedAt = "ai_analysis_generated_at"
    }

    // MARK: - Standard Initializer (for creating new items)
    init(
        itemName: String,
        category: String,
        condition: String,
        description: String,
        estimatedValue: String,
        imageUrl: String? = nil,
        priceAnalysis: MarketplacePriceAnalysis,
        userCostBasis: Double? = nil,
        userNotes: String? = nil,
        profitBreakdowns: [ProfitBreakdown]? = nil,
        listingStatus: ListingStatus? = nil,
        advancedAIAnalysis: MarketplacePriceAnalysis? = nil,
        aiAnalysisGeneratedAt: Date? = nil
    ) {
        self.id = UUID()
        self.itemName = itemName
        self.category = category
        self.condition = condition
        self.description = description
        self.estimatedValue = estimatedValue
        self.timestamp = Date()
        self.imageUrl = imageUrl
        self.priceAnalysis = StorableMarketplacePriceAnalysis(from: priceAnalysis)
        self.userCostBasis = userCostBasis
        self.userNotes = userNotes
        self.profitBreakdowns = profitBreakdowns?.map { StorableProfitBreakdown(from: $0) }
        self.listingStatus = listingStatus ?? ListingStatus()
        self.advancedAIAnalysis = advancedAIAnalysis.map { StorableMarketplacePriceAnalysis(from: $0) }
        self.aiAnalysisGeneratedAt = aiAnalysisGeneratedAt
    }

    // MARK: - Database Initializer (for Supabase loading)
    init(
        id: UUID,
        itemName: String,
        category: String,
        condition: String,
        description: String,
        estimatedValue: String,
        timestamp: Date,
        imageUrl: String?,
        priceAnalysis: StorableMarketplacePriceAnalysis,
        userCostBasis: Double?,
        userNotes: String?,
        profitBreakdowns: [StorableProfitBreakdown]?,
        listingStatus: ListingStatus?,
        advancedAIAnalysis: StorableMarketplacePriceAnalysis?,
        aiAnalysisGeneratedAt: Date?
    ) {
        self.id = id
        self.itemName = itemName
        self.category = category
        self.condition = condition
        self.description = description
        self.estimatedValue = estimatedValue
        self.timestamp = timestamp
        self.imageUrl = imageUrl
        self.priceAnalysis = priceAnalysis
        self.userCostBasis = userCostBasis
        self.userNotes = userNotes
        self.profitBreakdowns = profitBreakdowns
        self.listingStatus = listingStatus ?? ListingStatus()
        self.advancedAIAnalysis = advancedAIAnalysis
        self.aiAnalysisGeneratedAt = aiAnalysisGeneratedAt
    }

    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var daysSinceScanned: Int {
        Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
    }

    var categoryName: String? {
        category.components(separatedBy: ">").last
    }

    // MARK: - Advanced AI Helpers
    var hasAdvancedAIAnalysis: Bool {
        return advancedAIAnalysis != nil
    }

    var formattedAIAnalysisTimestamp: String? {
        guard let date = aiAnalysisGeneratedAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Storable Price Analysis (Codable version)
struct StorableMarketplacePriceAnalysis: Codable, Equatable {
    let recommendedMarketplace: String
    let confidence: String
    let averagePrices: [String: Double]
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
struct StorableProfitBreakdown: Codable, Equatable {
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
