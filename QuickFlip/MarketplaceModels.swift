//
//  MarketplaceModels.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

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

    var iconName: String {
        switch self {
        case .ebay: return "cart.fill"
        case .facebook: return "person.2.fill"
        case .amazon: return "shippingbox.fill"
        case .stockx: return "sneaker.fill"
        case .etsy: return "heart.fill"
        case .mercari: return "bag.fill"
        case .poshmark: return "tshirt.fill"
        case .depop: return "star.fill"
        }
    }

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
}
