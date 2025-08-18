//
//  ItemResultView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct ItemResultView: View {
    let result: ItemAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Item Name
            Text(result.itemName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Condition and Price
            HStack {
                if !result.condition.isEmpty {
                    Text("Condition: \(result.condition)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }

                Spacer()

                if !result.estimatedValue.isEmpty {
                    Text(result.estimatedValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }

            // Description
            if !result.description.isEmpty {
                Text(result.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
            }

            // Visual indicator this is tappable
            HStack {
                Text("Choose Marketplace")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(8)
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }
}
