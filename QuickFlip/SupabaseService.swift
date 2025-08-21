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

    let client = SupabaseClient(
        supabaseURL: URL(string: "https://caozetulkpyyuniwprtd.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhb3pldHVsa3B5eXVuaXdwcnRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2NjEyOTMsImV4cCI6MjA3MTIzNzI5M30.sdw4OMWXBl9-DrJX165M0Fz8NXBxSVJ6QQJb_qG11vM"
    )

    // MARK: - User Profile Operations

    func getUserProfile(userId: String) async throws -> UserProfile {
        let response: UserProfile = try await client
            .from("user_profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return response
    }

    func updateScanCount(userId: String, newCount: Int) async throws {
        try await client
            .from("user_profiles")
            .update(["total_items_scanned": newCount])
            .eq("id", value: userId)
            .execute()
    }

    func incrementScanCount(userId: String) async throws {
        // Get current count first
        let profile = try await getUserProfile(userId: userId)
        let newCount = profile.totalItemsScanned + 1

        try await updateScanCount(userId: userId, newCount: newCount)
    }

    func updateSubscriptionTier(userId: String, tier: String) async throws {
        try await client
            .from("user_profiles")
            .update(["subscription_tier": tier])
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Future Methods (placeholders for QuickFlip features)

    func saveItemScan(userId: String, imageData: Data, predictions: [String: Any]) async throws {
        // TODO: Save scanned item data
        print("Saving item scan for user: \(userId)")
    }

    func getMarketplaceRecommendations(itemData: [String: Any]) async throws -> [MarketplaceRecommendation] {
        // TODO: Get marketplace recommendations
        print("Getting marketplace recommendations")
        return []
    }

    func uploadToMarketplace(itemId: String, marketplace: String) async throws {
        // TODO: Upload item to specific marketplace
        print("Uploading to \(marketplace)")
    }

    // MARK: - Helper Methods

    func checkConnection() async throws -> Bool {
        // Simple health check
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

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User profile not found"
        case .invalidData:
            return "Invalid data format"
        case .networkError:
            return "Network connection error"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}
