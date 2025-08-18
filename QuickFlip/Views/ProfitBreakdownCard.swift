//
//  ProfitBreakdownCard.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct ProfitBreakdownCard: View {
    let breakdown: ProfitBreakdown
    let rank: Int

    var body: some View {
        VStack {
            HStack {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rank == 1 ? Color.yellow : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)

                    Text("\(rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(rank == 1 ? .black : .gray)
                }

                // Marketplace info
                VStack(alignment: .leading, spacing: 2) {
                    Text(breakdown.marketplace.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(breakdown.fees.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Profit info
                VStack(alignment: .trailing, spacing: 2) {
                    Text(breakdown.formattedNetProfit)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(breakdown.profitColor)

                    Text("\(breakdown.formattedProfitMargin) margin")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Breakdown details
            HStack {
                Text("Sale: \(breakdown.formattedSellingPrice)")
                    .font(.caption)
                    .foregroundColor(.green)

                Text("Fees: -\(breakdown.fees.formattedTotalFees)")
                    .font(.caption)
                    .foregroundColor(.red)

                if breakdown.costBasis > 0 {
                    Text("Cost: -\(String(format: "$%.2f", breakdown.costBasis))")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if breakdown.shippingCost > 0 {
                    Text("Ship: -\(String(format: "$%.2f", breakdown.shippingCost))")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(rank == 1 ? Color.yellow.opacity(0.1) : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rank == 1 ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
}
