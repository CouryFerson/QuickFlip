import Foundation

// MARK: - Market Price Models

struct MarketPriceData {
    let itemName: String
    let priceRanges: [PriceRange]
    let averagePrice: Double
    let minPrice: Double
    let maxPrice: Double
    let totalListings: Int
    let medianPrice: Double
    let marketInsights: MarketInsights
    let sellingStrategy: SellingStrategy?

    var formattedAveragePrice: String {
        return String(format: "$%.2f", averagePrice)
    }

    var formattedMinPrice: String {
        return String(format: "$%.2f", minPrice)
    }

    var formattedMaxPrice: String {
        return String(format: "$%.2f", maxPrice)
    }

    var formattedMedianPrice: String {
        return String(format: "$%.2f", medianPrice)
    }

    var priceRange: String {
        return "\(formattedMinPrice) - \(formattedMaxPrice)"
    }

    var hasData: Bool {
        return !priceRanges.isEmpty && totalListings > 0
    }

    var marketSaturation: String {
        if totalListings < 10 {
            return "Low competition"
        } else if totalListings < 30 {
            return "Moderate competition"
        } else {
            return "High competition"
        }
    }
}

struct PriceRange: Identifiable {
    let id = UUID()
    let minPrice: Double
    let maxPrice: Double
    let listingCount: Int

    var rangeLabel: String {
        return "$\(Int(minPrice))-\(Int(maxPrice))"
    }

    var formattedRange: String {
        return String(format: "$%.0f - $%.0f", minPrice, maxPrice)
    }

    var midpoint: Double {
        return (minPrice + maxPrice) / 2
    }
}

// MARK: - Market Insights

struct MarketInsights {
    let freeShippingPercentage: Double
    let bestOfferPercentage: Double
    let auctionPercentage: Double
    let topRatedPercentage: Double
    let conditionPricing: [String: Double]
    let topRatedPremium: Double
    let averageSellerRating: Double

    var formattedFreeShipping: String {
        return String(format: "%.0f%%", freeShippingPercentage)
    }

    var formattedBestOffer: String {
        return String(format: "%.0f%%", bestOfferPercentage)
    }

    var formattedAuction: String {
        return String(format: "%.0f%%", auctionPercentage)
    }

    var formattedTopRated: String {
        return String(format: "%.0f%%", topRatedPercentage)
    }

    var formattedTopRatedPremium: String {
        return String(format: "+%.0f%%", topRatedPremium)
    }

    var hasSignificantFreeShipping: Bool {
        return freeShippingPercentage > 50
    }

    var hasSignificantBestOffer: Bool {
        return bestOfferPercentage > 50
    }

    var hasTopRatedPremium: Bool {
        return topRatedPremium > 5
    }
}

// MARK: - Selling Strategy

struct SellingStrategy {
    let suggestedPrice: Double
    let enableBestOffer: Bool
    let offerFreeShipping: Bool
    let tips: [String]

    var formattedSuggestedPrice: String {
        return String(format: "$%.2f", suggestedPrice)
    }
}

// MARK: - Mock Data for Previews

extension MarketPriceData {
    static var mock: MarketPriceData {
        let ranges = [
            PriceRange(minPrice: 30, maxPrice: 40, listingCount: 5),
            PriceRange(minPrice: 40, maxPrice: 50, listingCount: 12),
            PriceRange(minPrice: 50, maxPrice: 60, listingCount: 18),
            PriceRange(minPrice: 60, maxPrice: 70, listingCount: 8),
            PriceRange(minPrice: 70, maxPrice: 80, listingCount: 4),
            PriceRange(minPrice: 80, maxPrice: 90, listingCount: 2)
        ]

        let insights = MarketInsights(
            freeShippingPercentage: 65,
            bestOfferPercentage: 78,
            auctionPercentage: 15,
            topRatedPercentage: 45,
            conditionPricing: [
                "New": 58.99,
                "Like New": 52.00,
                "Good": 45.50,
                "Used": 38.00
            ],
            topRatedPremium: 12.5,
            averageSellerRating: 847
        )

        let strategy = SellingStrategy(
            suggestedPrice: 54.60,
            enableBestOffer: true,
            offerFreeShipping: true,
            tips: [
                "Enable 'Best Offer' - 78% of sellers accept offers",
                "Offer free shipping - 65% of competitors do",
                "Top-Rated sellers charge 12% more on average"
            ]
        )

        return MarketPriceData(
            itemName: "Apple TV Siri Remote",
            priceRanges: ranges,
            averagePrice: 54.99,
            minPrice: 32.50,
            maxPrice: 89.99,
            totalListings: 49,
            medianPrice: 52.00,
            marketInsights: insights,
            sellingStrategy: strategy
        )
    }

    static var mockNoData: MarketPriceData {
        let emptyInsights = MarketInsights(
            freeShippingPercentage: 0,
            bestOfferPercentage: 0,
            auctionPercentage: 0,
            topRatedPercentage: 0,
            conditionPricing: [:],
            topRatedPremium: 0,
            averageSellerRating: 0
        )

        return MarketPriceData(
            itemName: "Rare Item",
            priceRanges: [],
            averagePrice: 0,
            minPrice: 0,
            maxPrice: 0,
            totalListings: 0,
            medianPrice: 0,
            marketInsights: emptyInsights,
            sellingStrategy: nil
        )
    }
}
