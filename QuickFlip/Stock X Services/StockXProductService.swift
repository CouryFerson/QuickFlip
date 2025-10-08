import Foundation

// MARK: - StockX Product Service
class StockXProductService: ObservableObject {
    @Published var isLoading = false
    @Published var searchResults: [StockXProduct] = []
    @Published var selectedProduct: StockXProduct?
    @Published var productVariants: [StockXVariant] = []
    @Published var lastError: String?

    private let supabaseService: SupabaseService
    private let authService: StockXAuthService
    private let debugMode = true

    // Search debouncing
    private var searchTask: Task<Void, Never>?

    init(supabaseService: SupabaseService, authService: StockXAuthService) {
        self.supabaseService = supabaseService
        self.authService = authService
    }

    // MARK: - Search Products
    func searchProducts(query: String, pageSize: Int = 20) async {
        // Cancel previous search
        searchTask?.cancel()

        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
            }
            return
        }

        searchTask = Task {
            // Debounce - wait 300ms
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }

            await performSearch(query: query, pageSize: pageSize)
        }
    }

    private func performSearch(query: String, pageSize: Int) async {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }

        if debugMode {
            print("🔍 Searching StockX for: \(query)")
        }

        do {
            let accessToken = try await authService.getValidAccessToken()

            let response: StockXSearchResponse = try await supabaseService.searchStockXProducts(
                query: query,
                pageSize: pageSize,
                accessToken: accessToken
            )

            await MainActor.run {
                self.searchResults = response.products
                self.isLoading = false
            }

            if debugMode {
                print("✅ Found \(response.products.count) products")
            }

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.lastError = error.localizedDescription
            }

            if debugMode {
                print("❌ Search error: \(error)")
            }
        }
    }

    // MARK: - Get Product Variants
    func fetchVariants(for productId: String) async {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }

        if debugMode {
            print("📦 Fetching variants for product: \(productId)")
        }

        do {
            let accessToken = try await authService.getValidAccessToken()

            let variants: [StockXVariant] = try await supabaseService.getStockXVariants(
                productId: productId,
                accessToken: accessToken
            )

            await MainActor.run {
                self.productVariants = variants
                self.isLoading = false
            }

            if debugMode {
                print("✅ Found \(variants.count) variants")
            }

        } catch {
            await MainActor.run {
                self.isLoading = false
                self.lastError = error.localizedDescription
            }

            if debugMode {
                print("❌ Variants error: \(error)")
            }
        }
    }

    // MARK: - Get Market Data
    func fetchMarketData(productId: String, variantId: String, currencyCode: String = "USD") async throws -> StockXMarketData {
        if debugMode {
            print("💰 Fetching market data for variant: \(variantId)")
        }

        let accessToken = try await authService.getValidAccessToken()

        let marketData: StockXMarketData = try await supabaseService.getStockXMarketData(
            productId: productId,
            variantId: variantId,
            currencyCode: currencyCode,
            accessToken: accessToken
        )

        if debugMode {
            print("✅ Market data - Lowest Ask: $\(marketData.lowestAsk), Highest Bid: $\(marketData.highestBid)")
        }

        return marketData
    }

    // MARK: - Helper Methods
    func selectProduct(_ product: StockXProduct) {
        selectedProduct = product
    }

    func clearSearch() {
        searchTask?.cancel()
        searchResults = []
        selectedProduct = nil
        productVariants = []
    }
}
