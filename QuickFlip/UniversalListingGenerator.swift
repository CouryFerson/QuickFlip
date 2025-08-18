//
//  UniversalListingGenerator.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import Foundation
import UIKit

struct UniversalListingGenerator {

    static func generateListing(
        for marketplace: Marketplace,
        item: EbayListing,
        userLocation: String = "Kansas City, KS"
    ) -> MarketplaceListingOutput {

        switch marketplace {
        case .ebay:
            return generateEbayListing(item: item)
        case .facebook:
            return generateFacebookListing(item: item, location: userLocation)
        case .stockx:
            return generateStockXListing(item: item)
        case .amazon:
            return generateAmazonListing(item: item)
        case .etsy:
            return generateEtsyListing(item: item)
        case .mercari:
            return generateMercariListing(item: item)
        case .poshmark:
            return generatePoshmarkListing(item: item)
        case .depop:
            return generateDepopListing(item: item)
        }
    }

    // MARK: - eBay Listing
    private static func generateEbayListing(item: EbayListing) -> MarketplaceListingOutput {
        let listingText = """
        Title: \(item.ebayTitle)
        
        Condition: \(item.condition)
        
        Description:
        \(item.description)
        
        Starting Price: $\(item.formattedStartingPrice)
        Buy It Now Price: $\(item.formattedPrice)
        
        Shipping: \(item.formattedShippingCost)
        Duration: \(item.durationText)
        Returns: \(item.returnPolicyText)
        
        Category: \(item.category)
        """

        let instructions = """
        eBay Listing Instructions:
        1. Go to eBay.com and click "Sell"
        2. Upload your saved photos
        3. Copy and paste the details above
        4. Set your payment and shipping preferences
        5. Review and list!
        """

        return MarketplaceListingOutput(
            platform: .ebay,
            listingText: listingText,
            instructions: instructions,
            estimatedFees: calculateEbayFees(price: item.buyItNowPrice)
        )
    }

    // MARK: - Facebook Marketplace
    private static func generateFacebookListing(item: EbayListing, location: String) -> MarketplaceListingOutput {
        let listingText = """
        \(item.title) - $\(item.formattedPrice)
        
        \(item.condition) condition
        
        \(item.description)
        
        Located in \(location)
        Cash or Venmo accepted
        Can meet in safe public location
        
        #\(item.category.replacingOccurrences(of: " ", with: ""))
        """

        let instructions = """
        Facebook Marketplace Instructions:
        1. Open Facebook and go to Marketplace
        2. Click "Create New Listing"
        3. Upload your saved photos
        4. Copy and paste the details above
        5. Set your location and category
        6. Publish listing!
        """

        return MarketplaceListingOutput(
            platform: .facebook,
            listingText: listingText,
            instructions: instructions,
            estimatedFees: calculateFacebookFees(price: item.buyItNowPrice)
        )
    }

    // MARK: - StockX
    private static func generateStockXListing(item: EbayListing) -> MarketplaceListingOutput {
        let listingText = """
        Product: \(item.title)
        
        Condition: \(mapConditionToStockX(item.condition))/10
        
        Description:
        \(item.description)
        
        Ask Price: $\(item.formattedPrice)
        
        Notes: Authentic item in \(item.condition.lowercased()) condition. All original accessories included where applicable.
        """

        let instructions = """
        StockX Instructions:
        1. Go to StockX.com and search for your item
        2. If found, click "Sell" on the product page
        3. Select condition and set your Ask price
        4. If not found, use "Sell Something New"
        5. Upload photos and copy description above
        """

        return MarketplaceListingOutput(
            platform: .stockx,
            listingText: listingText,
            instructions: instructions,
            estimatedFees: calculateStockXFees(price: item.buyItNowPrice)
        )
    }

