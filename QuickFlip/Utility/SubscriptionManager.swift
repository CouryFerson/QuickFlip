import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
class SubscriptionManager: ObservableObject {

    // MARK: - Published Properties
    @Published var subscriptions: [Product] = []
    @Published var consumables: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var currentTier: SubscriptionTier?
    @Published var userProfile: UserProfile?
    @Published var availableTiers: [SubscriptionTier] = []

    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let authManager: AuthManager
    private let storeKitManager: StoreKitManager
    private let supabaseService: SupabaseService
    private var cancellables = Set<AnyCancellable>()

    init(authManager: AuthManager, storeKitManager: StoreKitManager, supabaseService: SupabaseService) {
        self.authManager = authManager
        self.storeKitManager = storeKitManager
        self.supabaseService = supabaseService

        setupBindings()
    }

    // MARK: - Setup
    private func setupBindings() {
        storeKitManager.$subscriptions
            .assign(to: \.subscriptions, on: self)
            .store(in: &cancellables)

        storeKitManager.$consumables
            .assign(to: \.consumables, on: self)
            .store(in: &cancellables)

        storeKitManager.$purchasedSubscriptions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.refreshSubscriptionData() }
            }
            .store(in: &cancellables)

        storeKitManager.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Public Interface

    func initialize() async {
        isLoading = true

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.storeKitManager.requestProducts() }
            group.addTask { await self.loadSubscriptionData() }
        }

        isLoading = false
    }

    func purchaseSubscription(_ product: Product) async throws {
        isPurchasing = true
        errorMessage = nil

        defer { isPurchasing = false }

        do {
            guard let transaction = try await storeKitManager.purchase(product) else {
                return // User cancelled
            }

            let tierName = getTierName(from: product.id)
            try await processSubscriptionPurchase(transaction: transaction, tierName: tierName)
            await refreshSubscriptionData()
        } catch {
            errorMessage = "Subscription purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    func purchaseTokens(_ product: Product) async throws {
        isPurchasing = true
        errorMessage = nil

        defer { isPurchasing = false }

        do {
            guard let transaction = try await storeKitManager.purchase(product) else {
                return // User cancelled
            }

            let tokenCount = getTokenCount(from: product.id)
            try await processTokenPurchase(transaction: transaction, tokenCount: tokenCount)
            await refreshUserProfile()
            await authManager.refreshUserData()
        } catch {
            errorMessage = "Token purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await storeKitManager.restorePurchases()
            await refreshSubscriptionData()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            throw error
        }
    }

    func refreshSubscriptionData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadSubscriptionData() }
            group.addTask { await self.refreshUserProfile() }
        }
    }

    func canAccessFeature(_ feature: String) -> Bool {
        guard let currentTier = currentTier else { return false }
        return currentTier.features.contains(feature)
    }

    func requiresUpgradeFor(_ feature: String) -> Bool {
        return !canAccessFeature(feature)
    }

    // MARK: - Helper Properties

    var upgradePromptMessage: String {
        guard let currentTier = currentTier else {
            return "Upgrade to access premium features"
        }

        switch currentTier.tierName {
        case "free":
            return "Upgrade to Starter ($9.99/month) for more tokens and features"
        case "starter":
            return "Upgrade to Pro ($19.99/month) for unlimited features"
        default:
            return "Purchase more tokens to continue"
        }
    }

    var addTokensMessage: String {
        return "Purchase more tokens to continue"
    }

    var hasActiveSubscription: Bool {
        return !purchasedSubscriptions.isEmpty
    }

    var activeSubscriptionProduct: Product? {
        return purchasedSubscriptions.first
    }

    var canUpgradeFromCurrentTier: Bool {
        guard let currentTier = currentTier else { return true }
        return currentTier.tierName != "pro"
    }

    var hasStarterOrProAccess: Bool {
        guard let currentTier = currentTier else { return false }
        return currentTier.tierName == "starter" || currentTier.tierName == "pro"
    }

    func shouldShowUpgrade(for product: Product) -> Bool {
        guard let currentTier = currentTier else { return true }
        let productTier = getTierName(from: product.id)
        return tierPriority(productTier) > tierPriority(currentTier.tierName)
    }

    // MARK: - Public Product Configuration Methods

    func getTierColor(_ tierName: String) -> Color {
        return tierColor(tierName)
    }
}

// MARK: - Private Methods
private extension SubscriptionManager {

