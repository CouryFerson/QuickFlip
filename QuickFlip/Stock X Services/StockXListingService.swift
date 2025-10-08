import Foundation

// MARK: - StockX Listing Service
class StockXListingService: ObservableObject {
    @Published var isCreatingAsk = false
    @Published var lastError: String?
    @Published var createdAsk: StockXCreateAskResponse?

    private let supabaseService: SupabaseService
    private let authService: StockXAuthService
    private let debugMode = true

    init(supabaseService: SupabaseService, authService: StockXAuthService) {
        self.supabaseService = supabaseService
        self.authService = authService
    }

    // MARK: - Place Ask
    func placeAsk(
        variantId: String,
        askPrice: Double,
        currencyCode: String = "USD",
        inventoryType: String = "STANDARD"
    ) async throws -> StockXCreateAskResponse {

        await MainActor.run {
            isCreatingAsk = true
            lastError = nil
        }

        if debugMode {
            print("🏷️ Placing ask for variant: \(variantId)")
            print("💵 Ask price: $\(askPrice)")
        }

        do {
            let accessToken = try await authService.getValidAccessToken()

            let request = StockXCreateAskRequest(
                amount: askPrice,
                variantId: variantId,
                currencyCode: currencyCode,
                inventoryType: inventoryType
            )

            let response: StockXCreateAskResponse = try await supabaseService.placeStockXAsk(
                request: request,
                accessToken: accessToken
            )

            await MainActor.run {
                self.createdAsk = response
                self.isCreatingAsk = false
            }

            if debugMode {
                print("✅ Ask created successfully")
                print("📋 Listing ID: \(response.listingId)")
                print("📊 Status: \(response.operationStatus)")
            }

            if !response.isSuccessful {
                throw StockXListingError.askCreationFailed(response.error ?? "Unknown error")
            }

            return response

        } catch {
            await MainActor.run {
                self.isCreatingAsk = false
                self.lastError = error.localizedDescription
            }

            if debugMode {
                print("❌ Ask creation failed: \(error)")
            }

            throw error
        }
    }

    // MARK: - Calculate Recommended Price
    func calculateRecommendedPrice(from marketData: StockXMarketData, strategy: PricingStrategy) -> Double {
        switch strategy {
        case .competitive:
            // Price between highest bid and lowest ask
            return (marketData.highestBid + marketData.lowestAsk) / 2

        case .sellFaster:
            // Use StockX's sell faster recommendation
            return marketData.sellFaster

        case .earnMore:
            // Use StockX's earn more recommendation
            return marketData.earnMore

        case .matchLowestAsk:
            // Match current lowest ask
            return marketData.lowestAsk

        case .aboveMarket:
            // Price 5% above lowest ask
            return marketData.lowestAsk * 1.05
        }
    }

    // MARK: - Validate Ask Price
    func validateAskPrice(_ price: Double, against marketData: StockXMarketData) -> PriceValidation {
        if price < marketData.highestBid * 0.5 {
            return .tooLow("Price is significantly below market value")
        }

        if price > marketData.lowestAsk * 2 {
            return .tooHigh("Price is significantly above market value")
        }

        if price < marketData.highestBid {
            return .warning("Price is below highest bid - may sell instantly")
        }

        if price >= marketData.highestBid && price <= marketData.lowestAsk {
            return .good("Price is within market range")
        }

        if price > marketData.lowestAsk {
            return .warning("Price is above lowest ask - may take longer to sell")
        }

        return .good("Price looks good")
    }
}

// MARK: - Pricing Strategy
enum PricingStrategy {
    case competitive    // Between bid and ask
    case sellFaster     // StockX recommendation for quick sale
    case earnMore       // StockX recommendation for max profit
    case matchLowestAsk // Match current lowest ask
    case aboveMarket    // Price above market
}

// MARK: - Price Validation
enum PriceValidation {
    case tooLow(String)
    case tooHigh(String)
    case warning(String)
    case good(String)

    var isValid: Bool {
        switch self {
        case .good, .warning:
            return true
        case .tooLow, .tooHigh:
            return false
        }
    }

    var message: String {
        switch self {
        case .tooLow(let msg), .tooHigh(let msg), .warning(let msg), .good(let msg):
            return msg
        }
    }
}

// MARK: - Listing Errors
enum StockXListingError: Error, LocalizedError {
    case askCreationFailed(String)
    case invalidPrice
    case invalidVariant
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .askCreationFailed(let message):
            return "Failed to create ask: \(message)"
        case .invalidPrice:
            return "Invalid ask price"
        case .invalidVariant:
            return "Invalid product variant"
        case .notAuthenticated:
            return "Please authenticate with StockX first"
        }
    }
}
