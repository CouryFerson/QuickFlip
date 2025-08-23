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

    init(id: String,
        totalItemsScanned: Int,
        subscriptionTier: String,
        tokens: Int) {
        self.id = id
        self.totalItemsScanned = totalItemsScanned
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiresAt = nil
        self.appleTransactionId = nil
        self.appleOriginalTransactionId = nil
        self.autoRenewEnabled = nil
        self.tokens = tokens
    }

    init(id: String,
        totalItemsScanned: Int,
        subscriptionTier: String,
        subscriptionExpiresAt: Date?,
        appleTransactionId: String?,
        appleOriginalTransactionId: String?,
        autoRenewEnabled: Bool?,
        tokens: Int) {
        self.id = id
        self.totalItemsScanned = totalItemsScanned
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.appleTransactionId = appleTransactionId
        self.appleOriginalTransactionId = appleOriginalTransactionId
        self.autoRenewEnabled = autoRenewEnabled
        self.tokens = tokens
    }

    func withUpdatedTokens(_ newTokenCount: Int) -> UserProfile {
        return UserProfile(id: self.id,
                           totalItemsScanned: self.totalItemsScanned,
                           subscriptionTier: self.subscriptionTier,
                           subscriptionExpiresAt: self.subscriptionExpiresAt,
                           appleTransactionId: self.appleTransactionId,
                           appleOriginalTransactionId: self.appleOriginalTransactionId,
                           autoRenewEnabled: self.autoRenewEnabled,
                           tokens: newTokenCount)
    }

    // Copy with tier and token update
    func withUpdatedSubscription(tier: String, tokens: Int, expiresAt: Date? = nil) -> UserProfile {
        return UserProfile(id: self.id,
                           totalItemsScanned: self.totalItemsScanned,
                           subscriptionTier: tier,
                           subscriptionExpiresAt: expiresAt,
                           appleTransactionId: self.appleTransactionId,
                           appleOriginalTransactionId: self.appleOriginalTransactionId,
                           autoRenewEnabled: self.autoRenewEnabled,
                           tokens: tokens)
    }
}
