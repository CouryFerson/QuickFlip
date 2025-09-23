import SwiftUI

struct SettingsView: View {
    let actions: SettingsActions

    @EnvironmentObject var itemStorage: ItemStorageService
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var authManager: AuthManager

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
                profileSection
                accountSection
                preferencesSection
                dataStorageSection
                analysisSettingsSection
                supportInfoSection
                appInfoSection
            }
            .navigationTitle("Settings")
            .task {
                await subscriptionManager.refreshSubscriptionData()
            }
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
}

// MARK: - View Sections
private extension SettingsView {

    @ViewBuilder
    var profileSection: some View {
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
                    Text(userDisplayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(userEmail)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    userMembershipBadge
                }

                Spacer()

                Button("Edit") {
                    let action = actions.actions[.profile]
                    action?()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    var userMembershipBadge: some View {
        if let currentTier = subscriptionManager.currentTier {
            Text(membershipLabel(for: currentTier.tierName))
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(subscriptionManager.getTierColor(currentTier.tierName))
                .foregroundColor(.white)
                .cornerRadius(4)
        } else {
            Text("Free Member")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(4)
        }
    }

    @ViewBuilder
    var accountSection: some View {
        Section("Account") {
            Button {
                let action = actions.actions[.subscription]
                action?()
            } label: {
                HStack {
                    Label("Subscription", systemImage: "crown.fill")
                        .foregroundColor(.orange)

                    Spacer()

                    if let profile = subscriptionManager.userProfile {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(profile.tokens) tokens")
                                .font(.caption)
                                .foregroundColor(.blue)

                            if let currentTier = subscriptionManager.currentTier {
                                Text(currentTier.tierName.capitalized)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }

            actionRow(flow: .privacy, text: "Privacy & Security", systemImage: "lock.shield")

            Button(action: {
                signOut()
            }) {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    var preferencesSection: some View {
        Section("Preferences") {
            HStack {
                Label("Currency", systemImage: "dollarsign.circle")
                Spacer()
                Picker("", selection: $selectedCurrency) {
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
    }

    @ViewBuilder
    var dataStorageSection: some View {
        Section("Data & Storage") {
            Button {
                showingExportSheet = true
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }

            actionRow(flow: .storageUsage, text: "Storage Usage", systemImage: "internaldrive")
            actionRow(flow: .backUPSettings, text: "Backup Settings", systemImage: "icloud")

            Button {
                showingDeleteAlert = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    var analysisSettingsSection: some View {
        Section("Analysis Settings") {
            actionRow(flow: .aiModel, text: "AI Model", systemImage: "brain.head.profile")
            actionRow(flow: .marketplacePreferances, text: "Marketplace Preferences", systemImage: "storefront")
        }
    }

    @ViewBuilder
    var supportInfoSection: some View {
        Section("Support & Info") {
            actionRow(flow: .helpCenter, text: "Help Center", systemImage: "questionmark.circle")

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
        }
    }

    @ViewBuilder
    var appInfoSection: some View {
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

            if let profile = subscriptionManager.userProfile {
                HStack {
                    Text("Tokens Used")
                    Spacer()
                    if let currentTier = subscriptionManager.currentTier {
                        Text("\(currentTier.tokensPerPeriod - profile.tokens)/\(currentTier.tokensPerPeriod)")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Methods
 extension SettingsView {
    @ViewBuilder
    private func actionRow(flow: SettingsFlow, text: String, systemImage: String) -> some View {
        Button {
            let action = actions.actions[flow]
            action?()
        } label: {
            HStack {
                Label(text, systemImage: systemImage)
                Spacer()
                Image(systemName: "chevron.right")
                    .resizable()
                    .frame(width: 6, height: 12)
                    .foregroundStyle(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    var userDisplayName: String {
        return authManager.userName ?? "Not set"
    }

    var userEmail: String {
        return authManager.userEmail ?? "Not set"
    }

    func membershipLabel(for tierName: String) -> String {
        switch tierName.lowercased() {
        case "free":
            return "Free Member"
        case "starter":
            return "Starter Member"
        case "pro":
            return "Pro Member"
        default:
            return "Member"
        }
    }

    func contactSupport() {
        if let url = URL(string: "mailto:support@quickflip.app?subject=QuickFlip Support") {
            UIApplication.shared.open(url)
        }
    }

    func signOut() {
        Task {
            try? await authManager.signOut()
        }
    }
}

struct AIModelSettingsView: View {
    var body: some View {
        List {
            Section("Current Model") {
                HStack {
                    Text("AI Model")
                    Spacer()
                    Text("GPT-4o")
                        .foregroundColor(.gray)
                }
            }

            Section("Model Options") {
                Text("Advanced model selection coming soon")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("AI Model")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeeCalculatorSettingsView: View {
    var body: some View {
        Text("Fee Calculator Settings")
            .navigationTitle("Fee Calculator")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy")
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
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

                NavigationLink("Fee Calculator Settings", destination: FeeCalculatorSettingsView())
            }
        }
        .navigationTitle("Marketplace Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI
import StoreKit

// MARK: - Subscription View
struct SubscriptionView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingTokenPurchase = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                if subscriptionManager.isLoading {
                    loadingSection
                } else if let errorMessage = subscriptionManager.errorMessage {
                    errorSection(errorMessage)
                } else {
                    currentPlanSection
                    tokensSection
                    tokenPurchaseSection
                    featuresSection
                    upgradeSection
                    manageSubscriptionSection
                }

                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTokenPurchase) {
            TokenPurchaseView()
                .environmentObject(subscriptionManager)
        }
        .task {
            await subscriptionManager.initialize()
        }
        .refreshable {
            await subscriptionManager.refreshSubscriptionData()
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
    var loadingSection: some View {
        ProgressView("Loading subscription details...")
            .frame(height: 100)
    }

    @ViewBuilder
    var currentPlanSection: some View {
        if let currentTier = subscriptionManager.currentTier {
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Plan")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentTier.tierName.capitalized)
                            .font(.title3)
                            .fontWeight(.semibold)

                        if let price = currentTier.priceMonthly, price > 0 {
                            Text("$\(price, specifier: "%.2f")/month")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        } else {
                            Text("Free")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    subscriptionStatusBadge
                }
                .padding()
                .background(subscriptionManager.getTierColor(currentTier.tierName).opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    var subscriptionStatusBadge: some View {
        let isActive = subscriptionManager.hasActiveSubscription

        Text(isActive ? "Active" : "Inactive")
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(isActive ? Color.green : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
    }

    @ViewBuilder
    var tokensSection: some View {
        if let userProfile = subscriptionManager.userProfile,
           let currentTier = subscriptionManager.currentTier {
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
    var tokenPurchaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Need More Tokens?")
                .font(.headline)
                .padding(.horizontal)

            if !subscriptionManager.consumables.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(subscriptionManager.consumables, id: \.id) { product in
                        TokenPackageCard(
                            product: product,
                            isPurchasing: subscriptionManager.isPurchasing
                        ) {
                            await purchaseTokens(product)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                Button("Buy More Tokens") {
                    showingTokenPurchase = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    var featuresSection: some View {
        if let currentTier = subscriptionManager.currentTier {
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
        if subscriptionManager.canUpgradeFromCurrentTier {
            VStack(alignment: .leading, spacing: 16) {
                Text("Upgrade Options")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVStack(spacing: 12) {
                    ForEach(subscriptionManager.subscriptions, id: \.id) { product in
                        if subscriptionManager.shouldShowUpgrade(for: product) {
                            SubscriptionUpgradeCard(
                                product: product,
                                isPurchasing: subscriptionManager.isPurchasing
                            ) {
                                await purchaseSubscription(product)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    var manageSubscriptionSection: some View {
        VStack(spacing: 12) {
            Button("Manage Subscription") {
                openAppStoreSubscriptions()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

            Button("Restore Purchases") {
                Task { await restorePurchases() }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
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
                Task { await subscriptionManager.refreshSubscriptionData() }
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

// MARK: - Actions
private extension SubscriptionView {

    func purchaseSubscription(_ product: Product) async {
        do {
            try await subscriptionManager.purchaseSubscription(product)
        } catch {
            // Error is already handled by SubscriptionManager
            print("Subscription purchase failed: \(error)")
        }
    }

    func purchaseTokens(_ product: Product) async {
        do {
            try await subscriptionManager.purchaseTokens(product)
        } catch {
            // Error is already handled by SubscriptionManager
            print("Token purchase failed: \(error)")
        }
    }

    func restorePurchases() async {
        do {
            try await subscriptionManager.restorePurchases()
        } catch {
            // Error is already handled by SubscriptionManager
            print("Restore purchases failed: \(error)")
        }
    }

    func openAppStoreSubscriptions() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Helper Functions
private extension SubscriptionView {

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

struct TokenPackageCard: View {
    let product: Product
    let isPurchasing: Bool
    let onPurchase: () async -> Void

    private var tokenCount: Int {
        switch product.id {
        case "com.fersonix.quikflip.tokens_100":
            return 100
        default:
            return 0
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(tokenCount) Tokens")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("One-time purchase")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            Button(action: {
                Task { await onPurchase() }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    Text(isPurchasing ? "Purchasing..." : "Buy \(tokenCount) Tokens")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isPurchasing ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(isPurchasing)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SubscriptionUpgradeCard: View {
    let product: Product
    let isPurchasing: Bool
    let onUpgrade: () async -> Void

    private var tierName: String {
        switch product.id {
        case "com.fersonix.quikflip.starter_sub_monthly":
            return "Starter"
        case "com.fersonix.quikflip.pro_sub_monthly":
            return "Pro"
        default:
            return "Unknown"
        }
    }

    private var tierColor: Color {
        switch product.id {
        case "com.fersonix.quikflip.starter_sub_monthly":
            return .blue
        case "com.fersonix.quikflip.pro_sub_monthly":
            return .orange
        default:
            return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tierName)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(product.displayPrice + "/month")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: tierName == "Pro" ? "crown.fill" : "star.fill")
                    .font(.title2)
                    .foregroundColor(tierColor)
            }

            Button(action: {
                Task { await onUpgrade() }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    Text(isPurchasing ? "Upgrading..." : "Upgrade to \(tierName)")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isPurchasing ? Color.gray : tierColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(isPurchasing)
        }
        .padding()
        .background(tierColor.opacity(0.1))
        .cornerRadius(12)
    }
}
