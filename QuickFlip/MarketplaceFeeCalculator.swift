//
//  MarketplaceFeeCalculator.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
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
            let sellingFee = sellingPrice * 0.1295 // 12.95%
            let paymentFee = sellingPrice * 0.029 + 0.30 // 2.9% + $0.30
            return MarketplaceFees(
                sellingFee: sellingFee,
                paymentFee: paymentFee,
                description: "eBay 12.95% + Payment 2.9%"
            )

        case .facebook:
            let fee = sellingPrice <= 8.00 ? sellingPrice * 0.05 : sellingPrice * 0.029 + 0.30
            return MarketplaceFees(
                sellingFee: fee,
                paymentFee: 0,
                description: sellingPrice <= 8.00 ? "5% fee" : "2.9% + $0.30"
            )

        case .stockx:
            let sellingFee = sellingPrice * 0.095 // 9.5%
            let paymentFee = sellingPrice * 0.03 // 3%
            return MarketplaceFees(
                sellingFee: sellingFee,
                paymentFee: paymentFee,
                description: "StockX 9.5% + Payment 3%"
            )

        case .mercari:
            let sellingFee = sellingPrice * 0.10 // 10%
            let paymentFee = sellingPrice * 0.029 + 0.30 // 2.9% + $0.30
            return MarketplaceFees(
                sellingFee: sellingFee,
                paymentFee: paymentFee,
                description: "Mercari 10% + Payment 2.9%"
            )

        case .poshmark:
            let fee = sellingPrice < 15.00 ? 2.95 : sellingPrice * 0.20
            return MarketplaceFees(
                sellingFee: fee,
                paymentFee: 0,
                description: sellingPrice < 15.00 ? "$2.95 flat fee" : "20% commission"
            )

        case .etsy:
            let transactionFee = sellingPrice * 0.065 // 6.5%
            let paymentFee = sellingPrice * 0.03 + 0.25 // 3% + $0.25
            return MarketplaceFees(
                sellingFee: transactionFee,
                paymentFee: paymentFee,
                description: "Etsy 6.5% + Payment 3%"
            )

        case .amazon:
            // Simplified - Amazon fees are complex
            let referralFee = sellingPrice * 0.15 // ~15% average
            return MarketplaceFees(
                sellingFee: referralFee,
                paymentFee: 0,
                description: "Amazon ~15% referral fee"
            )

        case .depop:
            let fee = sellingPrice * 0.10 // 10%
            return MarketplaceFees(
                sellingFee: fee,
                paymentFee: 0,
                description: "Depop 10% commission"
            )
        }
    }
}
