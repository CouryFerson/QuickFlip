//
//  Untitled.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/20/25.
//

import SwiftUI

struct StockXPrepView: View {
    @State private var listing: StockXListing
    let capturedImage: UIImage
    @Environment(\.presentationMode) var presentationMode

    // StockX Brand Colors
    private let stockXGreen = Color(red: 0.0, green: 0.7, blue: 0.4) // StockX signature green #00B140
    private let stockXDarkGreen = Color(red: 0.0, green: 0.55, blue: 0.3) // Darker green
    private let stockXBlack = Color(red: 0.1, green: 0.1, blue: 0.12) // StockX dark
    private let stockXGray = Color(red: 0.97, green: 0.97, blue: 0.98) // Light gray background
    private let stockXWhite = Color.white
    private let stockXRed = Color(red: 0.9, green: 0.2, blue: 0.2) // Bid red

    init(listing: StockXListing, capturedImage: UIImage) {
        self._listing = State(initialValue: listing)
        self.capturedImage = capturedImage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // StockX Header
                stockXHeaderView

                // Product Overview Card
                productOverviewCard

                // Market Analysis Section
                marketAnalysisSection

                // Selling Flow Preview
                sellingFlowPreview

                // Action Section
                actionSection

                Spacer(minLength: 30)
            }
        }
        .background(stockXGray.ignoresSafeArea())
    }
}

