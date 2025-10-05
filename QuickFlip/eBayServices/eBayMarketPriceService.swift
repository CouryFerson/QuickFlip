
import Combine
import SwiftUI

// MARK: - eBay Browse API Market Price Service
class eBayMarketPriceService: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?

    private let debugMode = true
    private let supabaseService: SupabaseService

    // Results caching
    private var cache: [String: (data: MarketPriceData, timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 hour

    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }

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
        // Simplify search query
        let searchKeywords = simplifySearchQuery(itemName)

        if debugMode {
            print("=== Calling Edge Function ===")
            print("Search Keywords: \(searchKeywords)")
            print("==============================")
        }

        // Call Edge Function instead of eBay directly
        let browseResponse = try await supabaseService.searcheBayListings(
            searchKeywords: searchKeywords,
            limit: 50,
            isProduction: eBayConfig.isProduction
        )

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

        let freeShippingCount = listings.filter { $0.shippingCost == 0 }.count
        let freeShippingPercentage = (Double(freeShippingCount) / total) * 100

        let bestOfferCount = listings.filter { $0.buyingOptions.contains("BEST_OFFER") }.count
        let bestOfferPercentage = (Double(bestOfferCount) / total) * 100

        let auctionCount = listings.filter { $0.buyingOptions.contains("AUCTION") }.count
        let auctionPercentage = (Double(auctionCount) / total) * 100

        let topRatedCount = listings.filter { $0.topRatedBuyingExperience }.count
        let topRatedPercentage = (Double(topRatedCount) / total) * 100

        var conditionPricing: [String: Double] = [:]
        let conditions = Set(listings.map { $0.condition })
        for condition in conditions {
            let conditionListings = listings.filter { $0.condition == condition }
            let avgPrice = conditionListings.map { $0.price }.reduce(0, +) / Double(conditionListings.count)
            conditionPricing[condition] = avgPrice
        }

        let topRatedListings = listings.filter { $0.topRatedBuyingExperience }
        let regularListings = listings.filter { !$0.topRatedBuyingExperience }
        let topRatedAvg = topRatedListings.isEmpty ? 0 : topRatedListings.map { $0.price }.reduce(0, +) / Double(topRatedListings.count)
        let regularAvg = regularListings.isEmpty ? 0 : regularListings.map { $0.price }.reduce(0, +) / Double(regularListings.count)
        let topRatedPremium = regularAvg > 0 ? ((topRatedAvg - regularAvg) / regularAvg) * 100 : 0

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

        let suggestedPrice = medianPrice * 1.05

        let enableBestOffer = insights.bestOfferPercentage > 50
        if enableBestOffer {
            tips.append("Enable 'Best Offer' - \(Int(insights.bestOfferPercentage))% of sellers accept offers")
        }

        let offerFreeShipping = insights.freeShippingPercentage > 50
        if offerFreeShipping {
            tips.append("Offer free shipping - \(Int(insights.freeShippingPercentage))% of competitors do")
        }

        if totalListings > 50 {
            tips.append("High competition - price competitively and offer fast shipping")
        } else if totalListings < 10 {
            tips.append("Low competition - you can price higher")
        }

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
}

// MARK: - Browse API Response Models
struct BrowseSearchResponse: Codable {
    let itemSummaries: [BrowseItemSummary]?
}

struct BrowseItemSummary: Codable {
    let title: String?
    let price: BrowsePrice?
    let condition: String?
    let shippingOptions: [BrowseShippingOption]?
    let buyingOptions: [String]?
    let topRatedBuyingExperience: Bool?
    let seller: BrowseSeller?
}

struct BrowseSeller: Codable {
    let username: String?
    let feedbackScore: Int?
    let feedbackPercentage: String?
}

struct BrowsePrice: Codable {
    let value: String?
    let currency: String?
}

struct BrowseShippingOption: Codable {
    let shippingCost: BrowsePrice?
}

struct BrowseListing {
    let title: String
    let price: Double
    let condition: String
    let shippingCost: Double
    let buyingOptions: [String]
    let topRatedBuyingExperience: Bool
    let sellerFeedbackScore: Int?
}

struct AppTokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}
