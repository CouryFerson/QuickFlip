//
//  QuikListingData.swift
//  QuickFlip
//
//  Created by Claude on 2025-10-28.
//

import Foundation
import SwiftUI

/// Unified model for creating listings across multiple platforms
struct QuikListingData {
    // MARK: - Universal Fields
    var photos: [UIImage] = []
    var title: String = ""
    var description: String = ""
    var condition: ItemCondition = .good
    var basePrice: Double = 0.0

    // MARK: - Initialization
    init() {}

    init(from scannedItem: ScannedItem, image: UIImage) {
        self.photos = [image]
        self.title = scannedItem.itemName
        self.description = scannedItem.itemDescription ?? ""

        // Parse price from estimated value (e.g., "$99.99" -> 99.99)
        if let priceValue = Self.parsePrice(from: scannedItem.estimatedValue) {
            self.basePrice = priceValue
        }

        // Map condition if available
        if let scannedCondition = scannedItem.condition {
            self.condition = ItemCondition(from: scannedCondition)
        }
    }

    private static func parsePrice(from priceString: String) -> Double? {
        let numbers = priceString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(numbers).flatMap { $0 / 100.0 } // Assumes cents
    }

    // MARK: - Platform Selection
    var listToEbay: Bool = false
    var listToStockX: Bool = false

    // MARK: - eBay Specific Fields
    var ebayShippingCost: Double = 0.0
    var ebayListingType: ListingType = .buyItNow
    var ebayDuration: Int = 7
    var ebayReturnsAccepted: Bool = true
    var ebayReturnPeriod: Int = 30
    var ebayStartingPrice: Double = 0.0  // For auctions

    // MARK: - StockX Specific Fields
    var stockXProductId: String? = nil
    var stockXVariantId: String? = nil
    var stockXAskPrice: Double = 0.0
    var stockXProduct: StockXProduct? = nil
    var stockXVariant: StockXVariant? = nil
    var stockXMarketData: StockXMarketData? = nil

    // MARK: - Validation
    func validateUniversalFields() -> [String] {
        var errors: [String] = []

        if photos.isEmpty {
            errors.append("At least one photo is required")
        }
        if title.isEmpty {
            errors.append("Title is required")
        }
        if title.count > 80 {
            errors.append("Title must be 80 characters or less")
        }
        if description.isEmpty {
            errors.append("Description is required")
        }
        if basePrice <= 0 {
            errors.append("Price must be greater than 0")
        }

        return errors
    }

    func validateEbayFields() -> [String] {
        var errors: [String] = []

        if ebayListingType == .auction && ebayStartingPrice <= 0 {
            errors.append("Starting price is required for auctions")
        }

        return errors
    }

    func validateStockXFields() -> [String] {
        var errors: [String] = []

        if stockXProductId == nil {
            errors.append("StockX product must be selected")
        }
        if stockXVariantId == nil {
            errors.append("StockX variant/size must be selected")
        }
        if stockXAskPrice <= 0 {
            errors.append("StockX ask price must be greater than 0")
        }

        return errors
    }

    func canSubmit() -> (canSubmit: Bool, errors: [String]) {
        var allErrors: [String] = []

        // Universal validation
        allErrors.append(contentsOf: validateUniversalFields())

        // Platform-specific validation
        if listToEbay {
            allErrors.append(contentsOf: validateEbayFields())
        }
        if listToStockX {
            allErrors.append(contentsOf: validateStockXFields())
        }

        // Must select at least one platform
        if !listToEbay && !listToStockX {
            allErrors.append("Select at least one platform to list on")
        }

        return (allErrors.isEmpty, allErrors)
    }
}

// MARK: - Supporting Enums
enum ItemCondition: String, CaseIterable {
    case new = "New"
    case likeNew = "Like New"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var icon: String {
        switch self {
        case .new: return "sparkles"
        case .likeNew: return "star.fill"
        case .good: return "star.leadinghalf.filled"
        case .fair: return "star"
        case .poor: return "minus.circle"
        }
    }

    init(from scannedCondition: String) {
        let lowercased = scannedCondition.lowercased()
        if lowercased.contains("new") || lowercased.contains("mint") {
            self = .new
        } else if lowercased.contains("like new") || lowercased.contains("excellent") {
            self = .likeNew
        } else if lowercased.contains("good") || lowercased.contains("used") {
            self = .good
        } else if lowercased.contains("fair") || lowercased.contains("acceptable") {
            self = .fair
        } else if lowercased.contains("poor") || lowercased.contains("damaged") {
            self = .poor
        } else {
            self = .good // Default
        }
    }

    // Map to eBay condition ID
    var ebayConditionID: String {
        switch self {
        case .new: return "1000"
        case .likeNew: return "1500"
        case .good: return "3000"
        case .fair: return "4000"
        case .poor: return "5000"
        }
    }

    // Map to StockX condition scale (1-10)
    var stockXConditionScale: String {
        switch self {
        case .new: return "10"
        case .likeNew: return "9"
        case .good: return "7"
        case .fair: return "5"
        case .poor: return "3"
        }
    }
}

// MARK: - Submission Results
struct QuikListSubmissionResult {
    var ebayResult: EbaySubmissionResult?
    var stockXResult: StockXSubmissionResult?

    var hasAnySuccess: Bool {
        (ebayResult?.success ?? false) || (stockXResult?.success ?? false)
    }

    var hasAnyFailure: Bool {
        (ebayResult?.success == false) || (stockXResult?.success == false)
    }

    var allSuccessful: Bool {
        let ebayOk = ebayResult?.success ?? true  // true if not attempted
        let stockXOk = stockXResult?.success ?? true
        return ebayOk && stockXOk && (ebayResult != nil || stockXResult != nil)
    }
}

struct EbaySubmissionResult {
    var success: Bool
    var itemID: String?
    var listingURL: String?
    var error: String?
}

struct StockXSubmissionResult {
    var success: Bool
    var listingId: String?
    var operationStatus: String?
    var error: String?
}