// MARK: - StockX Header
private extension StockXPrepView {
    var stockXHeaderView: some View {
        VStack(spacing: 0) {
            // StockX branded header
            HStack {
                Text("StockX")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(stockXBlack)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(stockXGreen)
                        .frame(width: 8, height: 8)
                    Text("Live Market")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(stockXGreen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(stockXWhite)

            // Breadcrumb
            HStack {
                Text("Sell Preview")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(stockXBlack)

                Spacer()

                Text("Ready to list")
                    .font(.system(size: 12))
                    .foregroundColor(stockXGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stockXGreen.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(stockXGray)
        }
    }
}

// MARK: - Product Overview
private extension StockXPrepView {
    var productOverviewCard: some View {
        VStack(spacing: 16) {
            // Product header
            HStack(spacing: 16) {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .background(stockXWhite)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(listing.productName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(stockXBlack)
                        .lineLimit(2)

                    if !listing.colorway.isEmpty {
                        Text(listing.colorway)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    if !listing.sku.isEmpty {
                        Text(listing.sku)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }

                    // Verification status
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(stockXGreen)

                        Text("StockX Verified")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(stockXGreen)
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .background(stockXWhite)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Market Analysis
private extension StockXPrepView {
    var marketAnalysisSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Market Analysis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(stockXBlack)

                Spacer()

                Text("Live Data")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(stockXWhite)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(stockXRed)
                    .cornerRadius(4)
            }

            // Market data grid
            HStack(spacing: 12) {
                MarketDataCard(
                    title: "Last Sale",
                    value: "$\(String(format: "%.0f", listing.lastSalePrice))",
                    color: stockXBlack
                )

                MarketDataCard(
                    title: "Highest Bid",
                    value: "$\(String(format: "%.0f", listing.highestBid))",
                    color: stockXGreen
                )

                MarketDataCard(
                    title: "Lowest Ask",
                    value: "$\(String(format: "%.0f", listing.lowestAsk))",
                    color: stockXRed
                )
            }

            // Pricing recommendation
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(stockXGreen)
                        .font(.system(size: 14))

                    Text("Pricing Suggestion")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(stockXBlack)

                    Spacer()
                }

                Text("Based on current market data, consider pricing between $\(String(format: "%.0f", listing.highestBid)) - $\(String(format: "%.0f", listing.lowestAsk)) for optimal selling potential.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(stockXGreen.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(16)
        .background(stockXWhite)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Selling Flow Preview
private extension StockXPrepView {
    var sellingFlowPreview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("What's Next")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(stockXBlack)

                Spacer()

                Text("3 Steps")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            VStack(spacing: 12) {
                SellingStepRow(
                    stepNumber: 1,
                    title: "Size & Condition",
                    description: "Select your exact size and item condition",
                    icon: "ruler",
                    isCompleted: false
                )

                SellingStepRow(
                    stepNumber: 2,
                    title: "Set Your Ask",
                    description: "Choose your selling price or sell now",
                    icon: "dollarsign.circle",
                    isCompleted: false
                )

                SellingStepRow(
                    stepNumber: 3,
                    title: "Ship & Get Paid",
                    description: "Send to StockX for authentication",
                    icon: "shippingbox",
                    isCompleted: false
                )
            }

            // Important note
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(stockXGreen)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("StockX handles all authentication")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(stockXBlack)

                    Text("Every item is verified by experts before reaching the buyer")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(12)
            .background(stockXGray)
            .cornerRadius(8)
        }
        .padding(16)
        .background(stockXWhite)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Action Section
private extension StockXPrepView {
    var actionSection: some View {
        VStack(spacing: 16) {
            // Primary CTA
            Button(action: {
                openStockXApp()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Continue in StockX App")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(stockXWhite)

                        Text("Complete your listing in 3 simple steps")
                            .font(.system(size: 12))
                            .foregroundColor(stockXWhite.opacity(0.8))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(stockXWhite)

                        Text("StockX")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(stockXWhite)
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [stockXGreen, stockXDarkGreen]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }

            // Secondary info
            VStack(spacing: 8) {
                Text("Why list on StockX?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(stockXBlack)

                VStack(spacing: 6) {
                    BenefitRow(icon: "checkmark.shield.fill", text: "Guaranteed authentic buyers")
                    BenefitRow(icon: "dollarsign.circle.fill", text: "Competitive market pricing")
                    BenefitRow(icon: "globe", text: "Global marketplace reach")
                }
            }
            .padding(16)
            .background(stockXGray)
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Supporting Views

struct MarketDataCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct SellingStepRow: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(isCompleted ? Color(red: 0.0, green: 0.7, blue: 0.4) : Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(stepNumber)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.12))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.4))
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Actions
private extension StockXPrepView {
    func openStockXApp() {
        let universalListing = UniversalListing(
            from: listing,
            condition: "New",
            targetPrice: .competitive
        )

        MarketplaceIntegrationManager.postToMarketplace(
            .stockx,
            listing: universalListing,
            image: capturedImage,
            savePhotoOption: .ask
        )
    }
}

// MARK: - Models
struct StockXListing {
    var productName: String
    var colorway: String
    var sku: String
    var lastSalePrice: Double
    var lowestAsk: Double
    var highestBid: Double

    // Convenience initializer from ItemAnalysis
    init(from scannedItem: ScannedItem, image: UIImage) {
        self.productName = StockXListing.extractProductName(scannedItem.itemName)
        self.colorway = StockXListing.extractColorway(scannedItem.itemName)
        self.sku = StockXListing.generateSKU(from: scannedItem.itemName)

        // Mock market data based on estimated value
        let basePrice = StockXListing.extractPrice(from: scannedItem.estimatedValue)
        self.lastSalePrice = basePrice
        self.lowestAsk = basePrice * 1.1
        self.highestBid = basePrice * 0.9
    }

    // MARK: - StockX Price Strategy
     enum StockXPriceStrategy {
         case competitive    // Price between highest bid and lowest ask
         case aggressive     // Price at or below highest bid for quick sale
         case premium        // Price at or above lowest ask for maximum profit
         case lastSale       // Price based on last sale price
     }

     // MARK: - StockX Helper Methods

    func createStockXDescription(condition: String) -> String {
         var description = "Authentic \(productName)"

         if !colorway.isEmpty {
             description += " in \(colorway)"
         }

         if !sku.isEmpty {
             description += "\nSKU: \(sku)"
         }

         description += """
         
         📊 Market Data:
         • Last Sale: $\(String(format: "%.0f", lastSalePrice))
         • Lowest Ask: $\(String(format: "%.0f", lowestAsk))
         • Highest Bid: $\(String(format: "%.0f", highestBid))
         
         ✅ Condition: \(condition)
         🔒 StockX Authentication Guaranteed
         """

         return description
     }

    func calculateStockXPrice(strategy: StockXPriceStrategy) -> Double {
         switch strategy {
         case .competitive:
             // Price in the middle of bid-ask spread
             return (highestBid + lowestAsk) / 2

         case .aggressive:
             // Price to sell quickly - at or slightly below highest bid
             return max(highestBid - 10, highestBid * 0.95)

         case .premium:
             // Price for maximum profit - at or slightly below lowest ask
             return max(lowestAsk - 5, lowestAsk * 0.98)

         case .lastSale:
             // Price based on recent market activity
             return lastSalePrice
         }
     }

    func inferStockXCategory() -> String {
         let name = productName.lowercased()

         if name.contains("jordan") || name.contains("nike") || name.contains("adidas") ||
            name.contains("yeezy") || name.contains("sneaker") || name.contains("shoe") {
             return "Sneakers"
         } else if name.contains("supreme") || name.contains("bape") || name.contains("off-white") ||
                   name.contains("shirt") || name.contains("hoodie") || name.contains("jacket") {
             return "Streetwear"
         } else if name.contains("watch") || name.contains("airpods") || name.contains("iphone") ||
                   name.contains("gaming") || name.contains("console") {
             return "Electronics"
         } else if name.contains("card") || name.contains("pokemon") || name.contains("collectible") {
             return "Collectibles"
         } else {
             return "Other"
         }
     }

    func createStockXTags() -> [String] {
         var tags = ["StockX", "Authenticated", "Resale"]

         // Add brand tags
         let productName = productName.lowercased()
         if productName.contains("nike") { tags.append("Nike") }
         if productName.contains("jordan") { tags.append("Jordan") }
         if productName.contains("adidas") { tags.append("Adidas") }
         if productName.contains("yeezy") { tags.append("Yeezy") }
         if productName.contains("supreme") { tags.append("Supreme") }

         // Add colorway as tag if available
         if !colorway.isEmpty {
             tags.append(colorway)
         }

         // Add SKU if available
         if !sku.isEmpty {
             tags.append(sku)
         }

         return tags
     }

    private static func extractProductName(_ name: String) -> String {
        // Clean up product name for StockX format
        return name.replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractColorway(_ name: String) -> String {
        // Try to identify colorway from name
        let colors = ["Black", "White", "Red", "Blue", "Green", "Gray", "Navy", "Brown"]
        for color in colors {
            if name.lowercased().contains(color.lowercased()) {
                return color
            }
        }
        return "Multi-Color"
    }

    private static func generateSKU(from name: String) -> String {
        // Generate a mock SKU based on product name
        let prefix = name.prefix(3).uppercased()
        let numbers = String(Int.random(in: 100...999))
        return "\(prefix)-\(numbers)"
    }

    private static func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "150") ?? 150.0
    }
}