    // MARK: - Amazon
    private static func generateAmazonListing(item: EbayListing) -> MarketplaceListingOutput {
        let listingText = """
        Product Title: \(item.title)
        
        Condition: \(item.condition)
        
        Bullet Points:
        • \(item.condition) condition with full functionality
        • \(extractKeyFeature(from: item.description))
        • Fast shipping from Kansas City
        • Satisfaction guaranteed
        • Authentic product
        
        Description:
        \(item.description)
        
        Price: $\(item.formattedPrice)
        
        SKU: QF-\(UUID().uuidString.prefix(8))
        """

        let instructions = """
        Amazon Seller Central Instructions:
        1. Log into Amazon Seller Central
        2. Go to "Add a Product"
        3. Search for existing listing or create new
        4. Upload photos and copy details above
        5. Set price and inventory
        6. Review and submit for approval
        """

        return MarketplaceListingOutput(
            platform: .amazon,
            listingText: listingText,
            instructions: instructions,
            estimatedFees: calculateAmazonFees(price: item.buyItNowPrice)
        )
    }

    // MARK: - Etsy
    private static func generateEtsyListing(item: EbayListing) -> MarketplaceListingOutput {
        let listingText = """
        \(item.title) | \(item.condition) Condition | Vintage Electronics
        
        ✨ CONDITION: \(item.condition)
        
        📝 DESCRIPTION:
        \(item.description)
        
        This unique piece is perfect for collectors or anyone looking for quality vintage electronics!
        
        💰 PRICE: $\(item.formattedPrice)
        
        📦 SHIPPING: \(item.formattedShippingCost)
        
        🏷️ TAGS: vintage, electronics, \(extractTagsFromTitle(item.title)), retro, collectible
        
        ⭐ Ships from Kansas with care and fast handling!
        """

        let instructions = """
        Etsy Instructions:
        1. Go to Etsy.com and click "Sell on Etsy"
        2. Click "Add a listing"
        3. Upload your photos
        4. Copy title and description above
        5. Set category to "Vintage > Electronics"
        6. Add tags from the listing above
        7. Set price and shipping
        8. Publish!
        """

        return MarketplaceListingOutput(
            platform: .etsy,
            listingText: listingText,
            instructions: instructions,
            estimatedFees: calculateEtsyFees(price: item.buyItNowPrice)
        )
    }

    // MARK: - Mercari
    private static func generateMercariListing(item: EbayListing) -> MarketplaceListingOutput {
        let listingText = """
        \(item.title)
        
        Condition: \(item.condition)
        
        \(item.description)
        
        Price: $\(item.formattedPrice)
        Shipping: $\(String(format: "%.2f", item.shippingCost))
        
        • Fast shipping
        • Smoke-free home
        • \(item.condition) condition as shown
        • Questions welcome!
        
        #\(item.category.replacingOccurrences(of: " ", with: ""))
        """

        let instructions = """
        Mercari Instructions:
        1. Open Mercari app or website
        2. Tap "Sell" button
        3. Upload your saved photos
        4. Copy and paste details above
        5. Select category and condition
        6. Set price and shipping
        7. List item!
        """

        return MarketplaceListingOutput(
            platform: .mercari,
            listingText: listingText,
            instructions: instructions,
            estimatedFees: calculateMercariFees(price: item.buyItNowPrice)
        )
    }

    // MARK: - Poshmark
    private static func generatePoshmarkListing(item: EbayListing) -> MarketplaceListingOutput {
        let listingText = """
        \(item.title)
        
        ✨ Condition: \(item.condition)
        
        💫 \(item.description)
        
        🛍️ Price: $\(item.formattedPrice)
        
        📦 Ships same/next day
        💕 Smoke-free, pet-free home
        🌟 Bundle for discount!
        ❓ Questions? Just ask!
        
        #poshmarkfinds #\(extractPoshmarkTags(from: item.title))
        """

        let instructions = """
        Poshmark Instructions:
        1. Open Poshmark app
        2. Tap the "+" to create listing
        3. Upload your photos
        4. Copy title and description above
        5. Select appropriate category
        6. Set size (if applicable) and price
        7. Share to your closet!
        """

        return MarketplaceListingOutput(
            platform: .poshmark,
            listingText: listingText,
            instructions: instructions,
            estimatedFees: calculatePoshmarkFees(price: item.buyItNowPrice)
        )
    }

