//
//  MarketplaceFeeCalculator.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//  Updated: 8/21/25 - Fixed fee structures for 2025
//

import Foundation

struct MarketplaceFeeCalculator {

    static func calculateProfit(
        sellingPrice: Double,
        costBasis: Double = 0,
        shippingCost: Double = 0,
        marketplace: Marketplace
    ) -> ProfitBreakdown {

        let fees = calculateFees(sellingPrice: sellingPrice, marketplace: marketplace)
        let totalCosts = costBasis + shippingCost + fees.totalFees
        let netProfit = sellingPrice - totalCosts
        let profitMargin = sellingPrice > 0 ? (netProfit / sellingPrice) * 100 : 0

        return ProfitBreakdown(
            marketplace: marketplace,
            sellingPrice: sellingPrice,
            costBasis: costBasis,
            shippingCost: shippingCost,
            fees: fees,
            netProfit: netProfit,
            profitMargin: profitMargin
        )
    }

    static func calculateAllMarketplaces(
        prices: [Marketplace: Double],
        costBasis: Double = 0,
        shippingCost: Double = 0
    ) -> [ProfitBreakdown] {

        return prices.compactMap { marketplace, price in
            calculateProfit(
                sellingPrice: price,
                costBasis: costBasis,
                shippingCost: shippingCost,
                marketplace: marketplace
            )
        }.sorted { $0.netProfit > $1.netProfit }
    }

    private static func calculateFees(sellingPrice: Double, marketplace: Marketplace) -> MarketplaceFees {
        switch marketplace {
        case .ebay:
            // Updated 2025: Final value fee varies by category (8-15%), payment processing included
            // Using 13% as average for most categories + $0.40 per order fee
            let finalValueFee = sellingPrice * 0.13 // 13% average
            let perOrderFee = sellingPrice > 10.00 ? 0.40 : 0.30
            return MarketplaceFees(
                sellingFee: finalValueFee + perOrderFee,
                paymentFee: 0, // Included in final value fee
                description: "eBay ~13% + $\(String(format: "%.2f", perOrderFee)) order fee"
            )

        case .facebook:
            // Updated April 2024: 10% or $0.80 minimum for shipped items, free for local pickup
            let fee = max(sellingPrice * 0.10, 0.80)
            return MarketplaceFees(
                sellingFee: fee,
                paymentFee: 0, // Included in selling fee
                description: "Facebook 10% (min $0.80) shipped"
            )

        case .stockx:
            // Updated July 2023: Base 9% fee, tiered system available
            // Using Level 1 rates (most sellers start here)
            let sellingFee = sellingPrice * 0.09 // 9% base rate
            return MarketplaceFees(
                sellingFee: sellingFee,
                paymentFee: 0, // Payment processing temporarily waived
                description: "StockX 9% base rate"
            )

        case .mercari:
            // Updated January 2025: 10% flat fee, payment processing included
            let sellingFee = sellingPrice * 0.10 // 10%
            return MarketplaceFees(
                sellingFee: sellingFee,
                paymentFee: 0, // Included in 10% fee
                description: "Mercari 10% (includes processing)"
            )

        case .poshmark:
            // Current 2025: Still $2.95 flat fee under $15, 20% over $15
            let fee = sellingPrice < 15.00 ? 2.95 : sellingPrice * 0.20
            return MarketplaceFees(
                sellingFee: fee,
                paymentFee: 0, // Included in commission
                description: sellingPrice < 15.00 ? "Poshmark $2.95 flat fee" : "Poshmark 20% commission"
            )

        case .etsy:
            // Current 2025: Transaction fee + payment processing
            let transactionFee = sellingPrice * 0.065 // 6.5%
            let paymentFee = sellingPrice * 0.03 + 0.25 // 3% + $0.25
            return MarketplaceFees(
                sellingFee: transactionFee,
                paymentFee: paymentFee,
                description: "Etsy 6.5% + Payment 3%"
            )

        case .amazon:
            // Simplified - Amazon fees vary significantly by category
            // Using 15% as average referral fee
            let referralFee = sellingPrice * 0.15 // ~15% average
            return MarketplaceFees(
                sellingFee: referralFee,
                paymentFee: 0, // Included in referral fee
                description: "Amazon ~15% referral fee"
            )

        case .depop:
            // Current 2025: 10% commission
            let fee = sellingPrice * 0.10 // 10%
            return MarketplaceFees(
                sellingFee: fee,
                paymentFee: 0, // Included in commission
                description: "Depop 10% commission"
            )
        }
    }
}
