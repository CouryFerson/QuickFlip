//
//  MercariPrepView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/27/25.
//

import SwiftUI

struct MercariPrepView: View {
    @State private var listing: MercariListing
    let capturedImage: UIImage
    @Environment(\.presentationMode) var presentationMode

    // Mercari Brand Colors
    private let mercariRed = Color(red: 0.9, green: 0.2, blue: 0.2) // Mercari signature red #E60012
    private let mercariOrange = Color(red: 1.0, green: 0.4, blue: 0.0) // Mercari orange
    private let mercariDarkGray = Color(red: 0.2, green: 0.2, blue: 0.2) // Dark text
    private let mercariLightGray = Color(red: 0.95, green: 0.95, blue: 0.95) // Background
    private let mercariWhite = Color.white
    private let mercariGreen = Color(red: 0.0, green: 0.7, blue: 0.4) // Success green

    init(listing: MercariListing, capturedImage: UIImage) {
        self._listing = State(initialValue: listing)
        self.capturedImage = capturedImage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Mercari Header
                mercariHeaderView

                // Product Preview Card
                productPreviewCard

                // Selling Tips Section
                sellingTipsSection

                // Category Suggestion
                categorySuggestionSection

                // Pricing Insights
                pricingInsightsSection

                // Ready to List Section
                readyToListSection

                Spacer(minLength: 30)
            }
        }
        .background(mercariLightGray.ignoresSafeArea())
    }
}

// MARK: - Mercari Header
private extension MercariPrepView {
    var mercariHeaderView: some View {
        VStack(spacing: 0) {
            // Mercari branded header
            HStack {
                Text("mercari")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(mercariRed)
                    .textCase(.lowercase)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(mercariGreen)

                    Text("Sell Easy")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(mercariGreen)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(mercariWhite)

            // Progress indicator
            HStack {
                Text("Ready to List")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(mercariDarkGray)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == 0 ? mercariRed : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(mercariLightGray)
        }
    }
}

// MARK: - Product Preview
private extension MercariPrepView {
    var productPreviewCard: some View {
        VStack(spacing: 16) {
            // Product showcase
            HStack(spacing: 16) {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .background(mercariWhite)
                    .cornerRadius(12)
                    .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(mercariDarkGray)
                        .lineLimit(3)

                    if !listing.brand.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(mercariRed)

                            Text(listing.brand)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(mercariRed)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(mercariRed.opacity(0.1))
                        .cornerRadius(6)
                    }

                    Text(listing.condition)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)

                    // Mercari protection
                    HStack(spacing: 4) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 10))
                            .foregroundColor(mercariGreen)

                        Text("Mercari Protection")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(mercariGreen)
                    }
                }

                Spacer()
            }

            // Quick stats
            HStack(spacing: 16) {
                StatCard(
                    icon: "eye.fill",
                    title: "Views",
                    value: "High Interest",
                    color: mercariOrange
                )

                StatCard(
                    icon: "heart.fill",
                    title: "Likes",
                    value: "Expected",
                    color: mercariRed
                )

                StatCard(
                    icon: "clock.fill",
                    title: "Sell Time",
                    value: "2-7 Days",
                    color: mercariGreen
                )
            }
        }
        .padding(20)
        .background(mercariWhite)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Selling Tips
private extension MercariPrepView {
    var sellingTipsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(mercariOrange)

                Text("Mercari Selling Tips")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(mercariDarkGray)

                Spacer()
            }

            VStack(spacing: 12) {
                MercariTipView(
                    icon: "camera.fill",
                    tip: "Use natural lighting for photos",
                    detail: "Items with great photos sell 40% faster"
                )

                MercariTipView(
                    icon: "text.bubble.fill",
                    tip: "Be honest in your description",
                    detail: "Honest listings get better reviews"
                )

                MercariTipView(
                    icon: "speedometer",
                    tip: "Price competitively",
                    detail: "Fair prices attract more buyers"
                )

                MercariTipView(
                    icon: "paperplane.fill",
                    tip: "Ship within 3 days",
                    detail: "Fast shipping improves your rating"
                )
            }
        }
        .padding(20)
        .background(mercariWhite)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Category Suggestion
private extension MercariPrepView {
    var categorySuggestionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Suggested Category")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(mercariDarkGray)

                Spacer()

