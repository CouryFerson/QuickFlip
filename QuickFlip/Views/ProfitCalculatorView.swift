//
//  ProfitCalculatorView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct ProfitCalculatorView: View {
    let priceAnalysis: MarketplacePriceAnalysis
    let itemAnalysis: ItemAnalysis
    let capturedImage: UIImage
    @State private var costBasis: Double = 0
    @State private var shippingCost: Double = 0
    @State private var profitBreakdowns: [ProfitBreakdown] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("💰 Profit Calculator")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter your costs to see real profit after fees")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("What you paid")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("$0.00", value: $costBasis, format: .currency(code: "USD"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }

                        VStack(alignment: .leading) {
                            Text("Shipping cost")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("$0.00", value: $shippingCost, format: .currency(code: "USD"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }

                    if costBasis == 0 {
                        Text("💡 Enter $0 if you got this item for free")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Results Section
                if !profitBreakdowns.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("🏆 PROFIT RANKING")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Spacer()
                            Text("Best to Worst")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        ForEach(Array(profitBreakdowns.enumerated()), id: \.offset) { index, breakdown in
                            ProfitBreakdownCard(breakdown: breakdown, rank: index + 1)
                        }

                        // Summary
                        if let bestProfit = profitBreakdowns.first,
                           let worstProfit = profitBreakdowns.last {

                            VStack(alignment: .leading, spacing: 8) {
                                Text("💡 INSIGHTS")
                                    .font(.headline)
                                    .foregroundColor(.blue)

                                Text("Best marketplace: \(bestProfit.marketplace.rawValue) (\(bestProfit.formattedNetProfit) profit)")
                                    .font(.subheadline)

                                if bestProfit.netProfit > worstProfit.netProfit {
                                    let difference = bestProfit.netProfit - worstProfit.netProfit
                                    Text("You'd make \(String(format: "$%.2f", difference)) more than the worst option")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }

                                let avgProfit = profitBreakdowns.map(\.netProfit).reduce(0, +) / Double(profitBreakdowns.count)
                                Text("Average profit across all platforms: \(String(format: "$%.2f", avgProfit))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    if let bestProfit = profitBreakdowns.first {
                        NavigationLink(
                            destination: ListingPreparationView(
                                itemAnalysis: itemAnalysis,
                                capturedImage: capturedImage,
                                selectedMarketplace: bestProfit.marketplace
                            )
                        ) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)

                                Text("List on \(bestProfit.marketplace.rawValue)")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()

                                Text("Best Profit")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(bestProfit.marketplace.color)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Profit Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: costBasis) { _, _ in calculateProfits() }
        .onChange(of: shippingCost) { _, _ in calculateProfits() }
        .onAppear { calculateProfits() }
    }

    private func calculateProfits() {
        profitBreakdowns = MarketplaceFeeCalculator.calculateAllMarketplaces(
            prices: priceAnalysis.averagePrices,
            costBasis: costBasis,
            shippingCost: shippingCost
        )
    }
}

