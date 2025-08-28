
import Foundation

struct UserProfile: Codable {
    let id: String
    let tokens: Int

    enum CodingKeys: String, CodingKey {
        case id
        case tokens
    }

    init(id: String, tokens: Int) {
        self.id = id
        self.tokens = tokens
    }
}

// New UserSubscription model
struct UserSubscription: Codable {
    let id: String
    let userId: String
    let tierName: String
    let expiresAt: Date?
    let appleTransactionId: String?
    let appleOriginalTransactionId: String?
    let autoRenewEnabled: Bool
    let status: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tierName = "tier_name"
        case expiresAt = "expires_at"
        case appleTransactionId = "apple_transaction_id"
        case appleOriginalTransactionId = "apple_original_transaction_id"
        case autoRenewEnabled = "auto_renew_enabled"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isActive: Bool {
        return status == "active"
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt < Date()
    }
}

// Combined model for easy access
struct UserProfileWithSubscription {
    let profile: UserProfile
    let subscription: UserSubscription
    let subscriptionTier: SubscriptionTier?

    var tierName: String {
        return subscription.tierName
    }

    var tokens: Int {
        return profile.tokens
    }

    var features: [String] {
        return subscriptionTier?.features ?? []
    }
}
