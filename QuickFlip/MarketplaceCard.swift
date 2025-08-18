//
//  MarketplaceCard.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct MarketplaceCard: View {
    let marketplace: Marketplace
    let isRecommended: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(marketplace.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: marketplace.iconName)
                    .font(.title2)
                    .foregroundColor(marketplace.color)
            }

            VStack(spacing: 4) {
                HStack {
                    Text(marketplace.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if isRecommended {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text(marketplace.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isRecommended ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}