    // MARK: - Depop
    private static func generateDepopListing(item: EbayListing) -> MarketplaceListingOutput {
        let listingText = """
        \(item.title) ✨
        
        condition: \(item.condition.lowercased()) 💫
        
        \(item.description)
        
        price: $\(item.formattedPrice) 💰
        
        ships fast 📦
        dm for questions 💌
        
        #depop #vintage #\(extractDepopTags(from: item.title)) #secondhand #sustainable
        """

        let instructions = """
        Depop Instructions:
        1. Open Depop app
        2. Tap camera icon to sell
        3. Upload your photos with editing
        4. Copy description above
        5. Add relevant hashtags
        6. Set price and shipping
        7. Post to your shop!
        """

        return MarketplaceListingOutput(
            platform: .depop,
            listingText: listingText,
            instructions: instructions,
            estimatedFees: calculateDepopFees(price: item.buyItNowPrice)
        )
    }

    // MARK: - Helper Functions
    private static func mapConditionToStockX(_ condition: String) -> String {
        switch condition.lowercased() {
        case "new": return "10"
        case "like new": return "9"
        case "good": return "8"
        case "fair": return "6"
        case "poor": return "4"
        default: return "8"
        }
    }

    private static func extractKeyFeature(from description: String) -> String {
        let sentences = description.components(separatedBy: ". ")
        return sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "High quality item"
    }

    private static func extractTagsFromTitle(_ title: String) -> String {
        let words = title.lowercased().components(separatedBy: " ")
        let relevantWords = words.filter { $0.count > 3 && !["with", "from", "this", "that"].contains($0) }
        return relevantWords.prefix(3).joined(separator: ", ")
    }

    private static func extractPoshmarkTags(from title: String) -> String {
        let words = title.lowercased().components(separatedBy: " ")
        return words.filter { $0.count > 2 }.prefix(2).joined(separator: " #")
    }

    private static func extractDepopTags(from title: String) -> String {
        let words = title.lowercased().components(separatedBy: " ")
        return words.filter { $0.count > 2 }.prefix(2).joined(separator: " #")
    }

    // MARK: - Fee Calculations
    private static func calculateEbayFees(price: Double) -> String {
        let fee = price * 0.1295 + price * 0.029 + 0.30
        return "~$\(String(format: "%.2f", fee)) (12.95% + 2.9% + $0.30)"
    }

    private static func calculateFacebookFees(price: Double) -> String {
        if price <= 8.00 {
            let fee = price * 0.05
            return "~$\(String(format: "%.2f", fee)) (5%)"
        } else {
            let fee = price * 0.029 + 0.30
            return "~$\(String(format: "%.2f", fee)) (2.9% + $0.30)"
        }
    }

    private static func calculateStockXFees(price: Double) -> String {
        let fee = price * 0.095 + price * 0.03
        return "~$\(String(format: "%.2f", fee)) (9.5% + 3%)"
    }

    private static func calculateAmazonFees(price: Double) -> String {
        let fee = price * 0.15
        return "~$\(String(format: "%.2f", fee)) (~15%)"
    }

    private static func calculateEtsyFees(price: Double) -> String {
        let fee = price * 0.065 + price * 0.03 + 0.25
        return "~$\(String(format: "%.2f", fee)) (6.5% + 3% + $0.25)"
    }

    private static func calculateMercariFees(price: Double) -> String {
        let fee = price * 0.10 + price * 0.029 + 0.30
        return "~$\(String(format: "%.2f", fee)) (10% + 2.9% + $0.30)"
    }

    private static func calculatePoshmarkFees(price: Double) -> String {
        let fee = price < 15 ? 2.95 : price * 0.20
        return price < 15 ? "$2.95 flat fee" : "~$\(String(format: "%.2f", fee)) (20%)"
    }

    private static func calculateDepopFees(price: Double) -> String {
        let fee = price * 0.10
        return "~$\(String(format: "%.2f", fee)) (10%)"
    }
}

// MARK: - Output Model
struct MarketplaceListingOutput {
    let platform: Marketplace
    let listingText: String
    let instructions: String
    let estimatedFees: String

    var copyableContent: String {
        return """
        \(listingText)
        
        ---
        
        \(instructions)
        
        Estimated Fees: \(estimatedFees)
        
        Generated by QuickFlip
        """
    }
}
