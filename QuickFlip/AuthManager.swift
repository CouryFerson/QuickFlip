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
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false

    let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase

        // Check for existing session on init, and show we are in a loading state
        isLoading = true
        Task {
            await checkSession()
        }
    }

    // MARK: - Session Management

    func checkSession() async {
        isLoading = true

        do {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            let session = try await supabase.auth.session
            self.isAuthenticated = true
            self.currentUser = session.user
            self.isLoading = false
            print("Found existing session for: \(session.user.email ?? "unknown")")
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
            self.isLoading = false
        }
    }

    // MARK: - Apple Sign In

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

        } catch {
            throw error
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.auth.signOut()
        self.isAuthenticated = false
        self.currentUser = nil
    }

    // MARK: - Helper Properties

    var userEmail: String? {
        currentUser?.email
    }

    var userId: String? {
        currentUser?.id.uuidString
    }
}

// MARK: - Custom Errors

enum AuthError: LocalizedError {
    case invalidToken
    case signInFailed

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Unable to get valid identity token"
        case .signInFailed:
            return "Sign in process failed"
        }
    }
}
