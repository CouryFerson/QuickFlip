import StoreKit
import SwiftUI

@MainActor
class StoreKitManager: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var consumables: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionGroupStatus: Product.SubscriptionInfo.RenewalState?

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?

    // Product IDs
    private let subscriptionIDs = [
        "com.fersonix.quikflip.starter_sub_monthly",
        "com.fersonix.quikflip.pro_sub_monthly"
    ]

    private let consumableIDs = [
        "com.fersonix.quikflip.tokens_100"
    ]

    // MARK: - Initialization

    init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Interface

    func requestProducts() async {
        print("🛒 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

        isLoading = true
        errorMessage = nil

        print("🛒 Requesting products for IDs: \(subscriptionIDs + consumableIDs)")

        do {
            let storeProducts = try await Product.products(for: subscriptionIDs + consumableIDs)

            print("🛒 Received \(storeProducts.count) products from App Store")

            var newSubscriptions: [Product] = []
            var newConsumables: [Product] = []

            for product in storeProducts {
                print("🛒 Product: \(product.id) - Type: \(product.type) - Price: \(product.displayPrice)")

                switch product.type {
                case .autoRenewable:
                    newSubscriptions.append(product)
                case .consumable:
                    newConsumables.append(product)
                default:
                    print("🛒 Unknown product type: \(product.type) for product: \(product.id)")
                }
            }

            subscriptions = sortByPrice(newSubscriptions)
            consumables = sortByPrice(newConsumables)

            print("🛒 Final result - Subscriptions: \(subscriptions.count), Consumables: \(consumables.count)")

            await updateCustomerProductStatus()

        } catch {
            print("🛒 Error loading products: \(error)")
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction

        case .userCancelled, .pending:
            return nil

        default:
            return nil
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateCustomerProductStatus()
    }

    func updateCustomerProductStatus() async {
        var purchasedSubscriptions: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productType == .autoRenewable {
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }

        self.purchasedSubscriptions = purchasedSubscriptions

        // Update subscription status
        subscriptionGroupStatus = try? await subscriptions.first?.subscription?.status.first?.state
    }

    // MARK: - Helper Properties

    var hasActiveSubscription: Bool {
        return !purchasedSubscriptions.isEmpty
    }

    var activeSubscription: Product? {
        return purchasedSubscriptions.first
    }
}

// MARK: - Private Methods
private extension StoreKitManager {

    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted { $0.price < $1.price }
    }
}

// MARK: - Errors
enum StoreKitError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}

// MARK: - RenewalState Extension
extension Product.SubscriptionInfo.RenewalState {
    var localizedDescription: String {
        switch self {
        case .subscribed:
            return "Subscribed"
        case .expired:
            return "Expired"
        case .inBillingRetryPeriod:
            return "In Billing Retry"
        case .inGracePeriod:
            return "In Grace Period"
        case .revoked:
            return "Revoked"
        default:
            return "Unknown"
        }
    }
}
