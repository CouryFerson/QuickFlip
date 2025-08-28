//
//  Untitled.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/28/25.
//

import SwiftUI

struct PoshmarkPrepView: View {
    @State private var listing: PoshmarkListing
    let capturedImage: UIImage
    @Environment(\.presentationMode) var presentationMode

    // Poshmark Brand Colors
    private let poshmarkPink = Color(red: 0.9, green: 0.2, blue: 0.4) // Poshmark signature pink #E91E63
    private let poshmarkPurple = Color(red: 0.5, green: 0.3, blue: 0.8) // Poshmark purple
    private let poshmarkBlack = Color(red: 0.1, green: 0.1, blue: 0.1) // Dark text
    private let poshmarkGray = Color(red: 0.98, green: 0.98, blue: 0.99) // Light background
    private let poshmarkWhite = Color.white
    private let poshmarkGold = Color(red: 1.0, green: 0.84, blue: 0.0) // Premium gold

    init(listing: PoshmarkListing, capturedImage: UIImage) {
        self._listing = State(initialValue: listing)
        self.capturedImage = capturedImage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Poshmark Header
                poshmarkHeaderView

                // Closet Preview Card
                closetPreviewCard

                // Style Guide Section
                styleGuideSection

                // Community Insights
                communityInsightsSection

                // Posh Ambassador Tips
                poshAmbassadorSection

                // Share Your Posh Section
                shareYourPoshSection

                Spacer(minLength: 30)
            }
        }
        .background(poshmarkGray.ignoresSafeArea())
    }
}