                Text("AI Powered")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(mercariWhite)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(mercariOrange)
                    .cornerRadius(4)
            }

            HStack(spacing: 12) {
                Image(systemName: listing.getCategoryIcon())
                    .font(.system(size: 24))
                    .foregroundColor(mercariRed)
                    .frame(width: 40, height: 40)
                    .background(mercariRed.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.suggestedCategory)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(mercariDarkGray)

                    Text("Based on your item analysis")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text("✨ Perfect Match")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(mercariGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(mercariGreen.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(16)
            .background(mercariLightGray)
            .cornerRadius(12)
        }
        .padding(20)
        .background(mercariWhite)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Pricing Insights
private extension MercariPrepView {
    var pricingInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Pricing Insights")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(mercariDarkGray)

                Spacer()

                Text("💰")
                    .font(.system(size: 16))
            }

            // Price recommendation
            VStack(spacing: 12) {
                HStack {
                    Text("Suggested Price Range")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(mercariDarkGray)

                    Spacer()

                    Text("$\(String(format: "%.0f", listing.suggestedMinPrice)) - $\(String(format: "%.0f", listing.suggestedMaxPrice))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(mercariRed)
                }

                // Price breakdown
                HStack(spacing: 12) {
                    PricePoint(
                        label: "Quick Sale",
                        price: listing.suggestedMinPrice,
                        color: mercariGreen,
                        subtitle: "Sell Fast"
                    )

                    PricePoint(
                        label: "Market Price",
                        price: (listing.suggestedMinPrice + listing.suggestedMaxPrice) / 2,
                        color: mercariOrange,
                        subtitle: "Balanced"
                    )

                    PricePoint(
                        label: "Premium",
                        price: listing.suggestedMaxPrice,
                        color: mercariRed,
                        subtitle: "Max Profit"
                    )
                }
            }

            // Mercari fees info
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(mercariRed)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text("10% selling fee + payment processing")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(mercariDarkGray)

                    Text("Free shipping labels available")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(12)
            .background(mercariLightGray)
            .cornerRadius(8)
        }
        .padding(20)
        .background(mercariWhite)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Ready to List
private extension MercariPrepView {
    var readyToListSection: some View {
        VStack(spacing: 16) {
            // Primary CTA
            Button(action: {
                openMercariListing()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("List on Mercari")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(mercariWhite)

                        Text("Complete your listing in the Mercari app or website")
                            .font(.system(size: 13))
                            .foregroundColor(mercariWhite.opacity(0.9))
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 24))
                            .foregroundColor(mercariWhite)

                        Text("mercari")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(mercariWhite)
                            .textCase(.lowercase)
                    }
                }
                .padding(24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [mercariRed, mercariOrange]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }

            // Why Mercari section
            VStack(spacing: 12) {
                Text("Why sell on Mercari?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(mercariDarkGray)

                VStack(spacing: 8) {
                    MercariBenefitRow(icon: "shield.checkered", text: "Secure transactions with Mercari Protection")
                    MercariBenefitRow(icon: "dollarsign.circle", text: "No listing fees - only pay when you sell")
                    MercariBenefitRow(icon: "person.2.fill", text: "175M+ downloads - huge buyer base")
                    MercariBenefitRow(icon: "truck.box.fill", text: "Prepaid shipping labels included")
                }
            }
            .padding(20)
            .background(mercariLightGray)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct MercariTipView: View {
    let icon: String
    let tip: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.9, green: 0.2, blue: 0.2))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))

                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct PricePoint: View {
    let label: String
    let price: Double
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)

            Text("$\(String(format: "%.0f", price))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)

            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MercariBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.9, green: 0.2, blue: 0.2))
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Actions
private extension MercariPrepView {
    func openMercariListing() {
        let universalListing = UniversalListing(
            from: listing,
            condition: listing.condition,
            targetPrice: .competitive
        )

        MarketplaceIntegrationManager.postToMarketplace(
            .mercari,
            listing: universalListing,
            image: capturedImage,
            savePhotoOption: .ask
        )
    }
}

// MARK: - MercariListing Model
struct MercariListing {
    var title: String
    var brand: String
    var condition: String
    var suggestedCategory: String
    var suggestedMinPrice: Double
    var suggestedMaxPrice: Double

    // Convenience initializer from ScannedItem
    init(from scannedItem: ScannedItem, image: UIImage) {
        self.title = MercariListing.cleanTitle(scannedItem.itemName)
        self.brand = MercariListing.extractBrand(scannedItem.itemName)
        self.condition = MercariListing.determineCondition(scannedItem.itemName)
        self.suggestedCategory = MercariListing.categorizeItem(scannedItem.itemName)

        let basePrice = MercariListing.extractPrice(from: scannedItem.estimatedValue)
        self.suggestedMinPrice = basePrice * 0.8
        self.suggestedMaxPrice = basePrice * 1.2
    }

    func getCategoryIcon() -> String {
        switch suggestedCategory.lowercased() {
        case "electronics": return "desktopcomputer"
        case "clothing": return "tshirt.fill"
        case "shoes": return "shoe.fill"
        case "accessories": return "bag.fill"
        case "home & garden": return "house.fill"
        case "beauty": return "sparkles"
        case "collectibles": return "star.fill"
        case "books": return "book.fill"
        case "sports": return "sportscourt.fill"
        default: return "tag.fill"
        }
    }

    private static func cleanTitle(_ name: String) -> String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractBrand(_ name: String) -> String {
        let brands = ["Nike", "Adidas", "Apple", "Samsung", "Coach", "Gucci", "Supreme", "Jordan"]
        for brand in brands {
            if name.lowercased().contains(brand.lowercased()) {
                return brand
            }
        }
        return ""
    }

    private static func determineCondition(_ name: String) -> String {
        let nameLower = name.lowercased()
        if nameLower.contains("new") { return "New" }
        if nameLower.contains("used") || nameLower.contains("worn") { return "Good" }
        return "Like New"
    }

    private static func categorizeItem(_ name: String) -> String {
        let nameLower = name.lowercased()

        if nameLower.contains("phone") || nameLower.contains("ipad") || nameLower.contains("laptop") ||
           nameLower.contains("gaming") || nameLower.contains("headphones") { return "Electronics" }
        if nameLower.contains("shirt") || nameLower.contains("dress") || nameLower.contains("pants") ||
           nameLower.contains("jacket") { return "Clothing" }
        if nameLower.contains("shoe") || nameLower.contains("sneaker") || nameLower.contains("boot") { return "Shoes" }
        if nameLower.contains("bag") || nameLower.contains("purse") || nameLower.contains("wallet") ||
           nameLower.contains("watch") { return "Accessories" }
        if nameLower.contains("home") || nameLower.contains("decor") || nameLower.contains("kitchen") { return "Home & Garden" }
        if nameLower.contains("makeup") || nameLower.contains("skincare") || nameLower.contains("perfume") { return "Beauty" }
        if nameLower.contains("card") || nameLower.contains("collectible") || nameLower.contains("vintage") { return "Collectibles" }
        if nameLower.contains("book") { return "Books" }
        if nameLower.contains("sport") || nameLower.contains("fitness") { return "Sports" }

        return "Other"
    }

    private static func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "50") ?? 50.0
    }
}
