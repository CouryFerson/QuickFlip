//
//  ProfitBreakdown.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct ProfitBreakdown {
    let marketplace: Marketplace
    let sellingPrice: Double
    let costBasis: Double
    let shippingCost: Double
    let fees: MarketplaceFees
    let netProfit: Double
    let profitMargin: Double

    var formattedSellingPrice: String {
        return String(format: "$%.2f", sellingPrice)
    }

    var formattedNetProfit: String {
        return String(format: "$%.2f", netProfit)
    }

    var formattedProfitMargin: String {
        return String(format: "%.1f%%", profitMargin)
    }

    var profitColor: Color {
        if netProfit > 0 { return .green }
        if netProfit == 0 { return .orange }
        return .red
    }

    var isProfiitable: Bool {
        return netProfit > 0
    }
}