// MARK: - Poshmark Header
private extension PoshmarkPrepView {
    var poshmarkHeaderView: some View {
        VStack(spacing: 0) {
            // Poshmark branded header
            HStack {
                Text("Poshmark")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(poshmarkPink)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(poshmarkPink)

                    Text("Style Together")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(poshmarkPink)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(poshmarkWhite)

            // Poshmark journey indicator
            HStack {
                Text("Ready for Your Closet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(poshmarkBlack)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        Image(systemName: index <= 2 ? "heart.fill" : "heart")
                            .font(.system(size: 8))
                            .foregroundColor(index <= 2 ? poshmarkPink : Color.gray.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(poshmarkGray)
        }
    }
}

// MARK: - Closet Preview
private extension PoshmarkPrepView {
    var closetPreviewCard: some View {
        VStack(spacing: 16) {
            // Item showcase with Poshmark style
            HStack(spacing: 16) {
                ZStack {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .background(poshmarkWhite)
                        .cornerRadius(16)
                        .clipped()

                    // Poshmark style overlay
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart")
                                .font(.system(size: 16))
                                .foregroundColor(poshmarkWhite)
                                .padding(8)
                                .background(poshmarkBlack.opacity(0.3))
                                .cornerRadius(20)
                                .padding(8)
                        }
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(poshmarkBlack)
                        .lineLimit(2)

                    if !listing.brand.isEmpty {
                        Text(listing.brand)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(poshmarkPink)
                    }

                    Text("Size: \(listing.size)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)

                    Text(listing.condition)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(poshmarkPurple)

                    // Poshmark authenticity
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(poshmarkGold)

                        Text("Posh Protect")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(poshmarkGold)
                    }
                }

                Spacer()
            }

            // Engagement metrics
            HStack(spacing: 16) {
                EngagementCard(
                    icon: "heart.fill",
                    title: "Expected Likes",
                    value: "15-25",
                    color: poshmarkPink
                )

                EngagementCard(
                    icon: "message.fill",
                    title: "Comments",
                    value: "3-8",
                    color: poshmarkPurple
                )

                EngagementCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Shares",
                    value: "5-12",
                    color: poshmarkGold
                )
            }
        }
        .padding(20)
        .background(poshmarkWhite)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Style Guide
private extension PoshmarkPrepView {
    var styleGuideSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(poshmarkGold)

                Text("Poshmark Style Guide")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(poshmarkBlack)

                Spacer()

                Text("✨")
                    .font(.system(size: 16))
            }

            VStack(spacing: 12) {
                StyleTipRow(
                    icon: "camera.viewfinder",
                    tip: "Show all angles",
                    detail: "Front, back, and detail shots boost sales by 60%"
                )

                StyleTipRow(
                    icon: "textformat.size",
                    tip: "Use trendy keywords",
                    detail: "Include style terms buyers search for"
                )

                StyleTipRow(
                    icon: "tag.fill",
                    tip: "Cross-list similar items",
                    detail: "Bundle suggestions increase order value"
                )

                StyleTipRow(
                    icon: "clock.badge.checkmark",
                    tip: "List at peak times",
                    detail: "7-9 PM gets the most engagement"
                )
            }

            // Special Poshmark feature
            HStack(spacing: 8) {
                Image(systemName: "party.popper.fill")
                    .foregroundColor(poshmarkPink)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Host a Posh Party!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(poshmarkBlack)

                    Text("Get featured in themed parties to reach more buyers")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(12)
            .background(poshmarkPink.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(20)
        .background(poshmarkWhite)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Community Insights
private extension PoshmarkPrepView {
    var communityInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Community Insights")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(poshmarkBlack)

                Spacer()

                Text("👥 Social")
                    .font(.system(size: 12))
                    .foregroundColor(poshmarkPurple)
            }

            // Price insights specific to fashion
            VStack(spacing: 12) {
                HStack {
                    Text("Suggested Pricing")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(poshmarkBlack)

                    Spacer()

                    Text("$\(String(format: "%.0f", listing.suggestedMinPrice)) - $\(String(format: "%.0f", listing.suggestedMaxPrice))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(poshmarkPink)
                }

                // Poshmark-specific pricing strategy
                HStack(spacing: 12) {
                    PoshPriceCard(
                        label: "List High",
                        price: listing.suggestedMaxPrice,
                        subtitle: "Room to negotiate",
                        color: poshmarkPink
                    )

                    PoshPriceCard(
                        label: "Sweet Spot",
                        price: (listing.suggestedMinPrice + listing.suggestedMaxPrice) / 2,
                        subtitle: "Quick sale",
                        color: poshmarkPurple
                    )

                    PoshPriceCard(
                        label: "Bundle Deal",
                        price: listing.suggestedMinPrice,
                        subtitle: "With other items",
                        color: poshmarkGold
                    )
                }
            }

            // Poshmark fees and benefits
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(poshmarkPink)
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("20% fee on sales over $15 (flat $2.95 under)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(poshmarkBlack)

                        Text("Poshmark provides prepaid shipping label")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .foregroundColor(poshmarkGold)
                        .font(.system(size: 14))

                    Text("Buyers love bundles - offer 15% off 2+ items!")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(poshmarkBlack)

                    Spacer()
                }
            }
            .padding(12)
            .background(poshmarkGray)
            .cornerRadius(8)
        }
        .padding(20)
        .background(poshmarkWhite)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Posh Ambassador
private extension PoshmarkPrepView {
    var poshAmbassadorSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundColor(poshmarkGold)

                Text("Posh Ambassador Tips")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(poshmarkBlack)

                Spacer()
            }

            VStack(spacing: 10) {
                AmbassadorTipRow(
                    icon: "arrow.triangle.2.circlepath",
                    tip: "Share others' listings",
                    detail: "Community sharing boosts your visibility"
                )

                AmbassadorTipRow(
                    icon: "message.fill",
                    tip: "Engage authentically",
                    detail: "Genuine comments build lasting relationships"
                )

                AmbassadorTipRow(
                    icon: "clock.fill",
                    tip: "Be active daily",
                    detail: "Regular activity keeps you in feeds"
                )

                AmbassadorTipRow(
                    icon: "hand.thumbsup.fill",
                    tip: "Follow Posh etiquette",
                    detail: "Kind interactions create loyal customers"
                )
            }

            // Ambassador status info
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(poshmarkGold)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Become a Posh Ambassador")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(poshmarkBlack)

                    Text("Share, follow community guidelines, and stay active")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text("🏆")
                    .font(.system(size: 16))
            }
            .padding(12)
            .background(poshmarkGold.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(20)
        .background(poshmarkWhite)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Share Your Posh
private extension PoshmarkPrepView {
    var shareYourPoshSection: some View {
        VStack(spacing: 16) {
            // Primary CTA
            Button(action: {
                openPoshmarkListing()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Share to Poshmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(poshmarkWhite)

                        Text("Join the fashion community and start selling")
                            .font(.system(size: 13))
                            .foregroundColor(poshmarkWhite.opacity(0.9))
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(poshmarkWhite)

                        Text("Poshmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(poshmarkWhite)
                    }
                }
                .padding(24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [poshmarkPink, poshmarkPurple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
            }

            // Why Poshmark section
            VStack(spacing: 12) {
                Text("Why choose Poshmark?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(poshmarkBlack)

                VStack(spacing: 8) {
                    PoshmarkBenefitRow(icon: "person.3.fill", text: "80M+ users in a social shopping experience")
                    PoshmarkBenefitRow(icon: "shield.checkered", text: "Posh Protect covers all eligible orders")
                    PoshmarkBenefitRow(icon: "gift.fill", text: "Bundle discounts encourage multiple purchases")
                    PoshmarkBenefitRow(icon: "party.popper.fill", text: "Posh Parties and features boost visibility")
                    PoshmarkBenefitRow(icon: "dollarsign.circle", text: "No listing fees - only pay when you sell")
                }
            }
            .padding(20)
            .background(poshmarkGray)
            .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Supporting Views

struct EngagementCard: View {
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
                .font(.system(size: 9))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

struct StyleTipRow: View {
    let icon: String
    let tip: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.9, green: 0.2, blue: 0.4))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))

                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct PoshPriceCard: View {
    let label: String
    let price: Double
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)

            Text("$\(String(format: "%.0f", price))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))

            Text(subtitle)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

struct AmbassadorTipRow: View {
    let icon: String
    let tip: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))

                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct PoshmarkBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.9, green: 0.2, blue: 0.4))
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Actions
private extension PoshmarkPrepView {
    func openPoshmarkListing() {
        let universalListing = UniversalListing(
            from: listing,
            condition: listing.condition,
            targetPrice: .competitive
        )

        MarketplaceIntegrationManager.postToMarketplace(
            .poshmark,
            listing: universalListing,
            image: capturedImage,
            savePhotoOption: .ask
        )
    }
}

// MARK: - PoshmarkListing Model
struct PoshmarkListing {
    var title: String
    var brand: String
    var size: String
    var condition: String
    var category: String
    var suggestedMinPrice: Double
    var suggestedMaxPrice: Double

    // Convenience initializer from ScannedItem
    init(from scannedItem: ScannedItem, image: UIImage) {
        self.title = PoshmarkListing.createFashionTitle(scannedItem.itemName)
        self.brand = PoshmarkListing.extractBrand(scannedItem.itemName)
        self.size = PoshmarkListing.inferSize(scannedItem.itemName)
        self.condition = PoshmarkListing.determineCondition(scannedItem.itemName)
        self.category = PoshmarkListing.categorizeFashionItem(scannedItem.itemName)

        let basePrice = PoshmarkListing.extractPrice(from: scannedItem.estimatedValue)
        // Poshmark users often price high to allow for offers
        self.suggestedMinPrice = basePrice * 0.7
        self.suggestedMaxPrice = basePrice * 1.5
    }

    private static func createFashionTitle(_ name: String) -> String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractBrand(_ name: String) -> String {
        let fashionBrands = ["Zara", "H&M", "Nike", "Adidas", "Levi's", "Coach", "Gucci", "Prada",
                           "Louis Vuitton", "Chanel", "Dior", "Burberry", "Ralph Lauren", "Calvin Klein",
                           "Tommy Hilfiger", "Michael Kors", "Kate Spade", "Tory Burch", "Free People",
                           "Anthropologie", "J.Crew", "Banana Republic", "Ann Taylor", "Loft"]

        for brand in fashionBrands {
            if name.lowercased().contains(brand.lowercased()) {
                return brand
            }
        }
        return "Boutique"
    }

    private static func inferSize(_ name: String) -> String {
        let sizes = ["XXS", "XS", "S", "M", "L", "XL", "XXL", "XXXL",
                    "0", "2", "4", "6", "8", "10", "12", "14", "16", "18", "20",
                    "6.5", "7", "7.5", "8", "8.5", "9", "9.5", "10", "10.5", "11", "11.5", "12"]

        for size in sizes {
            if name.contains(" \(size) ") || name.contains(" \(size)\"") || name.hasSuffix(" \(size)") {
                return size
            }
        }
        return "OS" // One Size
    }

    private static func determineCondition(_ name: String) -> String {
        let nameLower = name.lowercased()
        if nameLower.contains("new with tags") || nameLower.contains("nwt") { return "New with tags" }
        if nameLower.contains("new without tags") || nameLower.contains("nwot") { return "New without tags" }
        if nameLower.contains("like new") { return "Like new" }
        if nameLower.contains("good") { return "Good" }
        if nameLower.contains("fair") { return "Fair" }
        return "Excellent"
    }

    private static func categorizeFashionItem(_ name: String) -> String {
        let nameLower = name.lowercased()

        if nameLower.contains("dress") || nameLower.contains("gown") { return "Dresses" }
        if nameLower.contains("top") || nameLower.contains("blouse") || nameLower.contains("shirt") ||
           nameLower.contains("tee") || nameLower.contains("tank") { return "Tops" }
        if nameLower.contains("pants") || nameLower.contains("jean") || nameLower.contains("trouser") ||
           nameLower.contains("legging") { return "Pants" }
        if nameLower.contains("skirt") { return "Skirts" }
        if nameLower.contains("jacket") || nameLower.contains("blazer") || nameLower.contains("coat") ||
           nameLower.contains("cardigan") { return "Jackets & Coats" }
        if nameLower.contains("shoe") || nameLower.contains("boot") || nameLower.contains("sneaker") ||
           nameLower.contains("heel") || nameLower.contains("sandal") { return "Shoes" }
        if nameLower.contains("bag") || nameLower.contains("purse") || nameLower.contains("clutch") ||
           nameLower.contains("tote") { return "Bags" }
        if nameLower.contains("jewelry") || nameLower.contains("necklace") || nameLower.contains("earring") ||
           nameLower.contains("bracelet") || nameLower.contains("ring") { return "Jewelry" }
        if nameLower.contains("watch") || nameLower.contains("scarf") || nameLower.contains("belt") ||
           nameLower.contains("hat") || nameLower.contains("sunglasses") { return "Accessories" }
        if nameLower.contains("swim") || nameLower.contains("bikini") || nameLower.contains("bathing") { return "Swim" }

        return "Other"
    }

    private static func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "25") ?? 25.0
    }
}
