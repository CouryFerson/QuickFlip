//
//  MarketplaceRecommendation.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/20/25.
//


struct MarketplaceRecommendation: Codable {
    let marketplace: String
    let estimatedPrice: Double
    let confidence: Double
    let fees: Double
    let netProfit: Double
}
