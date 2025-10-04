import SwiftUI

// MARK: - eBay Browse API Market Price Service
class eBayMarketPriceService: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?

    private let debugMode = true

    // OAuth token caching
    private var appAccessToken: String?
    private var tokenExpiration: Date?

    // Results caching
    private var cache: [String: (data: MarketPriceData, timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 hour

    func fetchMarketPrices(for itemName: String, category: String) async throws -> MarketPriceData {
        // Check cache first
        let cacheKey = itemName.lowercased()
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            if debugMode {
                print("📦 Using cached market data for: \(itemName)")
            }
            return cached.data
        }

        await MainActor.run {
            isLoading = true
            lastError = nil
        }

        if debugMode {
            print("=== Browse API Market Prices ===")
            print("Item: \(itemName)")
            print("================================")
        }

        do {
            let listings = try await searchActiveListings(itemName: itemName)
            let marketData = processMarketData(listings, itemName: itemName)

            // Store in cache
            cache[cacheKey] = (marketData, Date())

            await MainActor.run {
                isLoading = false
            }

            return marketData

        } catch {
            await MainActor.run {
                isLoading = false
                lastError = error.localizedDescription
            }
            throw error
        }
    }

    private func searchActiveListings(itemName: String) async throws -> [BrowseListing] {
        // Get OAuth token
        let accessToken = try await getAppAccessToken()

        // Browse API endpoint
        let baseURL = eBayConfig.isProduction
            ? "https://api.ebay.com/buy/browse/v1/item_summary/search"
            : "https://api.sandbox.ebay.com/buy/browse/v1/item_summary/search"

        // Simplify search query
        let searchKeywords = simplifySearchQuery(itemName)

        // Build query parameters
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: searchKeywords),
            URLQueryItem(name: "limit", value: "50")
        ]

        guard let url = components.url else {
            throw eBayError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("EBAY_US", forHTTPHeaderField: "X-EBAY-C-MARKETPLACE-ID")

        if debugMode {
            print("=== Browse API Request ===")
            print("Search Keywords: \(searchKeywords)")
            print("URL: \(url.absoluteString)")
            print("==========================")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw eBayError.networkError
        }

        if debugMode {
            print("Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response preview: \(responseString.prefix(500))")
            }
        }

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error Response: \(responseString)")
            }
            throw eBayError.networkError
        }

        // Parse JSON response
        let decoder = JSONDecoder()
        let browseResponse = try decoder.decode(BrowseSearchResponse.self, from: data)

        guard let listings = browseResponse.itemSummaries else {
            if debugMode {
                print("No active listings found")
            }
            return []
        }

        if debugMode {
            print("Found \(listings.count) active listings")
        }

        return listings.compactMap { item -> BrowseListing? in
            guard let title = item.title,
                  let priceValue = item.price?.value,
                  let price = Double(priceValue) else {
                return nil
            }

            let condition = item.condition ?? "Unknown"
            let shippingCost = item.shippingOptions?.first?.shippingCost?.value.flatMap { Double($0) } ?? 0
            let buyingOptions = item.buyingOptions ?? []
            let topRated = item.topRatedBuyingExperience ?? false
            let feedbackScore = item.seller?.feedbackScore

            return BrowseListing(
                title: title,
                price: price,
                condition: condition,
                shippingCost: shippingCost,
                buyingOptions: buyingOptions,
                topRatedBuyingExperience: topRated,
                sellerFeedbackScore: feedbackScore
            )
        }
    }

    private func simplifySearchQuery(_ itemName: String) -> String {
        let simplified = itemName
            .replacingOccurrences(of: "(2nd generation)", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "(1st generation)", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "(3rd generation)", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)

        let words = simplified.split(separator: " ").prefix(4)
        return words.joined(separator: " ")
    }

    private func processMarketData(_ listings: [BrowseListing], itemName: String) -> MarketPriceData {
        guard !listings.isEmpty else {
            return MarketPriceData(
                itemName: itemName,
                priceRanges: [],
                averagePrice: 0,
                minPrice: 0,
                maxPrice: 0,
                totalListings: 0,
                medianPrice: 0,
                marketInsights: MarketInsights(
                    freeShippingPercentage: 0,
                    bestOfferPercentage: 0,
                    auctionPercentage: 0,
                    topRatedPercentage: 0,
                    conditionPricing: [:],
                    topRatedPremium: 0,
                    averageSellerRating: 0
                ),
                sellingStrategy: nil
            )
        }

        let allPrices = listings.map { $0.price }.sorted()
        let averagePrice = allPrices.reduce(0, +) / Double(allPrices.count)
        let minPrice = allPrices.first ?? 0
        let maxPrice = allPrices.last ?? 0
        let medianPrice = allPrices.count % 2 == 0
            ? (allPrices[allPrices.count / 2 - 1] + allPrices[allPrices.count / 2]) / 2
            : allPrices[allPrices.count / 2]

        // Create price range buckets for visualization
        let priceRanges = createPriceRanges(from: allPrices, min: minPrice, max: maxPrice)

        // Calculate market insights
        let insights = calculateMarketInsights(from: listings)

        // Generate selling strategy
        let strategy = generateSellingStrategy(
            averagePrice: averagePrice,
            medianPrice: medianPrice,
            insights: insights,
            totalListings: listings.count
        )

        return MarketPriceData(
            itemName: itemName,
            priceRanges: priceRanges,
            averagePrice: averagePrice,
            minPrice: minPrice,
            maxPrice: maxPrice,
            totalListings: listings.count,
            medianPrice: medianPrice,
            marketInsights: insights,
            sellingStrategy: strategy
        )
    }

    private func calculateMarketInsights(from listings: [BrowseListing]) -> MarketInsights {
        let total = Double(listings.count)

        // Free shipping analysis
        let freeShippingCount = listings.filter { $0.shippingCost == 0 }.count
        let freeShippingPercentage = (Double(freeShippingCount) / total) * 100

        // Best Offer analysis
        let bestOfferCount = listings.filter { $0.buyingOptions.contains("BEST_OFFER") }.count
        let bestOfferPercentage = (Double(bestOfferCount) / total) * 100

        // Auction analysis
        let auctionCount = listings.filter { $0.buyingOptions.contains("AUCTION") }.count
        let auctionPercentage = (Double(auctionCount) / total) * 100

        // Top-Rated analysis
        let topRatedCount = listings.filter { $0.topRatedBuyingExperience }.count
        let topRatedPercentage = (Double(topRatedCount) / total) * 100

        // Condition-based pricing
        var conditionPricing: [String: Double] = [:]
        let conditions = Set(listings.map { $0.condition })
        for condition in conditions {
            let conditionListings = listings.filter { $0.condition == condition }
            let avgPrice = conditionListings.map { $0.price }.reduce(0, +) / Double(conditionListings.count)
            conditionPricing[condition] = avgPrice
        }

        // Top-Rated premium calculation
        let topRatedListings = listings.filter { $0.topRatedBuyingExperience }
        let regularListings = listings.filter { !$0.topRatedBuyingExperience }
        let topRatedAvg = topRatedListings.isEmpty ? 0 : topRatedListings.map { $0.price }.reduce(0, +) / Double(topRatedListings.count)
        let regularAvg = regularListings.isEmpty ? 0 : regularListings.map { $0.price }.reduce(0, +) / Double(regularListings.count)
        let topRatedPremium = regularAvg > 0 ? ((topRatedAvg - regularAvg) / regularAvg) * 100 : 0

        // Average seller rating
        let ratingsWithScores = listings.compactMap { $0.sellerFeedbackScore }
        let averageSellerRating = ratingsWithScores.isEmpty ? 0 : Double(ratingsWithScores.reduce(0, +)) / Double(ratingsWithScores.count)

        return MarketInsights(
            freeShippingPercentage: freeShippingPercentage,
            bestOfferPercentage: bestOfferPercentage,
            auctionPercentage: auctionPercentage,
            topRatedPercentage: topRatedPercentage,
            conditionPricing: conditionPricing,
            topRatedPremium: topRatedPremium,
            averageSellerRating: averageSellerRating
        )
    }

    private func generateSellingStrategy(
        averagePrice: Double,
        medianPrice: Double,
        insights: MarketInsights,
        totalListings: Int
    ) -> SellingStrategy {
        var tips: [String] = []

        // Pricing recommendation
        let suggestedPrice = medianPrice * 1.05 // 5% above median for negotiation room

        // Best Offer recommendation
        let enableBestOffer = insights.bestOfferPercentage > 50
        if enableBestOffer {
            tips.append("Enable 'Best Offer' - \(Int(insights.bestOfferPercentage))% of sellers accept offers")
        }

        // Free shipping recommendation
        let offerFreeShipping = insights.freeShippingPercentage > 50
        if offerFreeShipping {
            tips.append("Offer free shipping - \(Int(insights.freeShippingPercentage))% of competitors do")
        }

        // Competition level tip
        if totalListings > 50 {
            tips.append("High competition - price competitively and offer fast shipping")
        } else if totalListings < 10 {
            tips.append("Low competition - you can price higher")
        }

        // Top-Rated premium tip
        if insights.topRatedPremium > 5 {
            tips.append("Top-Rated sellers charge \(Int(insights.topRatedPremium))% more on average")
        }

        return SellingStrategy(
            suggestedPrice: suggestedPrice,
            enableBestOffer: enableBestOffer,
            offerFreeShipping: offerFreeShipping,
            tips: tips
        )
    }

    private func createPriceRanges(from prices: [Double], min: Double, max: Double) -> [PriceRange] {
        let bucketCount = 6
        let range = max - min
        let bucketSize = range / Double(bucketCount)

        var ranges: [PriceRange] = []

        for i in 0..<bucketCount {
            let rangeMin = min + (Double(i) * bucketSize)
            let rangeMax = i == bucketCount - 1 ? max : rangeMin + bucketSize

            let count = prices.filter { $0 >= rangeMin && $0 <= rangeMax }.count

            ranges.append(PriceRange(
                minPrice: rangeMin,
                maxPrice: rangeMax,
                listingCount: count
            ))
        }

        return ranges
    }

    // MARK: - OAuth Client Credentials Flow
    private func getAppAccessToken() async throws -> String {
        // Check if we have a valid cached token
        if let token = appAccessToken,
           let expiration = tokenExpiration,
           Date() < expiration {
            if debugMode {
                print("✅ Using cached app access token")
            }
            return token
        }

        // Get new token
        if debugMode {
            print("🔑 Fetching new app access token...")
        }

        let tokenURL = eBayConfig.isProduction
            ? URL(string: "https://api.ebay.com/identity/v1/oauth2/token")!
            : URL(string: "https://api.sandbox.ebay.com/identity/v1/oauth2/token")!

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Base64 encode clientID:clientSecret for Basic Auth
        let credentials = "\(eBayConfig.clientID):\(eBayConfig.clientSecret)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        // Request token with marketplace scope
        let scope = "https://api.ebay.com/oauth/api_scope"
        let body = "grant_type=client_credentials&scope=\(scope)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw eBayError.networkError
        }

        if debugMode {
            print("Token API Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Token Response: \(responseString)")
            }
        }

        guard httpResponse.statusCode == 200 else {
            throw eBayError.notAuthenticated
        }

        let tokenResponse = try JSONDecoder().decode(AppTokenResponse.self, from: data)

        // Cache the token (expires in seconds, usually 7200 = 2 hours)
        appAccessToken = tokenResponse.access_token
        tokenExpiration = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in - 300)) // Refresh 5 min early

        if debugMode {
            print("✅ App access token obtained, expires in \(tokenResponse.expires_in) seconds")
        }

        return tokenResponse.access_token
    }
}

// MARK: - Browse API Response Models
private struct BrowseSearchResponse: Codable {
    let itemSummaries: [BrowseItemSummary]?
}

private struct BrowseItemSummary: Codable {
    let title: String?
    let price: BrowsePrice?
    let condition: String?
    let shippingOptions: [BrowseShippingOption]?
    let buyingOptions: [String]?
    let topRatedBuyingExperience: Bool?
    let seller: BrowseSeller?
}

private struct BrowseSeller: Codable {
    let username: String?
    let feedbackScore: Int?
    let feedbackPercentage: String?
}

private struct BrowsePrice: Codable {
    let value: String?
    let currency: String?
}

private struct BrowseShippingOption: Codable {
    let shippingCost: BrowsePrice?
}

// MARK: - Internal Models
private struct BrowseListing {
    let title: String
    let price: Double
    let condition: String
    let shippingCost: Double
    let buyingOptions: [String]
    let topRatedBuyingExperience: Bool
    let sellerFeedbackScore: Int?
}

private struct AppTokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}
