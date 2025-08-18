//
//  MarketplacePriceAnalysis.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct MarketplacePriceAnalysis {
    let recommendedMarketplace: Marketplace
    let confidence: AnalysisConfidence
    let averagePrices: [Marketplace: Double]
    let reasoning: String
}

enum AnalysisConfidence {
    case high, medium, low

    var displayText: String {
        switch self {
        case .high: return "High Confidence"
        case .medium: return "Medium Confidence"
        case .low: return "Limited Data"
        }
    }

    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .orange
        case .low: return .gray
        }
    }
}
