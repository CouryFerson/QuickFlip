import SwiftUI

// MARK: - eBay Finding API Price History Service
class eBayPriceHistoryService: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?

    private let debugMode = true

    func fetchPriceHistory(for itemName: String, category: String) async throws -> PriceHistory {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }

        if debugMode {
            print("=== Finding API Price History ===")
            print("Item: \(itemName)")
            print("Category: \(category)")
            print("================================")
        }

        do {
            let completedItems = try await searchCompletedItems(itemName: itemName, category: category)
            let priceHistory = processPriceData(completedItems)

            await MainActor.run {
                isLoading = false
            }

            return priceHistory

        } catch {
            await MainActor.run {
                isLoading = false
                lastError = error.localizedDescription
            }
            throw error
        }
    }

    private func searchCompletedItems(itemName: String, category: String) async throws -> [CompletedItem] {
        // Finding API endpoint
        let baseURL = eBayConfig.isProduction
            ? "https://svcs.ebay.com/services/search/FindingService/v1"
            : "https://svcs.sandbox.ebay.com/services/search/FindingService/v1"

        // Build query parameters
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "OPERATION-NAME", value: "findCompletedItems"),
            URLQueryItem(name: "SERVICE-VERSION", value: "1.0.0"),
            URLQueryItem(name: "SECURITY-APPNAME", value: eBayConfig.clientID),
            URLQueryItem(name: "RESPONSE-DATA-FORMAT", value: "JSON"),
            URLQueryItem(name: "REST-PAYLOAD", value: ""),
            URLQueryItem(name: "keywords", value: itemName),
            URLQueryItem(name: "sortOrder", value: "EndTimeSoonest"),
            URLQueryItem(name: "paginationInput.entriesPerPage", value: "100"),
            // Filter for sold items only
            URLQueryItem(name: "itemFilter(0).name", value: "SoldItemsOnly"),
            URLQueryItem(name: "itemFilter(0).value", value: "true"),
            // Filter for last 90 days
            URLQueryItem(name: "itemFilter(1).name", value: "EndTimeFrom"),
            URLQueryItem(name: "itemFilter(1).value", value: date90DaysAgo()),
            URLQueryItem(name: "itemFilter(2).name", value: "EndTimeTo"),
            URLQueryItem(name: "itemFilter(2).value", value: currentDate())
        ]

        guard let url = components.url else {
            throw eBayError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if debugMode {
            print("=== Finding API Request ===")
            print("URL: \(url.absoluteString)")
            print("===========================")
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
            throw eBayError.networkError
        }

        // Parse JSON response
        let decoder = JSONDecoder()
        let findingResponse = try decoder.decode(FindingAPIResponse.self, from: data)

        guard let searchResult = findingResponse.findCompletedItemsResponse?.first?.searchResult?.first,
              let items = searchResult.item else {
            if debugMode {
                print("No completed items found")
            }
            return []
        }

        if debugMode {
            print("Found \(items.count) completed items")
        }

        return items.compactMap { item -> CompletedItem? in
            guard let title = item.title?.first,
                  let priceString = item.sellingStatus?.first?.currentPrice?.first?.value,
                  let price = Double(priceString),
                  let endTimeString = item.listingInfo?.first?.endTime?.first,
                  let endTime = parseISO8601Date(endTimeString) else {
                return nil
            }

            let condition = item.condition?.first?.conditionDisplayName?.first ?? "Unknown"

            return CompletedItem(
                title: title,
                price: price,
                endTime: endTime,
                condition: condition
            )
        }
    }

    private func processPriceData(_ items: [CompletedItem]) -> PriceHistory {
        guard !items.isEmpty else {
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

        // Sort by date
        let sortedItems = items.sorted { $0.endTime < $1.endTime }

        // Group by week for 90 days (approximately 13 weeks)
        let calendar = Calendar.current
        var weeklyData: [Date: [Double]] = [:]

        for item in sortedItems {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: item.endTime)?.start ?? item.endTime
            weeklyData[weekStart, default: []].append(item.price)
        }

        // Create data points
        let dataPoints = weeklyData.map { date, prices -> PriceDataPoint in
            let average = prices.reduce(0, +) / Double(prices.count)
            let min = prices.min() ?? 0
            let max = prices.max() ?? 0
            return PriceDataPoint(date: date, averagePrice: average, minPrice: min, maxPrice: max, salesCount: prices.count)
        }.sorted { $0.date < $1.date }

        // Calculate overall statistics
        let allPrices = items.map { $0.price }
        let averagePrice = allPrices.reduce(0, +) / Double(allPrices.count)
        let minPrice = allPrices.min() ?? 0
        let maxPrice = allPrices.max() ?? 0

        // Calculate price change (comparing first week to last week)
        let priceChange: Double
        let priceChangePercentage: Double
        if dataPoints.count >= 2 {
            let firstWeekAvg = dataPoints.first?.averagePrice ?? 0
            let lastWeekAvg = dataPoints.last?.averagePrice ?? 0
            priceChange = lastWeekAvg - firstWeekAvg
            priceChangePercentage = firstWeekAvg > 0 ? (priceChange / firstWeekAvg) * 100 : 0
        } else {
            priceChange = 0
            priceChangePercentage = 0
        }

        return PriceHistory(
            dataPoints: dataPoints,
            averagePrice: averagePrice,
            minPrice: minPrice,
            maxPrice: maxPrice,
            totalSales: items.count,
            priceChange: priceChange,
            priceChangePercentage: priceChangePercentage
        )
    }

    private func date90DaysAgo() -> String {
        let date = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        return ISO8601DateFormatter().string(from: date)
    }

    private func currentDate() -> String {
        return ISO8601DateFormatter().string(from: Date())
    }

    private func parseISO8601Date(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

// MARK: - Finding API Response Models
private struct FindingAPIResponse: Codable {
    let findCompletedItemsResponse: [FindCompletedItemsResponse]?
}

private struct FindCompletedItemsResponse: Codable {
    let searchResult: [SearchResult]?
}

private struct SearchResult: Codable {
    let item: [FindingItem]?
}

private struct FindingItem: Codable {
    let title: [String]?
    let sellingStatus: [SellingStatus]?
    let listingInfo: [ListingInfo]?
    let condition: [Condition]?
}

private struct SellingStatus: Codable {
    let currentPrice: [Price]?
}

private struct Price: Codable {
    let value: String?

    enum CodingKeys: String, CodingKey {
        case value = "__value__"
    }
}

private struct ListingInfo: Codable {
    let endTime: [String]?
}

private struct Condition: Codable {
    let conditionDisplayName: [String]?
}

// MARK: - Internal Models
private struct CompletedItem {
    let title: String
    let price: Double
    let endTime: Date
    let condition: String
}
