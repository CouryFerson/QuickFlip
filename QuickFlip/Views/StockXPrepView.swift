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

    @State private var copiedField: String?
    @State private var selectedSize: String = "9"
    @State private var selectedCondition: String = "New"
    @State private var hasBox = true
    @State private var hasReceipt = false
    @State private var estimatedPayout: Double = 0

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
                // StockX Header (no navigation)
                stockXHeaderView

                // Product Card - StockX style
                productCard

                // Authentication Notice
                authenticationNotice

                // Form sections
                VStack(spacing: 16) {
                    sizeSection
                    conditionSection
                    accessoriesSection
                    pricingSection
                    sellGuideSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Action buttons
                actionButtonsSection

                Spacer(minLength: 30)
            }
        }
        .background(stockXGray.ignoresSafeArea())
        .onAppear {
            calculateEstimatedPayout()
        }
    }
}

// MARK: - StockX Header (No Navigation)
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

            // Market status bar
            HStack {
                Text("Sell")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(stockXBlack)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                Text("Listing Preview")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()

                Text("Step 2 of 3")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(stockXGray)
        }
    }
}

// MARK: - Product Card
private extension StockXPrepView {
    var productCard: some View {
        VStack(spacing: 0) {
            // Product image and basic info
            HStack(spacing: 16) {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .background(stockXWhite)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.productName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(stockXBlack)
                        .lineLimit(2)

                    Text(listing.colorway)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Text(listing.sku)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)

                    // Verification badge
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
            .padding(16)
            .background(stockXWhite)

            // Market data row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Sale")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    Text("$\(String(format: "%.0f", listing.lastSalePrice))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(stockXBlack)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Lowest Ask")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    Text("$\(String(format: "%.0f", listing.lowestAsk))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(stockXRed)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Highest Bid")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    Text("$\(String(format: "%.0f", listing.highestBid))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(stockXGreen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(stockXGray)
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Authentication Notice
private extension StockXPrepView {
    var authenticationNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.title2)
                .foregroundColor(stockXGreen)

            VStack(alignment: .leading, spacing: 4) {
                Text("Authentication Guaranteed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(stockXBlack)

                Text("Every item is verified by our team of experts")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(16)
        .background(stockXGreen.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Form Sections
private extension StockXPrepView {
    var sizeSection: some View {
        StockXFormSection(title: "Size", isRequired: true) {
            VStack(spacing: 12) {
                Text("Select your size (US Men's)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(["8", "8.5", "9", "9.5", "10", "10.5", "11", "11.5", "12", "12.5", "13", "14"], id: \.self) { size in
                        Button(action: {
                            selectedSize = size
                            calculateEstimatedPayout()
                        }) {
                            Text(size)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedSize == size ? stockXWhite : stockXBlack)
                                .frame(height: 40)
                                .frame(maxWidth: .infinity)
                                .background(selectedSize == size ? stockXGreen : stockXWhite)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedSize == size ? stockXGreen : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }

                StockXTipBox(
                    icon: "ruler",
                    text: "Size is crucial for accurate pricing. Double-check your size before listing."
                )
            }
        }
    }

    var conditionSection: some View {
        StockXFormSection(title: "Condition", isRequired: true) {
            VStack(spacing: 12) {
                Picker("Condition", selection: $selectedCondition) {
                    Text("New").tag("New")
                    Text("New (No Box)").tag("New (No Box)")
                    Text("Used").tag("Used")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedCondition) { _, _ in
                    calculateEstimatedPayout()
                }

                ConditionInfoCard(condition: selectedCondition)
            }
        }
    }

    var accessoriesSection: some View {
        StockXFormSection(title: "Accessories", isRequired: false) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Original Box")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(stockXBlack)

                        Text("Increases value significantly")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Toggle("", isOn: $hasBox)
                        .toggleStyle(StockXToggleStyle())
                        .onChange(of: hasBox) { _, _ in
                            calculateEstimatedPayout()
                        }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Original Receipt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(stockXBlack)

                        Text("Proof of authenticity")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Toggle("", isOn: $hasReceipt)
                        .toggleStyle(StockXToggleStyle())
                        .onChange(of: hasReceipt) { _, _ in
                            calculateEstimatedPayout()
                        }
                }
            }
        }
    }

    var pricingSection: some View {
        StockXFormSection(title: "Estimated Payout", isRequired: false) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Estimated Payout")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(stockXBlack)

                        Text("After StockX fees")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Text("$\(String(format: "%.0f", estimatedPayout))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(stockXGreen)
                }
                .padding(16)
                .background(stockXGreen.opacity(0.1))
                .cornerRadius(8)

                // Fee breakdown
                VStack(spacing: 8) {
                    HStack {
                        Text("Selling Price")
                        Spacer()
                        Text("$\(String(format: "%.0f", listing.highestBid))")
                    }
                    .font(.system(size: 14))

                    HStack {
                        Text("StockX Fee (9.5%)")
                        Spacer()
                        Text("-$\(String(format: "%.0f", listing.highestBid * 0.095))")
                            .foregroundColor(.red)
                    }
                    .font(.system(size: 14))

                    HStack {
                        Text("Payment Processing (3%)")
                        Spacer()
                        Text("-$\(String(format: "%.0f", listing.highestBid * 0.03))")
                            .foregroundColor(.red)
                    }
                    .font(.system(size: 14))

                    Divider()

                    HStack {
                        Text("Total Payout")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("$\(String(format: "%.0f", estimatedPayout))")
                            .fontWeight(.bold)
                            .foregroundColor(stockXGreen)
                    }
                    .font(.system(size: 16))
                }
                .padding(12)
                .background(stockXGray)
                .cornerRadius(8)
            }
        }
    }

    var sellGuideSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(stockXGreen)
                    .font(.title2)

                Text("Selling Tips")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(stockXBlack)

                Spacer()
            }

