//
//  QuickFlipApp.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

@main
struct QuickFlipApp: App {
    @StateObject private var itemStorage = ItemStorageService()
    @StateObject private var supabaseService: SupabaseService
    @StateObject private var authManager: AuthManager

    init() {
        let supabaseService = SupabaseService()

        _supabaseService = StateObject(wrappedValue: supabaseService)
        _authManager = StateObject(wrappedValue: AuthManager(supabase: supabaseService.client))
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isLoading {
                // Show loading spinner while checking session
                LoadingView()
            } else if !authManager.isAuthenticated {
                // Show sign in only after we've confirmed no session
                AppleSignInView(authManager: authManager, onSignInComplete: {})
            } else {
                // User is authenticated
                MainTabView()
                    .environmentObject(itemStorage)
            }
        }
    }
}
