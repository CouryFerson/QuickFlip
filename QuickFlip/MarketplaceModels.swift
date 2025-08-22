import SwiftUI

// MARK: - Marketplace Models

enum Marketplace: String, CaseIterable, Identifiable {
    case ebay = "eBay"
    case facebook = "Facebook Marketplace"
    case amazon = "Amazon"
    case stockx = "StockX"
    case etsy = "Etsy"
    case mercari = "Mercari"
    case poshmark = "Poshmark"
    case depop = "Depop"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .ebay: return .blue
        case .facebook: return .blue
        case .amazon: return .orange
        case .stockx: return .green
        case .etsy: return .orange
        case .mercari: return .red
        case .poshmark: return .pink
        case .depop: return .purple
        }
    }

    var description: String {
        switch self {
        case .ebay: return "Auctions & Buy It Now"
        case .facebook: return "Local community sales"
        case .amazon: return "Global marketplace"
        case .stockx: return "Sneakers & streetwear"
        case .etsy: return "Handmade & vintage"
        case .mercari: return "Simple selling"
        case .poshmark: return "Fashion & lifestyle"
        case .depop: return "Gen Z marketplace"
        }
    }

    var systemImage: String {
        switch self {
        case .ebay: return "globe"
        case .amazon: return "shippingbox"
        case .etsy: return "heart"
        case .facebook: return "person.2"
        case .poshmark: return "tshirt"
        case .mercari: return "bag"
        case .depop: return "tshirt.fill"
        case .stockx: return "shoe"
        }
    }

    // MARK: - Integration Properties

    var hasNativeApp: Bool {
        switch self {
        case .ebay, .facebook, .amazon, .stockx, .etsy, .mercari, .poshmark, .depop:
            return true
        }
    }

    var integrationLevel: IntegrationLevel {
        switch self {
        case .ebay:
            return .fullAPI // You already have this
        case .facebook, .mercari, .poshmark, .depop:
            return .deepLink
        case .amazon, .stockx, .etsy:
            return .smartClipboard
        }
    }

    var brandColor: String {
        switch self {
        case .ebay: return "#E53238"
        case .facebook: return "#1877F2"
        case .amazon: return "#FF9900"
        case .stockx: return "#00D084"
        case .etsy: return "#F16521"
        case .mercari: return "#FF6600"
        case .poshmark: return "#731A5B"
        case .depop: return "#000000"
        }
    }

    var appURLScheme: String? {
        switch self {
        case .ebay: return "ebay://"
        case .facebook: return "fb://marketplace"
        case .amazon: return "amazon://"
        case .stockx: return "stockx://"
        case .etsy: return "etsy://"
        case .mercari: return "mercari://"
        case .poshmark: return "poshmark://"
        case .depop: return "depop://"
        }
    }

    var webCreateURL: String {
        switch self {
        case .ebay: return "https://www.ebay.com/sl/sell"
        case .facebook: return "https://www.facebook.com/marketplace/create"
        case .amazon: return "https://sellercentral.amazon.com/inventory/add-products"
        case .stockx: return "https://stockx.com/sell"
        case .etsy: return "https://www.etsy.com/your/shops/me/tools/listings/new"
        case .mercari: return "https://www.mercari.com/sell/"
        case .poshmark: return "https://poshmark.com/create-listing"
        case .depop: return "https://www.depop.com/sell/"
        }
    }

    // MARK: - Category Mapping

    func mapCategory(_ category: String) -> String {
        let categoryLower = category.lowercased()

        switch self {
        case .ebay:
            return mapEbayCategory(categoryLower)
        case .facebook:
            return mapFacebookCategory(categoryLower)
        case .amazon:
            return mapAmazonCategory(categoryLower)
        case .stockx:
            return mapStockXCategory(categoryLower)
        case .etsy:
            return mapEtsyCategory(categoryLower)
        case .mercari, .poshmark, .depop:
            return mapGeneralCategory(categoryLower)
        }
    }

    private func mapEbayCategory(_ category: String) -> String {
        if category.contains("electronics") || category.contains("phone") || category.contains("computer") {
            return "Electronics"
        } else if category.contains("clothing") || category.contains("fashion") {
            return "Clothing, Shoes & Accessories"
        } else if category.contains("home") || category.contains("furniture") {
            return "Home & Garden"
        } else if category.contains("car") || category.contains("vehicle") {
            return "eBay Motors"
        } else if category.contains("sport") || category.contains("fitness") {
            return "Sporting Goods"
        } else {
            return "Everything Else"
        }
    }

    private func mapFacebookCategory(_ category: String) -> String {
        if category.contains("electronics") || category.contains("phone") || category.contains("computer") {
            return "Electronics"
        } else if category.contains("clothing") || category.contains("fashion") {
            return "Clothing & Accessories"
        } else if category.contains("home") || category.contains("furniture") {
            return "Home & Garden"
        } else if category.contains("car") || category.contains("vehicle") {
            return "Vehicles"
        } else if category.contains("sport") || category.contains("fitness") {
            return "Sports"
        } else {
            return "Other"
        }
    }

    private func mapAmazonCategory(_ category: String) -> String {
        if category.contains("electronics") {
            return "Electronics"
        } else if category.contains("clothing") || category.contains("fashion") {
            return "Clothing & Accessories"
        } else if category.contains("home") {
            return "Home & Kitchen"
        } else if category.contains("sport") {
            return "Sports & Outdoors"
        } else {
            return "Everything Else"
        }
    }

    private func mapStockXCategory(_ category: String) -> String {
        if category.contains("sneaker") || category.contains("shoe") {
            return "Sneakers"
        } else if category.contains("clothing") || category.contains("apparel") {
            return "Apparel"
        } else if category.contains("accessories") {
            return "Accessories"
        } else {
            return "Electronics"
        }
    }

    private func mapEtsyCategory(_ category: String) -> String {
        if category.contains("jewelry") {
            return "Jewelry"
        } else if category.contains("clothing") {
            return "Clothing"
        } else if category.contains("home") {
            return "Home & Living"
        } else if category.contains("art") {
            return "Art & Collectibles"
        } else {
            return "Craft Supplies"
        }
    }

    private func mapGeneralCategory(_ category: String) -> String {
        if category.contains("electronics") {
            return "Electronics"
        } else if category.contains("clothing") || category.contains("fashion") {
            return "Fashion"
        } else if category.contains("home") {
            return "Home"
        } else if category.contains("sport") {
            return "Sports"
        } else {
            return "Other"
        }
    }
}

// MARK: - Integration Level Enum

enum IntegrationLevel {
    case fullAPI          // Direct API posting (like eBay)
    case deepLink         // App deep linking with pre-filled data
    case smartClipboard   // Optimized clipboard + instructions

    var description: String {
        switch self {
        case .fullAPI:
            return "Direct posting via API"
        case .deepLink:
            return "Opens app with pre-filled data"
        case .smartClipboard:
            return "Copies optimized listing text"
        }
    }

    var icon: String {
        switch self {
        case .fullAPI:
            return "bolt.circle.fill"
        case .deepLink:
            return "arrow.up.right.circle.fill"
        case .smartClipboard:
            return "doc.on.clipboard.fill"
        }
    }
}
