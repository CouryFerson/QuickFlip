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
    @StateObject private var analysisService: ImageAnalysisService
    @StateObject private var versionChecker = AppVersionChecker()
    @StateObject private var tutorialManager = TutorialManager()

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
        _subscriptionManager = StateObject(wrappedValue: SubscriptionManager(authManager: authManager, storeKitManager: StoreKitManager(), supabaseService: supabaseService))
        _analysisService = StateObject(wrappedValue: ImageAnalysisService(authManager: authManager, supabaseService: supabaseService))
        ImageCacheManager.shared.configure(with: supabaseService)
    }

    var body: some Scene {
        WindowGroup {
            if versionChecker.needsForceUpdate {
                ForceUpdateView(message: versionChecker.updateMessage)
            } else if authManager.isLoading {
                LoadingView()
            } else if !authManager.isAuthenticated {
                AppleSignInView(authManager: authManager, onSignInComplete: {})
            } else {
                ZStack {
                    mainTabView

                    if !tutorialManager.hasSeenTutorial {
                        TutorialView { }
                    }
                }
            }
        }
    }
}

private extension QuickFlipApp {
    private var mainTabView: some View {
        MainTabView()
            .environmentObject(supabaseService)
            .environmentObject(authManager)
            .environmentObject(itemStorage)
            .environmentObject(subscriptionManager)
            .environmentObject(analysisService)
            .environmentObject(versionChecker) // Add this so views can check for optional updates
            .task {
                await versionChecker.checkVersion(supabaseService: supabaseService)
                async let fetchUserData: () = itemStorage.fetchScannedItems()
                async let fetchScannedItems: () = fetchScannedItems()
                _ = await [fetchUserData, fetchScannedItems]
            }
    }

    private func fetchScannedItems() async {
        do {
            let items = try await supabaseService.fetchUserScannedItems()
            await ImageCacheManager.shared.preloadImages(for: items)
        } catch {
            print("failed to fetch images on startup")
        }
    }
}
