//
//  MainTabView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//


import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @EnvironmentObject private var itemStorage: ItemStorageService

    var body: some View {
        TabView {
            HomeCoordinatorView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            CaptureCoordinatorView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Capture")
                }

            HistoryCoordinator()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }

            SettingsCoordinatorView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
}
