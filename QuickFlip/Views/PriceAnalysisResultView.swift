//
//  PriceAnalysisResultView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct PriceAnalysisResultView: View {
    let analysis: MarketplacePriceAnalysis
    let onSelectMarketplace: (Marketplace) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Recommended Marketplace
            VStack(spacing: 8) {
                HStack {
                    Text("🏆 BEST MARKETPLACE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Spacer()

                    Text(analysis.confidence.displayText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(analysis.confidence.color.opacity(0.2))
                        .foregroundColor(analysis.confidence.color)
                        .cornerRadius(8)
                }

                NavigationLink(
                    destination: ListingPreparationView(
                        itemAnalysis: ItemAnalysis(
                            itemName: "",
                            condition: "",
                            description: "",
                            estimatedValue: "",
                            category: ""
                        ),
                        capturedImage: UIImage(),
                        selectedMarketplace: analysis.recommendedMarketplace
                    )
                ) {
                    HStack {
                        Image(systemName: analysis.recommendedMarketplace.iconName)
                            .font(.title2)
                            .foregroundColor(analysis.recommendedMarketplace.color)

                        VStack(alignment: .leading) {
                            Text(analysis.recommendedMarketplace.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)

                            if let price = analysis.averagePrices[analysis.recommendedMarketplace] {
                                Text("Avg: $\(String(format: "%.2f", price))")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(analysis.recommendedMarketplace.color.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(analysis.recommendedMarketplace.color, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Reasoning
            Text(analysis.reasoning)
                .font(.caption)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)

            // Price Comparison
            VStack(alignment: .leading, spacing: 8) {
                Text("Price Comparison:")
                    .font(.caption)
                    .fontWeight(.semibold)

                ForEach(analysis.averagePrices.sorted(by: { $0.value > $1.value }), id: \.key) { marketplace, price in
                    HStack {
                        Text(marketplace.rawValue)
                            .font(.caption)
                        Spacer()
                        Text("$\(String(format: "%.2f", price))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(marketplace == analysis.recommendedMarketplace ? .green : .gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)

                Text("Tap 'Calculate Real Profit' below to see profit after marketplace fees")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }
}
