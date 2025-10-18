//
//  StockXModels.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/7/25.
//

import Foundation

// MARK: - Product Search Response
struct StockXSearchResponse: Codable {
    let count: Int
    let pageNumber: Int
    let pageSize: Int
    let hasNextPage: Bool
    let products: [StockXProduct]
}

// MARK: - Product
struct StockXProduct: Codable, Identifiable {
    let productId: String
    let brand: String
    let productType: String
    let styleId: String
    let urlKey: String
    let title: String
    let productAttributes: ProductAttributes

    var id: String { productId }

    // Computed properties for display
    var imageURL: String {
        // StockX image URL pattern
        "https://images.stockx.com/images/\(urlKey).jpg"
    }

    var colorwayDisplay: String {
        productAttributes.colorway ?? productAttributes.color ?? ""
    }
}

struct ProductAttributes: Codable {
    let color: String?
    let colorway: String?
    let gender: String
    let releaseDate: String?
    let retailPrice: Int?
    let season: String?
}
struct SizeChart: Codable {
    let availableConversions: [SizeConversion]?
    let defaultConversion: SizeConversion?
}

struct SizeConversion: Codable {
    let name: String?
    let type: String?
    let size: String?
}

// MARK: - Product Variants Response
struct StockXVariant: Codable, Identifiable {
    let productId: String
    let variantId: String
    let variantName: String
    let variantValue: String?
    let sizeChart: VariantSizeChart?
    let gtins: [GTIN]?
    let isFlexEligible: Bool
    let isDirectEligible: Bool

    var id: String { variantId }

    // Display properties
    var sizeDisplay: String {
        sizeChart?.defaultConversion?.size ?? variantValue ?? "No size available"
    }

    var sizeType: String {
        sizeChart?.defaultConversion?.type ?? "standard"
    }
}

struct VariantSizeChart: Codable {
    let availableConversions: [SizeDetail]?
    let defaultConversion: SizeDetail?
}

struct SizeDetail: Codable {
    let size: String
    let type: String
}

struct GTIN: Codable {
    let identifier: String
    let type: String
}

// MARK: - Market Data Response
struct StockXMarketData: Codable {
    let productId: String
    let variantId: String
    let currencyCode: String
    let lowestAskAmount: String?
    let highestBidAmount: String?
    let sellFasterAmount: String?
    let earnMoreAmount: String?
    let flexLowestAskAmount: String?
    let standardMarketData: MarketDataDetail?
    let flexMarketData: MarketDataDetail?
    let directMarketData: MarketDataDetail?

    // Computed properties
    var lowestAsk: Double {
        Double(lowestAskAmount ?? "0") ?? 0
    }

    var highestBid: Double {
        Double(highestBidAmount ?? "0") ?? 0
    }

    var sellFaster: Double {
        Double(sellFasterAmount ?? "0") ?? 0
    }

    var earnMore: Double {
        Double(earnMoreAmount ?? "0") ?? 0
    }
}

struct MarketDataDetail: Codable {
    let beatUS: String?
    let earnMore: String?
    let sellFaster: String?
    let highestBidAmount: String?
    let lowestAsk: String?
}

// MARK: - Create Ask Request
struct StockXCreateAskRequest: Codable {
    let amount: String
    let variantId: String
    let currencyCode: String
    let expiresAt: String?
    let active: Bool
    let inventoryType: String

    init(amount: Double, variantId: String, currencyCode: String = "USD", inventoryType: String = "STANDARD") {
        self.amount = String(format: "%.0f", amount) // ✅ This should format as "104" not "104.0"
        self.variantId = variantId
        self.currencyCode = currencyCode
        self.expiresAt = nil
        self.active = true
        self.inventoryType = inventoryType
    }
}

// MARK: - Create Ask Response
struct StockXCreateAskResponse: Codable {
    let listingId: String
    let operationId: String
    let operationType: String
    let operationStatus: String
    let operationUrl: String?
    let operationInitiatedBy: String
    let operationInitiatedVia: String
    let createdAt: String
    let updatedAt: String
    let changes: AskChanges?
    let error: String?

    var isSuccessful: Bool {
        operationStatus == "PENDING" || operationStatus == "COMPLETED"
    }
}

struct AskChanges: Codable {
    let additions: AskAdditions?
    let updates: [String: String]?
    let removals: [String: String]?
}

struct AskAdditions: Codable {
    let active: Bool?
    let askData: AskDataDetail?
}

struct AskDataDetail: Codable {
    let amount: String
    let currency: String
    let expiresAt: String?
}

// MARK: - Error Response
struct StockXError: Codable {
    let error: String?
    let message: String?
    let statusCode: Int?

    var displayMessage: String {
        message ?? error ?? "An unknown error occurred"
    }
}
