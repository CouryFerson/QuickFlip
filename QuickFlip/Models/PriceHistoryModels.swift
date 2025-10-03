//
//  PriceHistoryModels.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/2/25.
//

import Foundation

// MARK: - Price History Models

struct PriceHistory {
    let dataPoints: [PriceDataPoint]
    let averagePrice: Double
    let minPrice: Double
    let maxPrice: Double
    let totalSales: Int
    let priceChange: Double
    let priceChangePercentage: Double

    var formattedAveragePrice: String {
        return String(format: "$%.2f", averagePrice)
    }

    var formattedMinPrice: String {
        return String(format: "$%.2f", minPrice)
    }

    var formattedMaxPrice: String {
        return String(format: "$%.2f", maxPrice)
    }

    var formattedPriceChange: String {
        let sign = priceChange >= 0 ? "+" : ""
        return String(format: "%@$%.2f", sign, priceChange)
    }

    var formattedPriceChangePercentage: String {
        let sign = priceChangePercentage >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, priceChangePercentage)
    }

    var priceRange: String {
        return "\(formattedMinPrice) - \(formattedMaxPrice)"
    }

    var isPriceIncreasing: Bool {
        return priceChange > 0
    }

    var isPriceDecreasing: Bool {
        return priceChange < 0
    }

    var isPriceStable: Bool {
        return abs(priceChangePercentage) < 5 // Within 5% considered stable
    }

    var hasData: Bool {
        return !dataPoints.isEmpty && totalSales > 0
    }

    var trendDescription: String {
        if !hasData {
            return "No recent sales data available"
        }

        if isPriceStable {
            return "Stable pricing"
        } else if isPriceIncreasing {
            return "Trending up"
        } else {
            return "Trending down"
        }
    }
}

struct PriceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let averagePrice: Double
    let minPrice: Double
    let maxPrice: Double
    let salesCount: Int

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var formattedPrice: String {
        return String(format: "$%.2f", averagePrice)
    }
}

// MARK: - Mock Data for Previews
extension PriceHistory {
    static var mock: PriceHistory {
        let calendar = Calendar.current
        let now = Date()

        let dataPoints = (0..<13).map { weekOffset in
            let date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now)!
            let basePrice = 45.0
            let variance = Double.random(in: -10...10)
            let avgPrice = basePrice + variance

            return PriceDataPoint(
                date: date,
                averagePrice: avgPrice,
                minPrice: avgPrice - 5,
                maxPrice: avgPrice + 5,
                salesCount: Int.random(in: 2...8)
            )
        }.reversed()

        return PriceHistory(
            dataPoints: Array(dataPoints),
            averagePrice: 47.50,
            minPrice: 35.00,
            maxPrice: 60.00,
            totalSales: 47,
            priceChange: 3.50,
            priceChangePercentage: 7.9
        )
    }

    static var mockNoData: PriceHistory {
        return PriceHistory(
            dataPoints: [],
            averagePrice: 0,
            minPrice: 0,
            maxPrice: 0,
            totalSales: 0,
            priceChange: 0,
            priceChangePercentage: 0
        )
    }
}
