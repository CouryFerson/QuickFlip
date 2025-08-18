//
//  SettingsView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var itemStorage: ItemStorageService
    @State private var notificationsEnabled = true
    @State private var autoSaveEnabled = true
    @State private var selectedCurrency = "USD"
    @State private var selectedTheme = "System"
    @State private var showingDeleteAlert = false
    @State private var showingExportSheet = false
    @State private var showingAbout = false

    let currencies = ["USD", "EUR", "GBP", "CAD", "AUD"]
    let themes = ["System", "Light", "Dark"]

    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("John Flipper")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("john.flipper@example.com")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("Pro Member")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }

                        Spacer()

                        Button("Edit") {
                            // TODO: Edit profile
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }

                // Account Settings
                Section("Account") {
                    NavigationLink(destination: SubscriptionView()) {
                        Label("Subscription", systemImage: "crown.fill")
                            .foregroundColor(.orange)
                    }

                    NavigationLink(destination: Text("Profile Settings")) {
                        Label("Profile Settings", systemImage: "person.circle")
                    }

                    NavigationLink(destination: Text("Privacy")) {
                        Label("Privacy & Security", systemImage: "lock.shield")
                    }
                }

                // App Preferences
                Section("Preferences") {
                    HStack {
                        Label("Currency", systemImage: "dollarsign.circle")
                        Spacer()
                        Picker("Currency", selection: $selectedCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }

                    HStack {
                        Label("Theme", systemImage: "paintbrush")
                        Spacer()
                        Picker("Theme", selection: $selectedTheme) {
                            ForEach(themes, id: \.self) { theme in
                                Text(theme).tag(theme)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }

                    Toggle(isOn: $notificationsEnabled) {
                        Label("Push Notifications", systemImage: "bell")
                    }

                    Toggle(isOn: $autoSaveEnabled) {
                        Label("Auto-save Scans", systemImage: "square.and.arrow.down")
                    }
                }

                // Data & Storage
                Section("Data & Storage") {
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink(destination: Text("Storage Usage: 2.3 MB")) {
                        Label("Storage Usage", systemImage: "internaldrive")
                    }

                    NavigationLink(destination: BackupSettingsView()) {
                        Label("Backup Settings", systemImage: "icloud")
                    }

                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }

                // Analysis Settings
                Section("Analysis Settings") {
                    NavigationLink(destination: Text("AI Model: GPT-4o")) {
                        Label("AI Model", systemImage: "brain.head.profile")
                    }

                    NavigationLink(destination: MarketplacePreferencesView()) {
                        Label("Marketplace Preferences", systemImage: "storefront")
                    }

                    NavigationLink(destination: Text("Fee Calculator Settings")) {
                        Label("Fee Calculator", systemImage: "calculator")
                    }
                }

                // Support & Info
                Section("Support & Info") {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }

                    Button {
                        contactSupport()
                    } label: {
                        Label("Contact Support", systemImage: "envelope")
                    }

                    Button {
                        showingAbout = true
                    } label: {
                        Label("About QuickFlip", systemImage: "info.circle")
                    }

                    NavigationLink(destination: Text("Privacy Policy")) {
                        Label("Privacy Policy", systemImage: "doc.text")
                    }

                    NavigationLink(destination: Text("Terms of Service")) {
                        Label("Terms of Service", systemImage: "doc.plaintext")
                    }
                }

                // App Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 42)")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Items Scanned")
                        Spacer()
                        Text("\(itemStorage.totalItemCount)")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
                .environmentObject(itemStorage)
        }
        .alert("Clear All Data", isPresented: $showingDeleteAlert) {
            Button("Clear", role: .destructive) {
                itemStorage.clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your scanned items and analysis data. This action cannot be undone.")
        }
        .alert("About QuickFlip", isPresented: $showingAbout) {
            Button("OK") { }
        } message: {
            Text("QuickFlip v1.0.0\n\nThe ultimate marketplace analysis tool for resellers. Scan items, get AI-powered price analysis, and maximize your profits.\n\nMade with ❤️ for the flipping community.")
        }
    }

    private func contactSupport() {
        if let url = URL(string: "mailto:support@quickflip.app?subject=QuickFlip Support") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Subscription View
struct SubscriptionView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("QuickFlip Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Unlock unlimited scans and advanced features")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Current Plan
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Plan")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pro Monthly")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("$9.99/month")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Text("Active")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pro Features")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        FeatureRow(icon: "infinity", title: "Unlimited Scans", description: "No daily limits")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Price Tracking", description: "Track price changes over time")
                        FeatureRow(icon: "bell.badge", title: "Price Alerts", description: "Get notified when items increase in value")
                        FeatureRow(icon: "square.grid.3x3", title: "Bulk Analysis", description: "Scan multiple items at once")
                        FeatureRow(icon: "icloud.and.arrow.up", title: "Cloud Sync", description: "Sync data across devices")
                        FeatureRow(icon: "envelope", title: "Priority Support", description: "24/7 customer support")
                    }
                    .padding(.horizontal)
                }

                // Manage Subscription
                VStack(spacing: 12) {
                    Button("Manage Subscription") {
                        // Open App Store subscriptions
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)

                    Button("Cancel Subscription") {
                        // Handle cancellation
                    }
                    .foregroundColor(.red)
                }
                .padding(.horizontal)

                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Backup Settings View
struct BackupSettingsView: View {
    @State private var iCloudEnabled = true
    @State private var autoBackup = true
    @State private var lastBackup = "2 hours ago"

    var body: some View {
        List {
            Section("iCloud Backup") {
                Toggle("Enable iCloud Sync", isOn: $iCloudEnabled)

                Toggle("Automatic Backup", isOn: $autoBackup)

                HStack {
                    Text("Last Backup")
                    Spacer()
                    Text(lastBackup)
                        .foregroundColor(.gray)
                }

                Button("Backup Now") {
                    // Trigger manual backup
                }
                .disabled(!iCloudEnabled)
            }

            Section("Backup Settings") {
                NavigationLink("What's Backed Up", destination: Text("• Scanned items\n• Analysis results\n• User preferences\n• App settings"))

                NavigationLink("Restore from Backup", destination: Text("Restore Settings"))
            }
        }
        .navigationTitle("Backup Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Marketplace Preferences View
struct MarketplacePreferencesView: View {
    @State private var enabledMarketplaces: Set<String> = ["eBay", "StockX", "Mercari", "Facebook"]
    @State private var defaultMarketplace = "eBay"
    @State private var showPriceAnalysis = true

    let allMarketplaces = ["eBay", "StockX", "Mercari", "Facebook", "Amazon", "Etsy", "Poshmark", "Depop"]

    var body: some View {
        List {
            Section("Enabled Marketplaces") {
                ForEach(allMarketplaces, id: \.self) { marketplace in
                    Toggle(marketplace, isOn: Binding(
                        get: { enabledMarketplaces.contains(marketplace) },
                        set: { isEnabled in
                            if isEnabled {
                                enabledMarketplaces.insert(marketplace)
                            } else {
                                enabledMarketplaces.remove(marketplace)
                            }
                        }
                    ))
                }
            }

            Section("Default Marketplace") {
                Picker("Default", selection: $defaultMarketplace) {
                    ForEach(Array(enabledMarketplaces).sorted(), id: \.self) { marketplace in
                        Text(marketplace).tag(marketplace)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Section("Analysis Preferences") {
                Toggle("Show Price Analysis", isOn: $showPriceAnalysis)

                NavigationLink("Fee Calculator Settings", destination: Text("Fee Settings"))
            }
        }
        .navigationTitle("Marketplace Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ItemStorageService())
    }
}
