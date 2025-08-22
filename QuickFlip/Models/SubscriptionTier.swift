//
//  SubscriptionTier.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/22/25.
//

import Foundation

struct SubscriptionTier: Codable {
    let id: String
    let tierName: String
    let tokensPerPeriod: Int
    let features: [String]  // Array instead of dictionary
    let priceMonthly: Double?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case tierName = "tier_name"
        case tokensPerPeriod = "tokens_per_period"
        case features
        case priceMonthly = "price_monthly"
        case isActive = "is_active"
    }
}
