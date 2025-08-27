import SwiftUI
import StoreKit

struct TokenPurchaseView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingSuccess = false
    @State private var purchasedTokens = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection

                if subscriptionManager.isLoading {
                    loadingSection
                } else if subscriptionManager.consumables.isEmpty {
                    noProductsSection
                } else {
                    tokenPackagesSection
                }

                if let errorMessage = subscriptionManager.errorMessage {
                    errorSection(errorMessage)
                }

                Spacer()

                disclaimerSection
            }
            .padding()
            .navigationTitle("Buy Tokens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Successful!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Successfully purchased \(purchasedTokens) tokens!")
            }
        }
    }
}

// MARK: - View Components
private extension TokenPurchaseView {

    @ViewBuilder
    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Buy More Tokens")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Purchase additional AI tokens to continue using QuickFlip's advanced features")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView("Loading token packages...")

            Text("Fetching available options from the App Store")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(height: 100)
    }

    @ViewBuilder
    var noProductsSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("No Token Packages Available")
                .font(.headline)

            Text("Unable to load token packages from the App Store. Please try again later.")
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
    }

    @ViewBuilder
    var tokenPackagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Packages")
                .font(.headline)

            LazyVStack(spacing: 12) {
                ForEach(subscriptionManager.consumables, id: \.id) { product in
                    TokenPackageDetailCard(
                        product: product,
                        isPurchasing: subscriptionManager.isPurchasing
                    ) {
                        await purchaseTokens(product)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func errorSection(_ message: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)

            Button("Try Again") {
                Task { await subscriptionManager.refreshSubscriptionData() }
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }

    @ViewBuilder
    var disclaimerSection: some View {
        VStack(spacing: 8) {
            Text("• Tokens are consumed when using AI features")
            Text("• Purchases are processed through the App Store")
            Text("• Tokens do not expire and carry over monthly")
        }
        .font(.caption)
        .foregroundColor(.gray)
        .multilineTextAlignment(.leading)
    }
}

// MARK: - Actions
private extension TokenPurchaseView {

    func purchaseTokens(_ product: Product) async {
        do {
            try await subscriptionManager.purchaseTokens(product)

            // Show success
            purchasedTokens = getTokenCount(from: product.id)
            showingSuccess = true

        } catch {
            // Error is handled by SubscriptionManager
            print("Token purchase failed: \(error)")
        }
    }

    func getTokenCount(from productID: String) -> Int {
        switch productID {
        case "com.fersonix.quikflip.tokens_100":
            return 100
        default:
            return 0
        }
    }
}

// MARK: - Supporting Views
struct TokenPackageDetailCard: View {
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

    private var valuePerToken: String {
        let priceDouble = NSDecimalNumber(decimal: product.price).doubleValue
        let count = Double(tokenCount)
        let perToken = priceDouble / count
        return String(format: "$%.3f per token", perToken)
    }

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            benefitsSection
            purchaseButton
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

private extension TokenPackageDetailCard {

    @ViewBuilder
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(tokenCount) Tokens")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(valuePerToken)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(product.displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Text("One-time purchase")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            benefitRow(icon: "bolt.fill", text: "\(tokenCount) AI requests")
            benefitRow(icon: "infinity", text: "Tokens never expire")
            benefitRow(icon: "plus.circle", text: "Adds to your current balance")
        }
    }

    @ViewBuilder
    func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }

    @ViewBuilder
    var purchaseButton: some View {
        Button(action: {
            Task { await onPurchase() }
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }

                Text(isPurchasing ? "Processing..." : "Buy \(tokenCount) Tokens")
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isPurchasing ? Color.gray : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(isPurchasing)
    }
}
