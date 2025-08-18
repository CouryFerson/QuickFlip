//
//  MarketplaceFees.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

struct MarketplaceFees {
    let sellingFee: Double
    let paymentFee: Double
    let description: String

    var totalFees: Double {
        return sellingFee + paymentFee
    }

    var formattedTotalFees: String {
        return String(format: "$%.2f", totalFees)
    }
}
