//
//  EbayListing.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import UIKit
import Foundation

// MARK: - eBay Listing Models
struct EbayListing {
    var title: String
    var description: String
    var category: String
    var condition: String
    var startingPrice: Double
    var buyItNowPrice: Double
    var listingType: ListingType
    var duration: Int
    var shippingCost: Double
    var returnsAccepted: Bool
    var returnPeriod: Int
    var photos: [UIImage]

    // Computed properties for convenience
    var formattedPrice: String {
        return String(format: "%.2f", buyItNowPrice)
    }

    var formattedStartingPrice: String {
        return String(format: "%.2f", startingPrice)
    }

    var formattedShippingCost: String {
        return shippingCost == 0.0 ? "Free" : String(format: "%.2f", shippingCost)
    }

    var durationText: String {
        return "\(duration) day\(duration == 1 ? "" : "s")"
    }

    var returnPolicyText: String {
        return returnsAccepted ? "\(returnPeriod) day returns" : "No returns"
    }
}

enum ListingType: CaseIterable {
    case auction
    case buyItNow

    var displayName: String {
        switch self {
        case .auction: return "Auction"
        case .buyItNow: return "Buy It Now"
        }
    }
}

// MARK: - eBay Listing Extensions
extension EbayListing {

    /// Creates a formatted string suitable for copying to clipboard
    var copyableText: String {
        return """
        Title: \(title)
        
        Description:
        \(description)
        
        Condition: \(condition)
        Price: $\(formattedPrice)
        Shipping: \(formattedShippingCost)
        Duration: \(durationText)
        Returns: \(returnPolicyText)
        Listing Type: \(listingType.displayName)
        
        Category: \(category)
        """
    }

    /// Creates an eBay-ready title (max 80 characters)
    var ebayTitle: String {
        return String(title.prefix(80))
    }

    /// Validates if the listing has required fields
    var isValid: Bool {
        return !title.isEmpty &&
               !description.isEmpty &&
               !condition.isEmpty &&
               buyItNowPrice > 0 &&
               !photos.isEmpty
    }

    /// Gets validation errors
    var validationErrors: [String] {
        var errors: [String] = []

        if title.isEmpty {
            errors.append("Title is required")
        }

        if description.isEmpty {
            errors.append("Description is required")
        }

        if condition.isEmpty {
            errors.append("Condition is required")
        }

        if buyItNowPrice <= 0 {
            errors.append("Price must be greater than $0")
        }

        if photos.isEmpty {
            errors.append("At least one photo is required")
        }

        if title.count > 80 {
            errors.append("Title must be 80 characters or less")
        }

        return errors
    }
}

// MARK: - Default Values
extension EbayListing {

    /// Creates a default listing with sensible defaults
    static func defaultListing() -> EbayListing {
        return EbayListing(
            title: "",
            description: "",
            category: "",
            condition: "Good",
            startingPrice: 0.99,
            buyItNowPrice: 0.0,
            listingType: .buyItNow,
            duration: 7,
            shippingCost: 0.0,
            returnsAccepted: true,
            returnPeriod: 30,
            photos: []
        )
    }
}
