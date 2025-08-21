//
//  Untitled.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/21/25.
//

import UIKit

class MarketplaceIntegrationManager {

    // MARK: - Universal Marketplace Posting
    static func postToMarketplace(_ marketplace: Marketplace, listing: UniversalListing, image: UIImage) {
        switch marketplace.integrationLevel {
        case .fullAPI:
            handleAPIPosting(marketplace, listing: listing, image: image)
        case .deepLink:
            handleDeepLinkPosting(marketplace, listing: listing, image: image)
        case .smartClipboard:
            handleSmartClipboardPosting(marketplace, listing: listing, image: image)
        }
    }

    // MARK: - API Integration Handler
    static func handleAPIPosting(_ marketplace: Marketplace, listing: UniversalListing, image: UIImage) {
        switch marketplace {
        case .ebay:
            // Your existing eBay API integration
            print("Posting to eBay via API...")
            // Call your existing eBay posting function

        default:
            // Fallback to deep linking
            handleDeepLinkPosting(marketplace, listing: listing, image: image)
        }
    }

    // MARK: - Deep Link Integration Handler
    static func handleDeepLinkPosting(_ marketplace: Marketplace, listing: UniversalListing, image: UIImage) {
        // Try app first
        if let appURL = createAppURL(for: marketplace, listing: listing),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            // Copy optimized listing to clipboard as backup
            copyOptimizedListing(for: marketplace, listing: listing)
            return
        }

        // Fallback to web + clipboard
        handleSmartClipboardPosting(marketplace, listing: listing, image: image)
    }

    // MARK: - Smart Clipboard Handler
    static func handleSmartClipboardPosting(_ marketplace: Marketplace, listing: UniversalListing, image: UIImage) {
        // Copy marketplace-specific optimized text
        copyOptimizedListing(for: marketplace, listing: listing)

        // Show instructions
        showPostingInstructions(for: marketplace)

        // Open marketplace after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let url = URL(string: marketplace.webCreateURL) {
                UIApplication.shared.open(url)
            }
        }
    }

    // MARK: - URL Creation
    static func createAppURL(for marketplace: Marketplace, listing: UniversalListing) -> URL? {
        guard let scheme = marketplace.appURLScheme else { return nil }

        switch marketplace {
        case .facebook:
            return createFacebookAppURL(listing: listing)
        case .mercari:
            return URL(string: "mercari://sell")
        case .poshmark:
            return URL(string: "poshmark://create")
        case .depop:
            return URL(string: "depop://sell")
        default:
            return URL(string: scheme)
        }
    }

    static func createFacebookAppURL(listing: UniversalListing) -> URL? {
        var components = URLComponents()
        components.scheme = "fb"
        components.host = "marketplace"
        components.path = "/create"

        components.queryItems = [
            URLQueryItem(name: "title", value: listing.title),
            URLQueryItem(name: "price", value: String(format: "%.0f", listing.price)),
            URLQueryItem(name: "description", value: listing.description),
            URLQueryItem(name: "condition", value: listing.condition),
            URLQueryItem(name: "location", value: listing.location)
        ]

        return components.url
    }

    // MARK: - Optimized Text Generation
    static func copyOptimizedListing(for marketplace: Marketplace, listing: UniversalListing) {
        let optimizedText = createOptimizedText(for: marketplace, listing: listing)
        UIPasteboard.general.string = optimizedText
    }

    static func createOptimizedText(for marketplace: Marketplace, listing: UniversalListing) -> String {
        switch marketplace {
        case .facebook:
            return createFacebookText(listing)
        case .mercari:
            return createMercariText(listing)
        case .poshmark:
            return createPoshmarkText(listing)
        case .depop:
            return createDepopText(listing)
        case .stockx:
            return createStockXText(listing)
        case .etsy:
            return createEtsyText(listing)
        case .amazon:
            return createAmazonText(listing)
        case .ebay:
            return createEbayText(listing)
        }
    }

    // MARK: - Platform-Specific Text Generators

    static func createFacebookText(_ listing: UniversalListing) -> String {
        return """
        💰 \(listing.title)
        
        $\(String(format: "%.0f", listing.price)) • \(listing.condition)
        
        \(listing.description)
        
        📍 \(listing.location)
        \(listing.isShippingAvailable ? "🚚 Shipping available" : "🤝 Local pickup only")
        
        💬 Message me if interested!
        
        #\(listing.category.replacingOccurrences(of: " ", with: ""))
        """
    }

    static func createMercariText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        ✨ Condition: \(listing.condition)
        📦 \(listing.isShippingAvailable ? "Fast shipping available!" : "Local pickup")
        
        💝 Bundle for discounts!
        ⭐ Check out my other items
        
        #\(listing.category) #Mercari
        """
    }

    static func createPoshmarkText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title) 💕
        
        \(listing.description)
        
        ✨ Condition: \(listing.condition)
        💖 From smoke-free home
        📏 Measurements available upon request
        💝 Bundle 2+ items for 15% off!
        📦 Ships same/next day
        
        #poshmark #\(listing.category.lowercased())
        """
    }

    static func createDepopText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title) ✨
        
        \(listing.description)
        
        condition: \(listing.condition.lowercased()) 💫
        \(listing.isShippingAvailable ? "ships worldwide 📦" : "pickup only 📍")
        
        dm for more pics/info 💌
        no returns 🚫
        
        #depop #\(listing.category.lowercased()) #vintage #y2k
        """
    }

    static func createStockXText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        Condition: \(listing.condition)
        Size: [Add size here]
        Authentication: StockX verified
        
        Lowest ask pricing
        Fast shipping with StockX authentication
        
        #StockX #Sneakers #Authentic
        """
    }

    static func createEtsyText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        This unique \(listing.category.lowercased()) is in \(listing.condition.lowercased()) condition.
        
        ✨ Handpicked with care
        📦 Ships within 1-2 business days
        💝 Perfect for gifting
        🌟 Questions? Message me anytime!
        
        #handmade #vintage #unique #\(listing.category.lowercased())
        """
    }

    static func createAmazonText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        Condition: \(listing.condition)
        Fast shipping with Amazon Prime
        Customer satisfaction guaranteed
        
        Professional seller with high ratings
        30-day return policy
        
        Keywords: \(listing.category), \(listing.condition.lowercased())
        """
    }

    static func createEbayText(_ listing: UniversalListing) -> String {
        return """
        \(listing.title)
        
        \(listing.description)
        
        Condition: \(listing.condition)
        \(listing.isShippingAvailable ? "Fast & Free Shipping!" : "Local pickup available")
        
        ✅ Same day handling
        ✅ 30-day returns accepted
        ✅ Top rated seller
        
        Check out my other items for combined shipping!
        """
    }

    // MARK: - Helper Functions
    static func showPostingInstructions(for marketplace: Marketplace) {
        let title = "Ready to post to \(marketplace.rawValue)! 🚀"
        let message = "Your optimized listing is copied to clipboard. \(marketplace.rawValue) will open in a moment - just paste and add your photos!"

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - Universal Listing Model
struct UniversalListing {
    let title: String
    let description: String
    let price: Double
    let category: String
    let condition: String
    let location: String
    let isShippingAvailable: Bool
    let tags: [String]

    // Convert from your existing FacebookListing
    init(from facebookListing: FacebookListing, category: String, condition: String, location: String, shipping: Bool) {
        self.title = facebookListing.title
        self.description = facebookListing.description
        self.price = facebookListing.price
        self.category = category
        self.condition = condition
        self.location = location
        self.isShippingAvailable = shipping
        self.tags = []
    }
}
