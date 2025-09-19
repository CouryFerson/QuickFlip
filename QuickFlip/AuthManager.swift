//
//  AuthManager.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/20/25.
//

import Foundation
import Supabase
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    // MARK: - Authentication State
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false

    // MARK: - User Data State
    @Published var userProfile: UserProfile?
    @Published var userSubscription: UserSubscription?
    @Published var subscriptionTier: SubscriptionTier?
    @Published var availableSubscriptionTiers: [SubscriptionTier] = []
    @Published var errorMessage: String?

    // MARK: - Services
    private let supabase: SupabaseClient
    private let supabaseService: SupabaseService

    init(supabase: SupabaseClient) {
        self.supabase = supabase
        self.supabaseService = SupabaseService(client: supabase)

        // Check for existing session on init
        isLoading = true
        Task {
            await checkSession()
        }
    }

    // MARK: - Authentication Methods

    func checkSession() async {
        isLoading = true
        clearError()

        do {
            let session = try await supabase.auth.session
            isAuthenticated = true
            currentUser = session.user

            print("Found existing session for: \(session.user.email ?? "unknown")")

            // Load user data
            await loadUserData()

        } catch {
            isAuthenticated = false
            currentUser = nil
            clearUserData()
            print("No existing session found")
        }

        isLoading = false
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidToken
        }

        isLoading = true
        clearError()

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityTokenString
                )
            )

            isAuthenticated = true
            currentUser = session.user

            print("Successfully signed in with Apple: \(session.user.email ?? "No email")")

            // Load user data
            await loadUserData()

        } catch {
            setError("Sign in failed: \(error.localizedDescription)")
            throw error
        }

        isLoading = false
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        isAuthenticated = false
        currentUser = nil
        clearUserData()
        print("User signed out")
    }

    // MARK: - User Data Loading

    func loadUserData() async {
        clearError()

        do {
            // Load profile
            userProfile = try await supabaseService.getUserProfile()

            // Load subscription
            userSubscription = try await supabaseService.getUserSubscription()

            // If no subscription exists, create a free one
            if userSubscription == nil {
                userSubscription = try await supabaseService.createSubscription(tierName: "free")
            }

            // Load tier details
            if let subscription = userSubscription {
                subscriptionTier = try await supabaseService.getSubscriptionTier(named: subscription.tierName)
            }

            // Load available tiers
            availableSubscriptionTiers = try await supabaseService.getAllSubscriptionTiers()

            print("Loaded user data: \(currentTierName) with \(tokenCount) tokens")

        } catch {
            setError("Failed to load user data: \(error.localizedDescription)")
            print("Failed to load user data: \(error)")
        }
    }

    func refreshUserData() async {
        await loadUserData()
    }

    // MARK: - Token Management

    var tokenCount: Int {
        userProfile?.tokens ?? 0
    }

    func purchaseTokens(_ amount: Int) async throws -> Int {
        let newCount = try await supabaseService.addTokens(amount)

        // Update local profile
        if let profile = userProfile {
            userProfile = UserProfile(
                id: profile.id,
                tokens: newCount,
                displayName: profile.displayName
            )
        }

        print("Purchased \(amount) tokens, new total: \(newCount)")
        return newCount
    }

    func refillMonthlyTokens() async throws -> Int {
        let newCount = try await supabaseService.refillMonthlyTokens()

        // Update local profile
        if let profile = userProfile {
            userProfile = UserProfile(
                id: profile.id,
                tokens: newCount,
                displayName: profile.displayName
            )
        }

        print("Monthly refill completed, new total: \(newCount)")
        return newCount
    }

    // MARK: - Subscription Management

    var currentTierName: String {
        userSubscription?.tierName.capitalized ?? "Free"
    }

    var subscriptionExpiresAt: Date? {
        userSubscription?.expiresAt
    }

    var isSubscriptionExpired: Bool {
        userSubscription?.isExpired ?? false
    }

    var autoRenewEnabled: Bool {
        userSubscription?.autoRenewEnabled ?? false
    }

    func hasFeature(_ feature: String) -> Bool {
        guard let tier = subscriptionTier else { return false }
        return tier.features.contains(feature)
    }

    func updateUserDisplayName(_ name: String) async throws {
        try await supabaseService.updateUserDisplayName(name)
    }

    func upgradeToTier(_ tierName: String) async throws {
        let (subscription, newTokenCount) = try await supabaseService.upgradeSubscription(to: tierName)

        // Update local state
        userSubscription = subscription
        if let profile = userProfile {
            userProfile = UserProfile(
                id: profile.id,
                tokens: newTokenCount,
                displayName: profile.displayName
            )
        }

        // Refresh tier details
        subscriptionTier = try await supabaseService.getSubscriptionTier(named: tierName)

        print("Upgraded to \(tierName) with \(newTokenCount) tokens")
    }

    func getAvailableUpgrades() -> [SubscriptionTier] {
        guard let currentTier = subscriptionTier else {
            return availableSubscriptionTiers.filter { $0.tierName != "free" }
        }

        return availableSubscriptionTiers.filter { tier in
            tier.tokensPerPeriod > currentTier.tokensPerPeriod
        }
    }

    // MARK: - Computed Properties

    var userEmail: String? {
        return currentUser?.email
    }

    var userId: String? {
        return currentUser?.id.uuidString
    }

    var userName: String? {
        return userProfile?.displayName
    }

    var isDataLoaded: Bool {
        userProfile != nil && userSubscription != nil && subscriptionTier != nil
    }

    var tokenUsagePercentage: Double {
        guard let tier = subscriptionTier, tier.tokensPerPeriod > 0 else { return 0.0 }
        return Double(tokenCount) / Double(tier.tokensPerPeriod)
    }

    var hasError: Bool {
        errorMessage != nil
    }

    // MARK: - Private Methods

    private func clearUserData() {
        userProfile = nil
        userSubscription = nil
        subscriptionTier = nil
        availableSubscriptionTiers = []
        errorMessage = nil
    }

    private func setError(_ message: String) {
        errorMessage = message
    }

    private func clearError() {
        errorMessage = nil
    }
}


// MARK: - AuthManager Extension
extension AuthManager: @preconcurrency TokenManaging {
    func hasTokens() -> Bool {
        return tokenCount > 0
    }
    
    func consumeTokens(_ amount: Int) async throws -> Int {
        guard tokenCount >= amount else {
            throw AuthError.insufficientTokens
        }

        let newCount = try await supabaseService.consumeTokens(amount)

        // Update local profile
        if let profile = userProfile {
            userProfile = UserProfile(
                id: profile.id,
                tokens: newCount,
                displayName: profile.displayName
            )
        }

        return newCount
    }

    // You already have consumeToken() for single token consumption
}

// MARK: - Custom Errors

enum AuthError: LocalizedError {
    case invalidToken
    case signInFailed
    case insufficientTokens
    case userNotFound
    case subscriptionError

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid authentication token"
        case .signInFailed:
            return "Sign in process failed"
        case .insufficientTokens:
            return "Not enough tokens to complete this request"
        case .userNotFound:
            return "User profile not found"
        case .subscriptionError:
            return "Subscription management error"
        }
    }
}
