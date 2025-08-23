//
//  HomeView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

struct HomeView: View {
    let marketplaceAction: () -> Void
    let scanItemAction: () -> Void

    @State private var userName = "User" // Could be stored in UserDefaults later
    @State private var totalScanned = 23 // Mock data for now
    @State private var totalSaved = 347.50 // Mock savings data
    @State private var topMarketplace = "StockX" // Mock trending data

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back,")
                                .font(.title2)
                                .foregroundColor(.gray)

                            Text(userName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        // Profile/notification button
                        Button(action: {
                            // TODO: Profile action
                        }) {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                )
                        }
                    }

                    Text("Ready to find your next profitable flip?")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top)

                // Quick Stats Cards
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        StatsCard(
                            title: "Items Scanned",
                            value: "\(totalScanned)",
                            subtitle: "This month",
                            icon: "camera.fill",
                            color: .blue
                        )

                        StatsCard(
                            title: "Fees Saved",
                            value: "$\(String(format: "%.0f", totalSaved))",
                            subtitle: "Smart choices",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                    }

                    StatsCard(
                        title: "Top Marketplace",
                        value: topMarketplace,
                        subtitle: "Best for your items",
                        icon: "crown.fill",
                        color: .orange,
                        isWide: true
                    )
                }
                .padding(.horizontal)

                // Quick Actions
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Quick Actions")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        QuickActionCard(
                            title: "Scan New Item",
                            subtitle: "Take a photo to analyze",
                            icon: "camera.fill",
                            color: .blue
                        ) {
                            // TODO: Navigate to capture tab
                        }

                        QuickActionCard(
                            title: "Upload from Gallery",
                            subtitle: "Analyze existing photos",
                            icon: "photo.fill",
                            color: .purple
                        ) {
                            // TODO: Image picker
                        }

                        QuickActionCard(
                            title: "Barcode Scanner",
                            subtitle: "Quick lookup for products",
                            icon: "barcode.viewfinder",
                            color: .orange
                        ) {
                            // TODO: Barcode scanner
                        }
                    }
                    .padding(.horizontal)
                }

                // Market Insights
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Market Insights")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button("See All") {
                            // TODO: Full insights view
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            InsightCard(
                                title: "Trending Up",
                                subtitle: "Vintage Electronics",
                                content: "+15%",
                                icon: "arrow.up.circle.fill",
                                color: .green
                            )

                            InsightCard(
                                title: "Hot Category",
                                subtitle: "Designer Handbags",
                                content: "🔥 Popular",
                                icon: "flame.fill",
                                color: .red
                            )

                            InsightCard(
                                title: "Best Time",
                                subtitle: "Weekend Listings",
                                content: "+23% sales",
                                icon: "clock.fill",
                                color: .blue
                            )
                        }
                        .padding(.horizontal)
                    }
                }

                // Recent Activity (if we had data)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Scans")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button("View All") {
                            // TODO: Navigate to history tab
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        RecentItemCard(
                            itemName: "Apple TV Remote",
                            bestPrice: "$67.50",
                            marketplace: "StockX",
                            timeAgo: "2 hours ago"
                        )

                        RecentItemCard(
                            itemName: "Nike Air Force 1",
                            bestPrice: "$120.00",
                            marketplace: "StockX",
                            timeAgo: "Yesterday"
                        )

                        RecentItemCard(
                            itemName: "Vintage Pyrex Bowl",
                            bestPrice: "$45.99",
                            marketplace: "Etsy",
                            timeAgo: "3 days ago"
                        )
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 100) // Extra space at bottom
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Supporting Views

struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var isWide: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .if(!isWide) { view in
            view.frame(maxWidth: .infinity)
        }
    }
}

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
