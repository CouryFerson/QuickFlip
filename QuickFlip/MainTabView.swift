//
//  MainTabView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//


import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            CaptureView(appState: appState)
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Capture")
                }

            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
}
