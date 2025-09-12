//
//  MainTabView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//


import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @StateObject private var appRouter = AppRouter()
    @EnvironmentObject private var itemStorage: ItemStorageService

    var body: some View {
        TabView(selection: $appRouter.selectedTab) {
            HomeCoordinatorView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(AppRouter.Tab.home.rawValue)

            CaptureCoordinatorView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Capture")
                }
                .tag(AppRouter.Tab.capture.rawValue)

            HistoryCoordinator()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(AppRouter.Tab.history.rawValue)

            SettingsCoordinatorView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(AppRouter.Tab.settings.rawValue)
        }
        .environmentObject(appRouter)
        .accentColor(.blue)
    }
}


import SwiftUI

class AppRouter: ObservableObject {
    @Published var selectedTab: Int = 0

    enum Tab: Int, CaseIterable {
        case home
        case capture
        case history
        case settings
    }

    func navigateToHome() {
        selectedTab = Tab.home.rawValue
    }

    func navigateToCapture() {
        selectedTab = Tab.capture.rawValue
    }

    func navigateToHistory() {
        selectedTab = Tab.history.rawValue
    }

    func navigateToSettings() {
        selectedTab = Tab.settings.rawValue
    }
}
