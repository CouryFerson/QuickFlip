//
//  SupabaseService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/20/25.
//

import Foundation
import Supabase
import UIKit

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

    private var currentUserUUID: UUID? {
        guard let userIdString = client.auth.currentUser?.id.uuidString,
              let uuid = UUID(uuidString: userIdString) else {
            return nil
        }

        return uuid
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

    func getAppConfig() async throws -> AppConfig {
        let response: AppConfig = try await client
            .from("app_config")
            .select()
            .order("created_at", ascending: false)
            .limit(1)
            .single()
            .execute()
            .value

        return response
    }

    func updateUserDisplayName(_ displayName: String) async throws {
        guard let userId = currentUserUUID else {
            throw SupabaseServiceError.unauthorized
        }

        try await client
            .from("user_profiles")
            .update(["display_name": displayName.trimmingCharacters(in: .whitespaces)])
            .eq("id", value: userId)
            .execute()
    }

    func updateTokenCount(_ newCount: Int) async throws {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        struct TokenUpdate: Codable {
            let tokens: Int
        }

        let update = TokenUpdate(tokens: newCount)

        try await client
            .from("user_profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()
    }

    func addTokens(_ amount: Int) async throws -> Int {
        let profile = try await getUserProfile()
        let newCount = profile.tokens + amount
        try await updateTokenCount(newCount)
        return newCount
    }

    func consumeTokens(_ amount: Int) async throws -> Int {
        let profile = try await getUserProfile()

        guard profile.tokens > 0 else {
            throw SupabaseServiceError.insufficientTokens
        }

        let newCount = profile.tokens - amount
        try await updateTokenCount(newCount)
        return newCount
    }

    // MARK: - Subscription Operations

    func getUserSubscription() async throws -> UserSubscription? {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        do {
            let response: UserSubscription = try await client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .single()
                .execute()
                .value

            return response
        } catch {
            return nil
        }
    }

    func createSubscription(tierName: String, expiresAt: Date? = nil) async throws -> UserSubscription {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        struct NewSubscription: Codable {
            let userId: String
            let tierName: String
            let expiresAt: Date?
            let status: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case tierName = "tier_name"
                case expiresAt = "expires_at"
                case status
            }
        }

        let newSub = NewSubscription(
            userId: userId,
            tierName: tierName,
            expiresAt: expiresAt,
            status: "active"
        )

        let response: UserSubscription = try await client
            .from("user_subscriptions")
            .insert(newSub)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func updateSubscription(tierName: String, expiresAt: Date? = nil) async throws -> UserSubscription {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        struct SubscriptionUpdate: Codable {
            let tierName: String
            let expiresAt: Date?
            let updatedAt: Date

            enum CodingKeys: String, CodingKey {
                case tierName = "tier_name"
                case expiresAt = "expires_at"
                case updatedAt = "updated_at"
            }
        }

        let update = SubscriptionUpdate(
            tierName: tierName,
            expiresAt: expiresAt,
            updatedAt: Date()
        )

        let response: UserSubscription = try await client
            .from("user_subscriptions")
            .update(update)
            .eq("user_id", value: userId)
            .eq("status", value: "active")
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func upgradeSubscription(to tierName: String) async throws -> (UserSubscription, Int) {
        // Get the new tier details
        guard let tier = try await getSubscriptionTier(named: tierName) else {
            throw SupabaseServiceError.invalidData
        }

        // Update subscription
        let subscription = try await updateSubscription(tierName: tierName)

        // Add tokens for the new tier (rollover approach)
        let newTokenCount = try await addTokens(tier.tokensPerPeriod)

        return (subscription, newTokenCount)
    }

    func refillMonthlyTokens() async throws -> Int {
        guard let subscription = try await getUserSubscription() else {
            throw SupabaseServiceError.userNotFound
        }

        guard let tier = try await getSubscriptionTier(named: subscription.tierName) else {
            throw SupabaseServiceError.invalidData
        }

        // Add monthly allocation to existing tokens (rollover)
        return try await addTokens(tier.tokensPerPeriod)
    }

    // MARK: - Subscription Tier Operations

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
        guard let subscription = try await getUserSubscription() else {
            return try await getSubscriptionTier(named: "free") // Default to free
        }
        return try await getSubscriptionTier(named: subscription.tierName)
    }

    func hasFeature(_ feature: String) async throws -> Bool {
        guard let tier = try await getUserSubscriptionTier() else { return false }
        return tier.features.contains(feature)
    }

    func createSignedUrl(for imagePath: String) async throws -> String {
        let signedURL = try await client.storage
            .from("scanned-items-images")
            .createSignedURL(path: imagePath, expiresIn: 3600)

        return signedURL.absoluteString
    }

    // MARK: - Scanned Items Operations

    // MARK: - Image Upload Functions
    private func uploadImageToStorage(_ image: UIImage, itemId: UUID) async throws -> String {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        // Convert UIImage to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SupabaseServiceError.invalidImageData
        }

        // Create file path: userId/itemId.jpg
        let fileName = "\(itemId.uuidString).jpg"
        let filePath = "\(userId)/\(fileName)"

        // Upload to Supabase Storage
        try await client.storage
            .from("scanned-items-images") // Your bucket name
            .upload(filePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))

        return filePath
    }

    private func deleteImageFromStorage(_ imageUrl: String) async throws {
        try await client.storage
            .from("scanned-items-images")
            .remove(paths: [imageUrl])
    }

    func saveScannedItem(_ item: ScannedItem, image: UIImage?) async throws -> ScannedItem {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        // Step 1: Upload image first (if provided)
        var imageUrl: String? = nil
        if let image = image {
            imageUrl = try await uploadImageToStorage(image, itemId: item.id)
        }

        // Step 2: Create updated item with imageUrl
        let updatedItem = ScannedItem(
            id: item.id,
            itemName: item.itemName,
            category: item.category,
            condition: item.condition,
            description: item.description,
            estimatedValue: item.estimatedValue,
            timestamp: item.timestamp,
            imageUrl: imageUrl,
            priceAnalysis: item.priceAnalysis,
            userCostBasis: item.userCostBasis,
            userNotes: item.userNotes,
            profitBreakdowns: item.profitBreakdowns,
            listingStatus: item.listingStatus,
            advancedAIAnalysis: item.advancedAIAnalysis,
            aiAnalysisGeneratedAt: item.aiAnalysisGeneratedAt,
            storageLocation: item.storageLocation
        )

        struct ScannedItemForDB: Codable {
            let userProfileId: String
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
            let listingStatus: ListingStatus
            let advancedAIAnalysis: StorableMarketplacePriceAnalysis?
            let aiAnalysisGeneratedAt: Date?

            enum CodingKeys: String, CodingKey {
                case userProfileId = "user_profile_id"
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
        }

        // Step 3: Save to database with image URL
        let itemForDB = ScannedItemForDB(
            userProfileId: userId,
            id: updatedItem.id,
            itemName: updatedItem.itemName,
            category: updatedItem.category,
            condition: updatedItem.condition,
            description: updatedItem.description,
            estimatedValue: updatedItem.estimatedValue,
            timestamp: updatedItem.timestamp,
            imageUrl: updatedItem.imageUrl,
            priceAnalysis: updatedItem.priceAnalysis,
            userCostBasis: updatedItem.userCostBasis,
            userNotes: updatedItem.userNotes,
            profitBreakdowns: updatedItem.profitBreakdowns,
            listingStatus: updatedItem.listingStatus,
            advancedAIAnalysis: updatedItem.advancedAIAnalysis,
            aiAnalysisGeneratedAt: updatedItem.aiAnalysisGeneratedAt
        )

        try await client
            .from("scanned_items")
            .insert(itemForDB)
            .execute()

        return updatedItem
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

        // Step 1: Delete image from storage if it exists
        if let imageUrl = item.imageUrl {
            try? await deleteImageFromStorage(imageUrl) // Use try? to not fail if image doesn't exist
        }

        // Step 2: Delete from database
        try await client
            .from("scanned_items")
            .delete()
            .eq("id", value: item.id.uuidString)
            .eq("user_profile_id", value: userId)
            .execute()
    }

    func updateScannedItem(_ item: ScannedItem, newImage: UIImage? = nil) async throws {
        guard let userId = currentUserProfileId else {
            throw SupabaseServiceError.unauthorized
        }

        var updatedItem = item

        // Handle image update if new image provided
        if let newImage = newImage {
            // Delete old image if it exists
            if let oldImageUrl = item.imageUrl {
                try? await deleteImageFromStorage(oldImageUrl)
            }

            // Upload new image
            let newImageUrl = try await uploadImageToStorage(newImage, itemId: item.id)
            updatedItem = ScannedItem(
                id: item.id,
                itemName: item.itemName,
                category: item.category,
                condition: item.condition,
                description: item.description,
                estimatedValue: item.estimatedValue,
                timestamp: item.timestamp,
                imageUrl: newImageUrl, // Updated with new URL
                priceAnalysis: item.priceAnalysis,
                userCostBasis: item.userCostBasis,
                userNotes: item.userNotes,
                profitBreakdowns: item.profitBreakdowns,
                listingStatus: item.listingStatus,
                advancedAIAnalysis: item.advancedAIAnalysis,
                aiAnalysisGeneratedAt: item.aiAnalysisGeneratedAt,
                storageLocation: item.storageLocation
            )
        }

        try await client
            .from("scanned_items")
            .update(updatedItem)
            .eq("id", value: item.id.uuidString)
            .eq("user_profile_id", value: userId)
            .execute()
    }

    func getCurrentUserID() -> UUID? {
        guard let userIdString = currentUserProfileId,
              let uuid = UUID(uuidString: userIdString) else {
            return nil
        }
        return uuid
    }

    /// Create user subscription (using your existing UserSubscription model)
    func createUserSubscription(_ subscription: UserSubscription) async throws {
        try await client
            .from("user_subscriptions")
            .insert(subscription)
            .execute()
    }

    /// Update user tokens count
    func updateUserTokens(count: Int) async throws {
        try await updateTokenCount(count)
    }

    /// Cancel active subscriptions for user
    func cancelActiveSubscriptions(for userId: String) async throws {
        struct SubscriptionUpdate: Codable {
            let status: String
            let updatedAt: Date

            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }

        let update = SubscriptionUpdate(
            status: "cancelled",
            updatedAt: Date()
        )

        try await client
            .from("user_subscriptions")
            .update(update)
            .eq("user_id", value: userId)
            .eq("status", value: "active")
            .execute()
    }

    /// Create token purchase record
    func createTokenPurchaseRecord(_ purchase: TokenPurchaseRecord) async throws {
        // Check if this transaction already exists
        let existing: [TokenPurchaseRecord] = try await client
            .from("token_purchases")
            .select()
            .eq("apple_transaction_id", value: purchase.appleTransactionId)
            .execute()
            .value

        // If it already exists, skip the insert
        guard existing.isEmpty else {
            print("⚠️ Purchase already recorded, skipping")
            return
        }

        // Otherwise, insert new record
        try await client
            .from("token_purchases")
            .insert(purchase)
            .execute()
    }

    // MARK: - User Stats Operations

    func fetchUserStats() async throws -> UserStats? {
        guard let userId = currentUserUUID else {
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
        guard let userId = currentUserUUID else {
            throw SupabaseServiceError.unauthorized
        }

        struct UserStatsForDB: Codable {
            let userProfileId: UUID
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

        let statsForDB = UserStatsForDB(
            userProfileId: userId,
            totalPotentialSavings: stats.totalPotentialSavings,
            favoriteMarketplace: stats.favoriteMarketplace,
            totalItemsScanned: stats.totalItemsScanned,
            averageProfit: stats.averageProfit,
            lastUpdated: stats.lastUpdated
        )

        // Specify the conflict resolution column for upsert
        try await client
            .from("user_stats")
            .upsert(statsForDB, onConflict: "user_profile_id")
            .execute()
    }

    func fetchCachedMarketTrends() async throws -> MarketTrends? {
        do {
            let response: MarketTrends = try await client
                .from("market_insights")
                .select()
                .order("timestamp", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value

            return response
        } catch {
            return nil
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

// MARK: - Custom Errors

enum SupabaseServiceError: LocalizedError {
    case userNotFound
    case invalidData
    case networkError
    case unauthorized
    case insufficientTokens
    case invalidImageData
    case unknown

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
        case .invalidImageData:
            return "Invalid image data"
        case .unknown:
            return "Unknown error"
        }
    }
}

extension SupabaseService: EdgeFunctionCalling {
    func invokeEdgeFunction(_ functionName: String, body: [String: Any]) async throws -> Data {
        // Convert [String: Any] to JSON Data
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        // Define a generic JSON response that matches what OpenAI returns
        struct OpenAIResponse: Codable {
            let choices: [Choice]?
            let error: String?

            struct Choice: Codable {
                let message: Message
            }

            struct Message: Codable {
                let content: String
            }
        }

        // Call the edge function and get typed response
        let response: OpenAIResponse = try await client.functions.invoke(
            functionName,
            options: FunctionInvokeOptions(body: jsonData)
        )

        // Convert back to Data for our protocol
        let responseData = try JSONEncoder().encode(response)
        return responseData
    }
}

extension SupabaseService {

    // MARK: - eBay OAuth Token Exchange

    func exchangeeBayOAuthCode(code: String, isProduction: Bool) async throws -> eBayTokenResponse {
        let body: [String: Any] = [
            "code": code,
            "isProduction": isProduction
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let response: eBayTokenResponse = try await client.functions.invoke(
            "exchange-ebay-oauth-code",
            options: FunctionInvokeOptions(body: jsonData)
        )

        return response
    }

    // MARK: - eBay Browse Token

    func geteBayBrowseToken(isProduction: Bool) async throws -> eBayAppTokenResponse {
        let body: [String: Any] = [
            "isProduction": isProduction
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let response: eBayAppTokenResponse = try await client.functions.invoke(
            "get-ebay-browse-token",
            options: FunctionInvokeOptions(body: jsonData)
        )

        return response
    }

    // MARK: - eBay Browse Search

    func searcheBayListings(searchKeywords: String, limit: Int = 50, isProduction: Bool) async throws -> eBayBrowseSearchResponse {
        let body: [String: Any] = [
            "searchKeywords": searchKeywords,
            "limit": limit,
            "isProduction": isProduction
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let response: eBayBrowseSearchResponse = try await client.functions.invoke(
            "ebay-browse-search",
            options: FunctionInvokeOptions(body: jsonData)
        )

        return response
    }

    // MARK: - eBay Create Listing

    func createeBayListing(
        userToken: String,
        title: String,
        description: String,
        categoryID: String,
        price: String,
        conditionID: String,
        itemSpecifics: String?,
        imageURL: String?,
        shippingCost: String,
        isProduction: Bool
    ) async throws -> eBayListingCreationResponse {
        var body: [String: Any] = [
            "userToken": userToken,
            "title": title,
            "description": description,
            "categoryID": categoryID,
            "price": price,
            "conditionID": conditionID,
            "shippingCost": shippingCost,
            "isProduction": isProduction
        ]

        if let itemSpecifics = itemSpecifics {
            body["itemSpecifics"] = itemSpecifics
        }

        if let imageURL = imageURL {
            body["imageURL"] = imageURL
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let response: eBayListingCreationResponse = try await client.functions.invoke(
            "create-ebay-listing",
            options: FunctionInvokeOptions(body: jsonData)
        )

        return response
    }
}

// MARK: - StockX Edge Function Extensions
extension SupabaseService {

    // MARK: - Authentication
    func exchangeStockXCode(
        code: String,
        redirectUri: String
    ) async throws -> StockXTokenResponse {
        let body: [String: Any] = [
            "code": code,
            "redirectUri": redirectUri,
            "grantType": "authorization_code"
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let response: StockXTokenResponse = try await client.functions.invoke(
            StockXConfig.exchangeTokenFunction,
            options: FunctionInvokeOptions(body: jsonData)
        )

        return response
    }

    func refreshStockXToken(
        refreshToken: String
    ) async throws -> StockXTokenResponse {
        let body: [String: Any] = [
            "refreshToken": refreshToken,
            "grantType": "refresh_token"
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let response: StockXTokenResponse = try await client.functions.invoke(
            StockXConfig.exchangeTokenFunction,
            options: FunctionInvokeOptions(body: jsonData)
        )

        return response
    }

    // MARK: - Search Products
    func searchStockXProducts(
        query: String,
        pageSize: Int = 20,
        pageNumber: Int = 1,
        accessToken: String
    ) async throws -> StockXSearchResponse {
        let body: [String: Any] = [
            "query": query,
            "pageSize": pageSize,
            "pageNumber": pageNumber,
            "accessToken": accessToken
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let response: StockXSearchResponse = try await client.functions.invoke(
            StockXConfig.searchProductsFunction,
            options: FunctionInvokeOptions(body: jsonData)
        )

        return response
    }

    // MARK: - Get Product Variants
    func getStockXVariants(
        productId: String,
        accessToken: String
    ) async throws -> [StockXVariant] {
        let body: [String: Any] = [
            "productId": productId,
            "accessToken": accessToken
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let variants: [StockXVariant] = try await client.functions.invoke(
            StockXConfig.getProductDetailsFunction,
            options: FunctionInvokeOptions(body: jsonData)
        )

        return variants
    }

    // MARK: - Get Market Data
    func getStockXMarketData(
        productId: String,
        variantId: String,
        currencyCode: String = "USD",
        country: String = "US",
        accessToken: String
    ) async throws -> StockXMarketData {
        let body: [String: Any] = [
            "productId": productId,
            "variantId": variantId,
            "currencyCode": currencyCode,
            "country": country,
            "accessToken": accessToken
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let marketData: StockXMarketData = try await client.functions.invoke(
            StockXConfig.getMarketDataFunction,
            options: FunctionInvokeOptions(body: jsonData)
        )

        return marketData
    }

    // MARK: - Place Ask
    func placeStockXAsk(
        request: StockXCreateAskRequest,
        accessToken: String
    ) async throws -> StockXCreateAskResponse {
        let encoder = JSONEncoder()
        let requestData = try encoder.encode(request)
        var requestDict = try JSONSerialization.jsonObject(with: requestData) as! [String: Any]

        requestDict["accessToken"] = accessToken

        let jsonData = try JSONSerialization.data(withJSONObject: requestDict)

        let response: StockXCreateAskResponse = try await client.functions.invoke(
            StockXConfig.placeAskFunction,
            options: FunctionInvokeOptions(body: jsonData)
        )

        return response
    }
}
