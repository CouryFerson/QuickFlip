//
//  DepopPrepView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/27/25.
//

import SwiftUI

struct DepopPrepView: View {
    @State private var listing: DepopListing
    let capturedImage: UIImage
    @Environment(\.presentationMode) var presentationMode

    // Depop Brand Colors
    private let depopRed = Color(red: 1.0, green: 0.0, blue: 0.0) // Depop signature bright red #FF0000
    private let depopPink = Color(red: 1.0, green: 0.4, blue: 0.7) // Depop pink
    private let depopBlue = Color(red: 0.0, green: 0.5, blue: 1.0) // Depop blue
    private let depopBlack = Color(red: 0.1, green: 0.1, blue: 0.1) // Dark text
    private let depopGray = Color(red: 0.96, green: 0.96, blue: 0.96) // Light background
    private let depopWhite = Color.white
    private let depopGreen = Color(red: 0.0, green: 0.8, blue: 0.4) // Success green
    private let depopYellow = Color(red: 1.0, green: 0.9, blue: 0.0) // Highlight yellow

    init(listing: DepopListing, capturedImage: UIImage) {
        self._listing = State(initialValue: listing)
        self.capturedImage = capturedImage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Depop Header
                depopHeaderView

                // Item Vibe Check
                itemVibeCard

                // Aesthetic Guide
                aestheticGuideSection

                // Creator Economy Section
                creatorEconomySection

                // Trending Insights
                trendingInsightsSection

                // Drop Your Item Section
                dropYourItemSection

                Spacer(minLength: 30)
            }
        }
        .background(depopGray.ignoresSafeArea())
    }
}

