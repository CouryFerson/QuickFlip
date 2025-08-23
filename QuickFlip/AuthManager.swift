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

    // MARK: - User Profile & Subscription State
    @Published var userProfile: UserProfile?
    @Published var subscriptionTier: SubscriptionTier?
    @Published var availableSubscriptionTiers: [SubscriptionTier] = []
    @Published var tokenCount: Int = 0
    @Published var profileError: String?

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

        do {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay for UX
            let session = try await supabase.auth.session
            self.isAuthenticated = true
            self.currentUser = session.user

            print("Found existing session for: \(session.user.email ?? "unknown")")

            // Load user profile and subscription data
            await loadUserProfileData()

        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
            self.clearUserData()
        }

        isLoading = false
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidToken
        }

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityTokenString
                )
            )

            self.isAuthenticated = true
            self.currentUser = session.user

            print("Successfully signed in with Apple: \(session.user.email ?? "No email")")

            // Load user profile and subscription data
            await loadUserProfileData()

        } catch {
            throw error
        }
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        self.isAuthenticated = false
        self.currentUser = nil
        self.clearUserData()
    }

    // MARK: - User Profile Methods

    func loadUserProfileData() async {
        profileError = nil

        do {
            // Load all subscription tiers
            availableSubscriptionTiers = try await supabaseService.getAllSubscriptionTiers()

            // Load user profile
            userProfile = try await supabaseService.getUserProfile()
            tokenCount = userProfile?.tokens ?? 0

            // Load current subscription tier
            if let profile = userProfile {
                subscriptionTier = try await supabaseService.getSubscriptionTier(named: profile.subscriptionTier)
            }

            print("Loaded user profile: \(userProfile?.subscriptionTier ?? "unknown") with \(tokenCount) tokens")

        } catch {
            profileError = "Failed to load profile: \(error.localizedDescription)"
            print("Failed to load user profile: \(error)")
        }
    }

    func refreshProfile() async {
        await loadUserProfileData()
    }

    // MARK: - Subscription Management

    func hasFeature(_ feature: String) -> Bool {
        guard let tier = subscriptionTier else { return false }
        return tier.features.contains(feature)
    }

    func canMakeRequest() -> Bool {
        return tokenCount > 0
    }

    func consumeToken() async throws -> Int {
        guard canMakeRequest() else {
            throw AuthError.insufficientTokens
        }

        let newTokenCount = try await supabaseService.consumeToken()
        self.tokenCount = newTokenCount

        // Update local profile using convenience method
        if let profile = userProfile {
            self.userProfile = profile.withUpdatedTokens(newTokenCount)
        }

        return newTokenCount
    }

    func upgradeToTier(_ tierName: String) async throws {
        let newTokenCount = try await supabaseService.setTokensForTier(tierName)

        // Refresh user data
        await loadUserProfileData()

        print("Upgraded to \(tierName) with \(newTokenCount) tokens")
    }

    func refillTokens() async throws -> Int {
        let newTokenCount = try await supabaseService.refillTokens()
        self.tokenCount = newTokenCount

        // Update local profile using convenience method
        if let profile = userProfile {
            self.userProfile = profile.withUpdatedTokens(newTokenCount)
        }

        return newTokenCount
    }

    func getTierUpgradeOptions() -> [SubscriptionTier] {
        guard let currentTier = subscriptionTier else {
            return availableSubscriptionTiers.filter { $0.tierName != "free" }
        }

        return availableSubscriptionTiers.filter { tier in
            tier.tokensPerPeriod > currentTier.tokensPerPeriod
        }
    }

    // MARK: - Helper Properties

    var userEmail: String? {
        currentUser?.email
    }

    var userId: String? {
        currentUser?.id.uuidString
    }

    var currentTierName: String {
        subscriptionTier?.tierName.capitalized ?? "Free"
    }

    var isSubscriptionLoaded: Bool {
        subscriptionTier != nil
    }

    var tokenPercentageRemaining: Double {
        guard let tier = subscriptionTier, tier.tokensPerPeriod > 0 else { return 0.0 }
        return Double(tokenCount) / Double(tier.tokensPerPeriod)
    }

    // MARK: - Private Methods

    private func clearUserData() {
        userProfile = nil
        subscriptionTier = nil
        availableSubscriptionTiers = []
        tokenCount = 0
        profileError = nil
    }
}

// MARK: - Custom Errors

enum AuthError: LocalizedError {
    case invalidToken
    case signInFailed
    case insufficientTokens

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Unable to get valid identity token"
        case .signInFailed:
            return "Sign in process failed"
        case .insufficientTokens:
            return "Insufficient tokens to complete this request"
        }
    }
}
