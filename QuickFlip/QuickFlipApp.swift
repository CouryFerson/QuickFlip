//
//  QuickFlipApp.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI
import Supabase

@main
struct QuickFlipApp: App {
    @StateObject private var itemStorage: ItemStorageService
    @StateObject private var supabaseService: SupabaseService
    @StateObject private var authManager: AuthManager
    @StateObject private var subscriptionManager: SubscriptionManager

    init() {
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://caozetulkpyyuniwprtd.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhb3pldHVsa3B5eXVuaXdwcnRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2NjEyOTMsImV4cCI6MjA3MTIzNzI5M30.sdw4OMWXBl9-DrJX165M0Fz8NXBxSVJ6QQJb_qG11vM"
        )

        let authManager = AuthManager(supabase: client)
        let supabaseService = SupabaseService(client: client)

        _supabaseService = StateObject(wrappedValue: supabaseService)
        _authManager = StateObject(wrappedValue: authManager)
        _itemStorage = StateObject(wrappedValue: ItemStorageService(supabaseService: supabaseService))
        _subscriptionManager = StateObject(wrappedValue: SubscriptionManager(storeKitManager: StoreKitManager(), supabaseService: supabaseService))
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
                    .environmentObject(supabaseService)
                    .environmentObject(authManager)
                    .environmentObject(itemStorage)
                    .environmentObject(subscriptionManager)
                    .task {
                        await itemStorage.refreshData()
                    }
            }
        }
    }
}
