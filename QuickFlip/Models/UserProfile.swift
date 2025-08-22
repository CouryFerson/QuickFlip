//
//  UserProfile.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/20/25.
//

import Foundation

struct UserProfile: Codable {
    let id: String
    let totalItemsScanned: Int
    let subscriptionTier: String
    let subscriptionExpiresAt: Date?
    let appleTransactionId: String?
    let appleOriginalTransactionId: String?
    let autoRenewEnabled: Bool?
    let tokens: Int

    enum CodingKeys: String, CodingKey {
        case id
        case totalItemsScanned = "total_items_scanned"
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
        case appleTransactionId = "apple_transaction_id"
        case appleOriginalTransactionId = "apple_original_transaction_id"
        case autoRenewEnabled = "auto_renew_enabled"
        case tokens
    }
}