            VStack(spacing: 8) {
                SellTipRow(icon: "camera.fill", text: "Take clear photos of any flaws or wear")
                SellTipRow(icon: "shippingbox.fill", text: "Pack securely - StockX will inspect your item")
                SellTipRow(icon: "clock.fill", text: "Ship within 2 business days of sale")
                SellTipRow(icon: "dollarsign.circle.fill", text: "Higher condition = higher payout")
            }
        }
        .padding(16)
        .background(stockXWhite)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Primary action - Open StockX
            Button(action: {
                openStockXApp()
            }) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("List on StockX")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Live bidding marketplace")
                            .font(.system(size: 12))
                            .opacity(0.9)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(stockXWhite)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(stockXRed)
                            .cornerRadius(4)

                        Text("BIDDING")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(stockXGreen)
                    }
                }
                .foregroundColor(stockXWhite)
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [stockXGreen, stockXDarkGreen]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)

            // Secondary actions
            HStack(spacing: 12) {
                Button("Copy Details") {
                    copyListingDetails()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(stockXGreen)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(stockXWhite)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(stockXGreen, lineWidth: 1)
                )

                Button("Save Item") {
                    saveItem()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(stockXGray)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 20)
    }
}

// MARK: - StockX UI Components
struct StockXFormSection<Content: View>: View {
    let title: String
    let isRequired: Bool
    let content: Content

    init(title: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isRequired = isRequired
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.12))

                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }

                Spacer()
            }

            content
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StockXToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(configuration.isOn ? Color(red: 0.0, green: 0.7, blue: 0.4) : Color.gray.opacity(0.3))
            .frame(width: 50, height: 30)
            .overlay(
                Circle()
                    .fill(.white)
                    .frame(width: 26, height: 26)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            )
            .onTapGesture {
                configuration.isOn.toggle()
            }
    }
}

struct StockXTipBox: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.4))
                .font(.system(size: 14))

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(Color(red: 0.0, green: 0.7, blue: 0.4).opacity(0.1))
        .cornerRadius(8)
    }
}

struct ConditionInfoCard: View {
    let condition: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(conditionTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.12))

            Text(conditionDescription)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private var conditionTitle: String {
        switch condition {
        case "New":
            return "Brand New with Box"
        case "New (No Box)":
            return "Brand New without Box"
        case "Used":
            return "Previously Worn"
        default:
            return "Condition Info"
        }
    }

    private var conditionDescription: String {
        switch condition {
        case "New":
            return "Unworn with original box, tags, and accessories"
        case "New (No Box)":
            return "Unworn but missing original packaging"
        case "Used":
            return "Shows signs of wear, all flaws must be disclosed"
        default:
            return ""
        }
    }
}

struct SellTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.4))
                .font(.system(size: 14))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Helper Functions
private extension StockXPrepView {
    func calculateEstimatedPayout() {
        let basePrice = listing.highestBid

        // Adjust for condition
        var adjustedPrice = basePrice
        switch selectedCondition {
        case "New":
            adjustedPrice = basePrice
        case "New (No Box)":
            adjustedPrice = basePrice * 0.9
        case "Used":
            adjustedPrice = basePrice * 0.8
        default:
            adjustedPrice = basePrice
        }

        // Adjust for accessories
        if !hasBox {
            adjustedPrice *= 0.95
        }
        if hasReceipt {
            adjustedPrice *= 1.05
        }

        // Calculate payout after fees (9.5% + 3% processing)
        let fees = adjustedPrice * 0.125
        estimatedPayout = adjustedPrice - fees
    }

    func openStockXApp() {
        let universalListing = UniversalListing(from: listing, condition: selectedCondition, targetPrice: .competitive)
        MarketplaceIntegrationManager.postToMarketplace(.stockx, listing: universalListing, image: capturedImage)
    }

    func copyListingDetails() {
        let details = """
        STOCKX LISTING DETAILS
        
        Product: \(listing.productName)
        Colorway: \(listing.colorway)
        SKU: \(listing.sku)
        
        Size: US \(selectedSize)
        Condition: \(selectedCondition)
        
        Accessories:
        Original Box: \(hasBox ? "Yes" : "No")
        Receipt: \(hasReceipt ? "Yes" : "No")
        
        Market Data:
        Last Sale: $\(String(format: "%.0f", listing.lastSalePrice))
        Lowest Ask: $\(String(format: "%.0f", listing.lowestAsk))
        Highest Bid: $\(String(format: "%.0f", listing.highestBid))
        
        Estimated Payout: $\(String(format: "%.0f", estimatedPayout))
        """

        UIPasteboard.general.string = details
        copiedField = "All Details"

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedField = nil
        }
    }

    func saveItem() {
        print("Saving StockX item for later...")
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