// MARK: - Depop Header
private extension DepopPrepView {
    var depopHeaderView: some View {
        VStack(spacing: 0) {
            // Depop branded header with gradient
            HStack {
                Text("Depop")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [depopRed, depopPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(depopRed)

                    Text("Express Yourself")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(depopRed)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(depopWhite)

            // Vibe indicator
            HStack {
                Text("Ready to Drop")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(depopBlack)

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<5) { index in
                        Image(systemName: index <= 3 ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(index <= 3 ? depopYellow : Color.gray.opacity(0.4))
                    }
                    Text("Trending")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(depopYellow)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(depopGray)
        }
    }
}

// MARK: - Item Vibe Check
private extension DepopPrepView {
    var itemVibeCard: some View {
        VStack(spacing: 16) {
            // Creative item showcase
            HStack(spacing: 16) {
                ZStack {
                    // Depop-style creative background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [depopPink.opacity(0.3), depopBlue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)

                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .cornerRadius(16)
                        .clipped()

                    // Depop-style overlay elements
                    VStack {
                        HStack {
                            Spacer()

                            VStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(depopWhite)

                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(depopWhite)
                            }
                            .padding(8)
                            .background(depopBlack.opacity(0.4))
                            .cornerRadius(16)
                            .padding(12)
                        }
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(listing.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(depopBlack)
                        .lineLimit(2)

                    if !listing.style.isEmpty {
                        Text("#\(listing.style)")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(depopRed)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(depopRed.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Text("Size \(listing.size)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text(listing.condition)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(depopBlue)

                    // Depop verification
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(depopGreen)

                        Text("Depop Protected")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(depopGreen)
                    }
                }

                Spacer()
            }

            // Engagement predictions with Depop style
            HStack(spacing: 12) {
                VibeMetricCard(
                    emoji: "🔥",
                    metric: "Fire Rating",
                    value: "8.5/10",
                    color: depopRed
                )

                VibeMetricCard(
                    emoji: "👀",
                    metric: "Views",
                    value: "50-80",
                    color: depopBlue
                )

                VibeMetricCard(
                    emoji: "💕",
                    metric: "Likes",
                    value: "12-25",
                    color: depopPink
                )

                VibeMetricCard(
                    emoji: "⚡",
                    metric: "Sell Speed",
                    value: "1-4 Days",
                    color: depopYellow
                )
            }
        }
        .padding(20)
        .background(depopWhite)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

// MARK: - Aesthetic Guide
private extension DepopPrepView {
    var aestheticGuideSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 20))
                    .foregroundColor(depopPink)

                Text("Aesthetic Guide")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(depopBlack)

                Spacer()

                Text("🎨✨")
                    .font(.system(size: 16))
            }

            VStack(spacing: 14) {
                AestheticTipRow(
                    icon: "camera.macro",
                    tip: "Get that perfect flat lay",
                    detail: "Creative backgrounds make items pop",
                    vibe: "📸"
                )

                AestheticTipRow(
                    icon: "textformat.alt",
                    tip: "Write like you talk",
                    detail: "Authentic descriptions connect with buyers",
                    vibe: "💬"
                )

                AestheticTipRow(
                    icon: "number",
                    tip: "Use trending hashtags",
                    detail: "#vintage #y2k #cottagecore boost discovery",
                    vibe: "#️⃣"
                )

                AestheticTipRow(
                    icon: "person.crop.circle.fill.badge.plus",
                    tip: "Show your personality",
                    detail: "Buyers follow sellers they vibe with",
                    vibe: "✨"
                )
            }

            // Depop creator tip
            HStack(spacing: 10) {
                Text("💡")
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro Tip: Model your items!")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(depopBlack)

                    Text("Items worn by sellers get 5x more engagement")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(14)
            .background(depopYellow.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(20)
        .background(depopWhite)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Creator Economy
private extension DepopPrepView {
    var creatorEconomySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Creator Economy")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(depopBlack)

                Spacer()

                Text("🚀 Level Up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(depopRed)
            }

            // Creator stats
            VStack(spacing: 12) {
                HStack {
                    Text("Build Your Following")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(depopBlack)

                    Spacer()

                    Text("Social Selling")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(depopWhite)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(depopRed)
                        .cornerRadius(6)
                }

                HStack(spacing: 12) {
                    CreatorStatCard(
                        title: "Followers",
                        value: "Start Building",
                        color: depopRed,
                        icon: "person.3.fill"
                    )

                    CreatorStatCard(
                        title: "Engagement",
                        value: "Be Authentic",
                        color: depopPink,
                        icon: "heart.fill"
                    )

                    CreatorStatCard(
                        title: "Sales",
                        value: "Stay Active",
                        color: depopBlue,
                        icon: "bag.fill"
                    )
                }
            }

            // Creator tips
            VStack(spacing: 10) {
                CreatorTipRow(
                    tip: "Post consistently",
                    detail: "Regular drops keep followers engaged"
                )

                CreatorTipRow(
                    tip: "Engage with community",
                    detail: "Like and comment on others' posts"
                )

                CreatorTipRow(
                    tip: "Share your story",
                    detail: "Personal connection drives sales"
                )
            }
        }
        .padding(20)
        .background(depopWhite)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Trending Insights
private extension DepopPrepView {
    var trendingInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Pricing & Trends")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(depopBlack)

                Spacer()

                Text("📈 Market")
                    .font(.system(size: 12))
                    .foregroundColor(depopGreen)
            }

            // Price strategy for Gen-Z market
            VStack(spacing: 12) {
                HStack {
                    Text("Price It Right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(depopBlack)

                    Spacer()

                    Text("$\(String(format: "%.0f", listing.suggestedMinPrice)) - $\(String(format: "%.0f", listing.suggestedMaxPrice))")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(depopRed)
                }

                HStack(spacing: 12) {
                    DepopPriceCard(
                        strategy: "Quick Drop",
                        price: listing.suggestedMinPrice,
                        emoji: "💨",
                        color: depopGreen
                    )

                    DepopPriceCard(
                        strategy: "Sweet Spot",
                        price: (listing.suggestedMinPrice + listing.suggestedMaxPrice) / 2,
                        emoji: "🎯",
                        color: depopBlue
                    )

                    DepopPriceCard(
                        strategy: "Premium",
                        price: listing.suggestedMaxPrice,
                        emoji: "💎",
                        color: depopPink
                    )
                }
            }

            // Depop fees and marketplace info
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text("💰")
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("10% selling fee + payment processing")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(depopBlack)

                        Text("Free shipping boost available")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    Text("🌟")
                        .font(.system(size: 14))

                    Text("Bundle deals and discounts drive repeat buyers")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(depopBlack)

                    Spacer()
                }
            }
            .padding(14)
            .background(depopGray)
            .cornerRadius(12)
        }
        .padding(20)
        .background(depopWhite)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Drop Your Item
private extension DepopPrepView {
    var dropYourItemSection: some View {
        VStack(spacing: 16) {
            // Primary CTA with Depop energy
            Button(action: {
                openDepopListing()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Drop on Depop")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(depopWhite)

                        Text("Join the creative community")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(depopWhite.opacity(0.9))
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(depopWhite)

                        Text("Depop")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(depopWhite)
                    }
                }
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [depopRed, depopPink, depopBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(24)
            }

            // Why Depop section with Gen-Z energy
            VStack(spacing: 14) {
                Text("Why Depop hits different")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(depopBlack)

                VStack(spacing: 10) {
                    DepopBenefitRow(emoji: "🌍", text: "30M+ users worldwide, mostly Gen-Z")
                    DepopBenefitRow(emoji: "✨", text: "Express your unique style and creativity")
                    DepopBenefitRow(emoji: "🛡️", text: "Depop Payments keep transactions secure")
                    DepopBenefitRow(emoji: "📱", text: "Mobile-first platform built for creators")
                    DepopBenefitRow(emoji: "🎨", text: "Sustainable fashion meets individual expression")
                }
            }
            .padding(20)
            .background(depopGray)
            .cornerRadius(20)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Supporting Views

struct VibeMetricCard: View {
    let emoji: String
    let metric: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 16))

            Text(metric)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AestheticTipRow: View {
    let icon: String
    let tip: String
    let detail: String
    let vibe: String

    var body: some View {
        HStack(spacing: 12) {
            Text(vibe)
                .font(.system(size: 16))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(tip)
                    .font(.system(size: 13, weight: .bold))
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

struct CreatorStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

struct CreatorTipRow: View {
    let tip: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Text("•")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(Color(red: 1.0, green: 0.0, blue: 0.0))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))

                Text(detail)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }
}

struct DepopPriceCard: View {
    let strategy: String
    let price: Double
    let emoji: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 16))

            Text(strategy)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(color)

            Text("$\(String(format: "%.0f", price))")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct DepopBenefitRow: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 16))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Actions
private extension DepopPrepView {
    func openDepopListing() {
        let universalListing = UniversalListing(
            from: listing,
            condition: listing.condition,
            targetPrice: .competitive
        )

        MarketplaceIntegrationManager.postToMarketplace(
            .depop,
            listing: universalListing,
            image: capturedImage,
            savePhotoOption: .ask
        )
    }
}

// MARK: - DepopListing Model
struct DepopListing {
    var title: String
    var style: String
    var size: String
    var condition: String
    var category: String
    var suggestedMinPrice: Double
    var suggestedMaxPrice: Double

    // Convenience initializer from ScannedItem
    init(from scannedItem: ScannedItem, image: UIImage) {
        self.title = DepopListing.createCreativeTitle(scannedItem.itemName)
        self.style = DepopListing.inferStyle(scannedItem.itemName)
        self.size = DepopListing.determineSize(scannedItem.itemName)
        self.condition = DepopListing.assessCondition(scannedItem.itemName)
        self.category = DepopListing.categorizeCreativeItem(scannedItem.itemName)

        let basePrice = DepopListing.extractPrice(from: scannedItem.estimatedValue)
        // Depop has younger demographic, often looking for deals
        self.suggestedMinPrice = basePrice * 0.6
        self.suggestedMaxPrice = basePrice * 1.3
    }

    private static func createCreativeTitle(_ name: String) -> String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func inferStyle(_ name: String) -> String {
        let styles = ["vintage", "y2k", "grunge", "cottagecore", "indie", "alt", "preppy",
                     "streetwear", "boho", "minimalist", "gothic", "kawaii", "retro", "punk"]

        for style in styles {
            if name.lowercased().contains(style) {
                return style
            }
        }

        // Infer style based on item type
        let nameLower = name.lowercased()
        if nameLower.contains("band") || nameLower.contains("tour") { return "vintage" }
        if nameLower.contains("90s") || nameLower.contains("2000s") { return "y2k" }
        if nameLower.contains("floral") || nameLower.contains("prairie") { return "cottagecore" }
        if nameLower.contains("black") || nameLower.contains("leather") { return "grunge" }

        return "unique"
    }

    private static func determineSize(_ name: String) -> String {
        let sizes = ["XXS", "XS", "S", "M", "L", "XL", "XXL",
                    "6", "7", "8", "9", "10", "11", "12", "13", "14", "16", "18", "20",
                    "US 6", "US 7", "US 8", "US 9", "US 10", "US 11", "US 12",
                    "UK 6", "UK 8", "UK 10", "UK 12", "UK 14", "UK 16"]

        for size in sizes {
            if name.contains(size) {
                return size
            }
        }
        return "One Size"
    }

    private static func assessCondition(_ name: String) -> String {
        let nameLower = name.lowercased()
        if nameLower.contains("brand new") || nameLower.contains("never worn") { return "Brand new" }
        if nameLower.contains("barely worn") || nameLower.contains("like new") { return "Like new" }
        if nameLower.contains("good condition") || nameLower.contains("well maintained") { return "Good" }
        if nameLower.contains("worn") || nameLower.contains("used") { return "Well loved" }
        if nameLower.contains("vintage") || nameLower.contains("distressed") { return "Vintage condition" }
        return "Good"
    }

    private static func categorizeCreativeItem(_ name: String) -> String {
        let nameLower = name.lowercased()

        if nameLower.contains("top") || nameLower.contains("shirt") || nameLower.contains("blouse") ||
           nameLower.contains("crop") || nameLower.contains("tank") || nameLower.contains("tee") { return "Tops" }
        if nameLower.contains("dress") || nameLower.contains("midi") || nameLower.contains("maxi") { return "Dresses" }
        if nameLower.contains("jeans") || nameLower.contains("pants") || nameLower.contains("trouser") ||
           nameLower.contains("cargo") || nameLower.contains("wide leg") { return "Bottoms" }
        if nameLower.contains("skirt") || nameLower.contains("mini") || nameLower.contains("pleated") { return "Skirts" }
        if nameLower.contains("jacket") || nameLower.contains("blazer") || nameLower.contains("coat") ||
           nameLower.contains("bomber") || nameLower.contains("denim jacket") { return "Outerwear" }
        if nameLower.contains("shoes") || nameLower.contains("boots") || nameLower.contains("sneakers") ||
           nameLower.contains("platform") || nameLower.contains("doc martens") { return "Shoes" }
        if nameLower.contains("bag") || nameLower.contains("purse") || nameLower.contains("backpack") ||
           nameLower.contains("tote") || nameLower.contains("crossbody") { return "Bags" }
        if nameLower.contains("jewelry") || nameLower.contains("necklace") || nameLower.contains("earrings") ||
           nameLower.contains("rings") || nameLower.contains("bracelet") { return "Jewelry" }
        if nameLower.contains("hat") || nameLower.contains("scarf") || nameLower.contains("belt") ||
           nameLower.contains("sunglasses") || nameLower.contains("hair") { return "Accessories" }
        if nameLower.contains("home") || nameLower.contains("decor") || nameLower.contains("poster") ||
           nameLower.contains("plant") { return "Home" }

        return "Everything Else"
    }

    private static func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "20") ?? 20.0
    }
}
