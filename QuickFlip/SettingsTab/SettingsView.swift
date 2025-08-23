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
                Task {
                    await itemStorage.clearAllData()
                }
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
import SwiftUI

// MARK: - Subscription View
struct SubscriptionView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var authManager: AuthManager

    @State private var availableTiers: [SubscriptionTier] = []
    @State private var currentTier: SubscriptionTier?
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                if isLoading {
                    ProgressView("Loading subscription details...")
                        .frame(height: 100)
                } else if let errorMessage = errorMessage {
                    errorSection(errorMessage)
                } else {
                    currentPlanSection
                    tokensSection
                    featuresSection
                    upgradeSection
                    manageSubscriptionSection
                }

                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSubscriptionData()
        }
    }
}

// MARK: - View Components
private extension SubscriptionView {

    @ViewBuilder
    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("QuickFlip Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Unlock advanced features and more tokens")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    @ViewBuilder
    var currentPlanSection: some View {
        if let currentTier = currentTier {
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Plan")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentTier.tierName.capitalized)
                            .font(.title3)
                            .fontWeight(.semibold)

                        if currentTier.priceMonthly ?? 0 > 0 {
                            Text("$\(currentTier.priceMonthly!, specifier: "%.2f")/month")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } else {
                            Text("Free")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    Text("Active")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(currentTier.tierName == "free" ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .background(tierColor(for: currentTier.tierName).opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    var tokensSection: some View {
        if let userProfile = userProfile, let currentTier = currentTier {
            VStack(alignment: .leading, spacing: 12) {
                Text("Usage")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tokens Remaining")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text("\(userProfile.tokens)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(tokenColor(for: userProfile.tokens, max: currentTier.tokensPerPeriod))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Monthly Limit")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text("\(currentTier.tokensPerPeriod)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                // Progress bar
                ProgressView(value: Double(userProfile.tokens), total: Double(currentTier.tokensPerPeriod))
                    .progressViewStyle(LinearProgressViewStyle(tint: tokenColor(for: userProfile.tokens, max: currentTier.tokensPerPeriod)))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    var featuresSection: some View {
        if let currentTier = currentTier {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(currentTier.tierName.capitalized) Features")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(currentTier.features, id: \.self) { feature in
                        FeatureRow(
                            icon: iconForFeature(feature),
                            title: titleForFeature(feature),
                            description: descriptionForFeature(feature)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    var upgradeSection: some View {
        if let currentTier = currentTier, currentTier.tierName != "pro" {
            let upgradeTiers = availableTiers.filter { tier in
                tier.tokensPerPeriod > currentTier.tokensPerPeriod
            }

            if !upgradeTiers.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Upgrade Options")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(upgradeTiers, id: \.id) { tier in
                        UpgradeTierCard(tier: tier) {
                            await upgradeTo(tier: tier)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    var manageSubscriptionSection: some View {
        if let currentTier = currentTier, currentTier.priceMonthly ?? 0 > 0 {
            VStack(spacing: 12) {
                Button("Manage Subscription") {
                    // Open App Store subscriptions or your billing portal
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)

                Button("Cancel Subscription") {
                    // Handle cancellation - could show confirmation dialog
                }
                .foregroundColor(.red)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func errorSection(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Error Loading Subscription")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await loadSubscriptionData() }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Helper Functions
private extension SubscriptionView {

    func loadSubscriptionData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let tiersRequest = supabaseService.getAllSubscriptionTiers()
            async let profileRequest = supabaseService.getUserProfile()
            async let currentTierRequest = supabaseService.getUserSubscriptionTier()

            availableTiers = try await tiersRequest
            userProfile = try await profileRequest
            currentTier = try await currentTierRequest

            // If no current tier found, default to free
            if currentTier == nil {
                currentTier = availableTiers.first { $0.tierName == "free" }
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func upgradeTo(tier: SubscriptionTier) async {
        do {
            let newTokenCount: () = try await authManager.upgradeToTier(tier.tierName)

            // Refresh data
            await loadSubscriptionData()

            // Show success message or handle App Store purchase
            print("Upgraded to \(tier.tierName) with \(newTokenCount) tokens")
        } catch {
            errorMessage = "Failed to upgrade: \(error.localizedDescription)"
        }
    }

    func tierColor(for tierName: String) -> Color {
        switch tierName.lowercased() {
        case "free": return .gray
        case "starter": return .blue
        case "pro": return .orange
        default: return .gray
        }
    }

    func tokenColor(for tokens: Int, max: Int) -> Color {
        let percentage = Double(tokens) / Double(max)
        if percentage > 0.5 { return .green }
        if percentage > 0.2 { return .orange }
        return .red
    }

    func iconForFeature(_ feature: String) -> String {
        switch feature {
        case "ai_requests": return "brain"
        case "basic_scanning": return "camera"
        case "bulk_scanning": return "square.grid.3x3"
        case "barcode_scanning": return "barcode"
        case "marketplace_uploads": return "icloud.and.arrow.up"
        case "daily_market_insights": return "chart.line.uptrend.xyaxis"
        case "daily_price_history": return "clock.arrow.circlepath"
        case "advanced_insights": return "chart.bar.doc.horizontal"
        case "priority_support": return "envelope.badge"
        case "item_history": return "clock"
        case "price_analysis": return "dollarsign.circle"
        default: return "checkmark.circle"
        }
    }

    func titleForFeature(_ feature: String) -> String {
        switch feature {
        case "ai_requests": return "AI Requests"
        case "basic_scanning": return "Basic Scanning"
        case "bulk_scanning": return "Bulk Scanning"
        case "barcode_scanning": return "Barcode Scanning"
        case "marketplace_uploads": return "Marketplace Uploads"
        case "daily_market_insights": return "Daily Market Insights"
        case "daily_price_history": return "Price History"
        case "advanced_insights": return "Advanced Analytics"
        case "priority_support": return "Priority Support"
        case "item_history": return "Item History"
        case "price_analysis": return "Price Analysis"
        default: return feature.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    func descriptionForFeature(_ feature: String) -> String {
        switch feature {
        case "ai_requests": return "Powered by advanced AI models"
        case "basic_scanning": return "Scan individual items"
        case "bulk_scanning": return "Scan multiple items at once"
        case "barcode_scanning": return "Quick barcode recognition"
        case "marketplace_uploads": return "Upload directly to eBay, Mercari, etc."
        case "daily_market_insights": return "Daily market trends and opportunities"
        case "daily_price_history": return "Track price changes over time"
        case "advanced_insights": return "Deep analytics and recommendations"
        case "priority_support": return "24/7 customer support"
        case "item_history": return "Keep track of all your scans"
        case "price_analysis": return "See detailed pricing across marketplaces"
        default: return "Available in this tier"
        }
    }
}

// MARK: - Supporting Views
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

struct UpgradeTierCard: View {
    let tier: SubscriptionTier
    let onUpgrade: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.tierName.capitalized)
                        .font(.title3)
                        .fontWeight(.semibold)

                    if let price = tier.priceMonthly {
                        Text("$\(price, specifier: "%.2f")/month")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Text("\(tier.tokensPerPeriod) tokens")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }

            Button("Upgrade to \(tier.tierName.capitalized)") {
                Task { await onUpgrade() }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
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
