//
//  SupabaseService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/20/25.
//

import Foundation
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    // Get current user's profile ID
    private var currentUserProfileId: String? {
        return client.auth.currentUser?.id.uuidString
    }

    // MARK: - User Profile Operations

    func getUserProfile() async throws -> UserProfile {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        let response: UserProfile = try await client
            .from("user_profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return response
    }

    func updateScanCount(newCount: Int) async throws {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        struct ScanCountUpdate: Codable {
            let totalItemsScanned: Int

            enum CodingKeys: String, CodingKey {
                case totalItemsScanned = "total_items_scanned"
            }
        }

        let update = ScanCountUpdate(totalItemsScanned: newCount)

        try await client
            .from("user_profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()
    }

    func incrementScanCount() async throws {
        let profile = try await getUserProfile()
        let newCount = profile.totalItemsScanned + 1
        try await updateScanCount(newCount: newCount)
    }

    func updateSubscriptionTier(tier: String) async throws {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        struct TierUpdate: Codable {
            let subscriptionTier: String

            enum CodingKeys: String, CodingKey {
                case subscriptionTier = "subscription_tier"
            }
        }

        let update = TierUpdate(subscriptionTier: tier)

        try await client
            .from("user_profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Scanned Items Operations

    func saveScannedItem(_ item: ScannedItem) async throws {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        // Create a version with user_profile_id for database insert
        // This is the ONLY place we need to add the user association
        struct ScannedItemWithUser: Codable {
            let userProfileId: String
            let id: UUID
            let itemName: String
            let category: String
            let condition: String
            let description: String
            let estimatedValue: String
            let timestamp: Date
            let imageData: String? // Changed to String for Base64
            let priceAnalysis: StorableMarketplacePriceAnalysis
            let userCostBasis: Double?
            let userNotes: String?
            let profitBreakdowns: [StorableProfitBreakdown]?

            enum CodingKeys: String, CodingKey {
                case userProfileId = "user_profile_id"
                case id
                case itemName = "item_name"
                case category
                case condition
                case description
                case estimatedValue = "estimated_value"
                case timestamp
                case imageData = "image_data"
                case priceAnalysis = "price_analysis"
                case userCostBasis = "user_cost_basis"
                case userNotes = "user_notes"
                case profitBreakdowns = "profit_breakdowns"
            }
        }

        let itemWithUser = ScannedItemWithUser(
            userProfileId: userId,
            id: item.id,
            itemName: item.itemName,
            category: item.category,
            condition: item.condition,
            description: item.description,
            estimatedValue: item.estimatedValue,
            timestamp: item.timestamp,
            imageData: item.imageData,
            priceAnalysis: item.priceAnalysis,
            userCostBasis: item.userCostBasis,
            userNotes: item.userNotes,
            profitBreakdowns: item.profitBreakdowns
        )

        try await client
            .from("scanned_items")
            .insert(itemWithUser)
            .execute()
    }

    func fetchUserScannedItems() async throws -> [ScannedItem] {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        let response: [ScannedItem] = try await client
            .from("scanned_items")
            .select()
            .eq("user_profile_id", value: userId)
            .order("timestamp", ascending: false)
            .execute()
            .value

        return response
    }

    func deleteScannedItem(_ item: ScannedItem) async throws {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        try await client
            .from("scanned_items")
            .delete()
            .eq("id", value: item.id.uuidString)
            .eq("user_profile_id", value: userId)
            .execute()
    }

    func updateScannedItem(_ item: ScannedItem) async throws {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        // For updates, we can use the ScannedItem directly
        // Supabase will ignore the user_profile_id in the WHERE clause
        try await client
            .from("scanned_items")
            .update(item)
            .eq("id", value: item.id.uuidString)
            .eq("user_profile_id", value: userId)
            .execute()
    }

    // MARK: - User Stats Operations

    func fetchUserStats() async throws -> UserStats? {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        do {
            let response: UserStats = try await client
                .from("user_stats")
                .select()
                .eq("user_profile_id", value: userId)
                .single()
                .execute()
                .value

            return response
        } catch {
            return nil
        }
    }

    func saveUserStats(_ stats: UserStats) async throws {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        // Create version with user_profile_id for database
        struct UserStatsWithUser: Codable {
            let userProfileId: String
            let totalPotentialSavings: Double
            let favoriteMarketplace: String
            let totalItemsScanned: Int
            let averageProfit: Double
            let lastUpdated: Date

            enum CodingKeys: String, CodingKey {
                case userProfileId = "user_profile_id"
                case totalPotentialSavings = "total_potential_savings"
                case favoriteMarketplace = "favorite_marketplace"
                case totalItemsScanned = "total_items_scanned"
                case averageProfit = "average_profit"
                case lastUpdated = "last_updated"
            }
        }

        let statsWithUser = UserStatsWithUser(
            userProfileId: userId,
            totalPotentialSavings: stats.totalPotentialSavings,
            favoriteMarketplace: stats.favoriteMarketplace,
            totalItemsScanned: stats.totalItemsScanned,
            averageProfit: stats.averageProfit,
            lastUpdated: stats.lastUpdated
        )

        // Try update first, then insert if it fails
        do {
            try await client
                .from("user_stats")
                .update(statsWithUser)
                .eq("user_profile_id", value: userId)
                .execute()
        } catch {
            try await client
                .from("user_stats")
                .insert(statsWithUser)
                .execute()
        }
    }

    // MARK: - Helper Methods

    func checkConnection() async throws -> Bool {
        let _: [UserProfile] = try await client
            .from("user_profiles")
            .select()
            .limit(1)
            .execute()
            .value

        return true
    }
}

// MARK: - Subscription Tier Operations

extension SupabaseService {

    func getAllSubscriptionTiers() async throws -> [SubscriptionTier] {
        let response: [SubscriptionTier] = try await client
            .from("subscription_tiers")
            .select()
            .eq("is_active", value: true)
            .order("tokens_per_period", ascending: true)
            .execute()
            .value

        return response
    }

    func getSubscriptionTier(named tierName: String) async throws -> SubscriptionTier? {
        do {
            let response: SubscriptionTier = try await client
                .from("subscription_tiers")
                .select()
                .eq("tier_name", value: tierName.lowercased())
                .eq("is_active", value: true)
                .single()
                .execute()
                .value

            return response
        } catch {
            return nil
        }
    }

    func getUserSubscriptionTier() async throws -> SubscriptionTier? {
        let profile = try await getUserProfile()
        return try await getSubscriptionTier(named: profile.subscriptionTier)
    }

    func hasFeature(_ feature: String) async throws -> Bool {
        guard let tier = try await getUserSubscriptionTier() else { return false }
        return tier.features.contains(feature)
    }
}

// MARK: - Token Management

extension SupabaseService {

    func getTokenCount() async throws -> Int {
        let profile = try await getUserProfile()
        return profile.tokens
    }

    func hasTokens() async throws -> Bool {
        let tokenCount = try await getTokenCount()
        return tokenCount > 0
    }

    func consumeToken() async throws -> Int {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        let currentProfile = try await getUserProfile()

        guard currentProfile.tokens > 0 else {
            throw SupabaseServiceError.insufficientTokens
        }

        let newTokenCount = currentProfile.tokens - 1

        struct TokenUpdate: Codable {
            let tokens: Int
        }

        let update = TokenUpdate(tokens: newTokenCount)

        try await client
            .from("user_profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()

        return newTokenCount
    }

    func setTokensForTier(_ tierName: String) async throws -> Int {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        guard let tier = try await getSubscriptionTier(named: tierName) else {
            throw SupabaseServiceError.invalidData
        }

        struct TierTokenUpdate: Codable {
            let subscriptionTier: String
            let tokens: Int

            enum CodingKeys: String, CodingKey {
                case subscriptionTier = "subscription_tier"
                case tokens
            }
        }

        let update = TierTokenUpdate(
            subscriptionTier: tier.tierName,
            tokens: tier.tokensPerPeriod
        )

        try await client
            .from("user_profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()

        return tier.tokensPerPeriod
    }

    func refillTokens() async throws -> Int {
        let profile = try await getUserProfile()
        return try await setTokensForTier(profile.subscriptionTier)
    }
}

// MARK: - Custom Errors

enum SupabaseServiceError: LocalizedError {
    case userNotFound
    case invalidData
    case networkError
    case unauthorized
    case insufficientTokens

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found"
        case .invalidData:
            return "Invalid data format"
        case .networkError:
            return "Network connection error"
        case .unauthorized:
            return "User not authenticated"
        case .insufficientTokens:
            return "Insufficient tokens to complete this request"
        }
    }
}
