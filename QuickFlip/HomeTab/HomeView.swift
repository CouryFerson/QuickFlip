//
//  HomeView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.title2)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightCard: View {
    let title: String
    let subtitle: String?
    let content: String
    let icon: String?
    let color: Color

    init(title: String, subtitle: String? = nil, content: String, icon: String? = nil, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.icon = icon
        self.color = color
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(content)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding()
        .frame(width: 140, height: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct RecentItemCard: View {
    let itemName: String
    let bestPrice: String
    let marketplace: String
    let timeAgo: String

    var body: some View {
        HStack {
            // Placeholder for item image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(itemName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Best on \(marketplace)")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(bestPrice)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
