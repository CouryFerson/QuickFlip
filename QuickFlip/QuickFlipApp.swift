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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(itemStorage)
        }
    }
}