    func loadSubscriptionData() async {
        do {
            async let tiersRequest = supabaseService.getAllSubscriptionTiers()
            async let profileRequest = supabaseService.getUserProfile()
            async let currentTierRequest = supabaseService.getUserSubscriptionTier()

            availableTiers = try await tiersRequest
            userProfile = try await profileRequest
            currentTier = try await currentTierRequest

            // Default to free tier if none found
            if currentTier == nil {
                currentTier = availableTiers.first { $0.tierName == "free" }
            }

        } catch {
            errorMessage = "Failed to load subscription data: \(error.localizedDescription)"
        }
    }

    func refreshUserProfile() async {
        do {
            userProfile = try await supabaseService.getUserProfile()
            await authManager.refreshUserData()
        } catch {
            errorMessage = "Failed to refresh user profile: \(error.localizedDescription)"
        }
    }

    func processSubscriptionPurchase(transaction: StoreKit.Transaction, tierName: String) async throws {
        // Cancel existing subscriptions
        try await cancelExistingSubscriptions()

        // Create new subscription using your existing model
        let subscription = UserSubscription(
            id: UUID().uuidString,
            userId: try getCurrentUserID(),
            tierName: tierName,
            expiresAt: transaction.expirationDate,
            appleTransactionId: String(transaction.id),
            appleOriginalTransactionId: String(transaction.originalID),
            autoRenewEnabled: true,
            status: "active",
            createdAt: Date(),
            updatedAt: Date()
        )

        try await supabaseService.createUserSubscription(subscription)
        try await updateUserTokensForTier(tierName: tierName)
    }

    func processTokenPurchase(transaction: StoreKit.Transaction, tokenCount: Int) async throws {
        guard let userProfile = userProfile else {
            throw SubscriptionError.userNotFound
        }

        let newTokenCount = userProfile.tokens + tokenCount
        // Use your existing method
        _ = try await supabaseService.addTokens(tokenCount)

        // Create token purchase record
        let purchase = TokenPurchaseRecord(
            id: UUID().uuidString,
            userId: try getCurrentUserID(),
            tokenCount: tokenCount,
            appleTransactionId: String(transaction.id),
            createdAt: Date()
        )

        try await supabaseService.createTokenPurchaseRecord(purchase)
    }

    func cancelExistingSubscriptions() async throws {
        let userID = try getCurrentUserID()
        try await supabaseService.cancelActiveSubscriptions(for: userID)
    }

    func updateUserTokensForTier(tierName: String) async throws {
        guard let tier = availableTiers.first(where: { $0.tierName == tierName }) else {
            throw SubscriptionError.tierNotFound
        }

        guard let currentProfile = userProfile else {
            throw SubscriptionError.userNotFound
        }

        // Add the new tier's full monthly allocation to their current balance
        let newTokenCount = currentProfile.tokens + tier.tokensPerPeriod

        // Update with the combined total
        try await supabaseService.updateTokenCount(newTokenCount)
    }

    func getCurrentUserID() throws -> String {
        guard let userID = supabaseService.getCurrentUserID() else {
            throw SubscriptionError.userNotFound
        }
        return userID.uuidString
    }

    // MARK: - Product Configuration

    func getTierName(from productID: String) -> String {
        switch productID {
        case "com.fersonix.quikflip.starter_sub_monthly":
            return "starter"
        case "com.fersonix.quikflip.pro_sub_monthly":
            return "pro"
        default:
            return "free"
        }
    }

    func getTokenCount(from productID: String) -> Int {
        switch productID {
        case "com.fersonix.quikflip.tokens_100":
            return 100
        default:
            return 0
        }
    }

    func tierPriority(_ tierName: String) -> Int {
        switch tierName {
        case "free": return 0
        case "starter": return 1
        case "pro": return 2
        default: return 0
        }
    }

    func tierColor(_ tierName: String) -> Color {
        switch tierName.lowercased() {
        case "free": return .gray
        case "starter": return .blue
        case "pro": return .orange
        default: return .gray
        }
    }
}

// MARK: - Supporting Models

struct TokenPurchaseRecord: Codable {
    let id: String
    let userId: String
    let tokenCount: Int
    let appleTransactionId: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tokenCount = "token_count"
        case appleTransactionId = "apple_transaction_id"
        case createdAt = "created_at"
    }
}

// MARK: - Subscription Errors
enum SubscriptionError: LocalizedError {
    case userNotFound
    case insufficientTokens
    case tierNotFound
    case purchaseFailed(String)
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .insufficientTokens:
            return "You don't have enough tokens. Purchase more tokens or upgrade your subscription."
        case .tierNotFound:
            return "Subscription tier not found."
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .syncFailed(let message):
            return "Failed to sync with server: \(message)"
        }
    }
}
