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

    var suggestedPricing: String {
        // Suggest pricing based on median
        let competitivePrice = medianPrice * 0.95 // 5% below median
        return String(format: "$%.2f", competitivePrice)
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

        return MarketPriceData(
            itemName: "Apple TV Siri Remote",
            priceRanges: ranges,
            averagePrice: 54.99,
            minPrice: 32.50,
            maxPrice: 89.99,
            totalListings: 49,
            medianPrice: 52.00
        )
    }

    static var mockNoData: MarketPriceData {
        return MarketPriceData(
            itemName: "Rare Item",
            priceRanges: [],
            averagePrice: 0,
            minPrice: 0,
            maxPrice: 0,
            totalListings: 0,
            medianPrice: 0
        )
    }
}
