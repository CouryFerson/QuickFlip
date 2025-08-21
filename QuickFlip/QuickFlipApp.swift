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
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if !authManager.isAuthenticated {
                AppleSignInView(authManager: authManager, onSignInComplete: {})
            } else {
                MainTabView()
                    .environmentObject(itemStorage)
            }
        }
    }
}
