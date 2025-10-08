//
//  StockXAuthService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/7/25.
//

import Foundation
import UIKit

// MARK: - StockX Authentication Service
class StockXAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var refreshToken: String?
    @Published var userEmail: String?

    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "StockXAccessToken"
    private let refreshTokenKey = "StockXRefreshToken"
    private let tokenExpiryKey = "StockXTokenExpiry"
    private let userEmailKey = "StockXUserEmail"

    private let supabaseService: SupabaseService
    private let debugMode = true

    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
        loadStoredToken()
    }

    // MARK: - OAuth Flow

    func startAuthentication() {
        let state = UUID().uuidString

        var components = URLComponents(string: StockXConfig.authURL)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: StockXConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: StockXConfig.redirectURI),
            URLQueryItem(name: "scope", value: StockXConfig.scope),
            URLQueryItem(name: "audience", value: StockXConfig.audience),
            URLQueryItem(name: "state", value: state)
        ]

        if let url = components.url {
            if debugMode {
                print("🔐 Opening StockX OAuth: \(url.absoluteString)")
            }
            UIApplication.shared.open(url)
        } else {
            if debugMode {
                print("❌ Failed to create OAuth URL")
            }
        }
    }

    func handleCallback(url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            if debugMode {
                print("❌ Invalid callback URL")
            }
            return
        }

        // Extract authorization code
        if let code = queryItems.first(where: { $0.name == "code" })?.value {
            await exchangeCodeForToken(code: code)
        } else if let error = queryItems.first(where: { $0.name == "error" })?.value {
            if debugMode {
                print("❌ StockX OAuth error: \(error)")
            }
        }
    }

    func exchangeCodeForToken(code: String) async {
        if debugMode {
            print("🔄 Exchanging authorization code for tokens...")
        }

        do {
            let response: StockXTokenResponse = try await supabaseService.exchangeStockXCode(
                code: code,
                redirectUri: StockXConfig.redirectURI
            )

            await MainActor.run {
                self.accessToken = response.accessToken
                self.refreshToken = response.refreshToken
                self.isAuthenticated = true

                // Store tokens
                userDefaults.set(response.accessToken, forKey: accessTokenKey)
                if let refreshToken = response.refreshToken {
                    userDefaults.set(refreshToken, forKey: refreshTokenKey)
                }

                // Calculate and store expiry (12 hours from now)
                let expiryDate = Date().addingTimeInterval(12 * 60 * 60)
                userDefaults.set(expiryDate, forKey: tokenExpiryKey)
            }

            if debugMode {
                print("✅ Successfully authenticated with StockX!")
            }

        } catch {
            if debugMode {
                print("❌ Token exchange failed: \(error)")
            }
        }
    }

    // MARK: - Token Refresh
    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw StockXAuthError.noRefreshToken
        }

        if debugMode {
            print("🔄 Refreshing StockX access token...")
        }

        do {
            let response: StockXTokenResponse = try await supabaseService.refreshStockXToken(
                refreshToken: refreshToken
            )

            await MainActor.run {
                self.accessToken = response.accessToken
                // Note: refresh_token is NOT returned on refresh, keep existing one

                // Update stored token
                userDefaults.set(response.accessToken, forKey: accessTokenKey)

                // Update expiry
                let expiryDate = Date().addingTimeInterval(12 * 60 * 60)
                userDefaults.set(expiryDate, forKey: tokenExpiryKey)
            }

            if debugMode {
                print("✅ Access token refreshed")
            }

        } catch {
            if debugMode {
                print("❌ Token refresh failed: \(error)")
            }
            throw error
        }
    }

    // MARK: - Token Management
    private func loadStoredToken() {
        guard let token = userDefaults.string(forKey: accessTokenKey),
              let expiryDate = userDefaults.object(forKey: tokenExpiryKey) as? Date else {
            return
        }

        // Check if token is expired
        if expiryDate < Date() {
            if debugMode {
                print("⚠️ Stored token expired")
            }
            // Try to refresh
            Task {
                try? await refreshAccessToken()
            }
            return
        }

        self.accessToken = token
        self.refreshToken = userDefaults.string(forKey: refreshTokenKey)
        self.userEmail = userDefaults.string(forKey: userEmailKey)
        self.isAuthenticated = true

        if debugMode {
            print("✅ Loaded stored StockX token")
        }
    }

    func signOut() {
        accessToken = nil
        refreshToken = nil
        userEmail = nil
        isAuthenticated = false

        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
        userDefaults.removeObject(forKey: tokenExpiryKey)
        userDefaults.removeObject(forKey: userEmailKey)

        if debugMode {
            print("👋 Signed out of StockX")
        }
    }

    // MARK: - Get Valid Token
    func getValidAccessToken() async throws -> String {
        // Check if we have a token and it's not expired
        if let token = accessToken,
           let expiryDate = userDefaults.object(forKey: tokenExpiryKey) as? Date,
           expiryDate > Date() {
            return token
        }

        // Token expired, try to refresh
        try await refreshAccessToken()

        guard let token = accessToken else {
            throw StockXAuthError.notAuthenticated
        }

        return token
    }
}

// MARK: - Token Response Model
struct StockXTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let tokenType: String
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

// MARK: - Auth Errors
enum StockXAuthError: Error, LocalizedError {
    case notAuthenticated
    case noRefreshToken
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to StockX first"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenExpired:
            return "StockX session expired. Please sign in again"
        }
    }
}
