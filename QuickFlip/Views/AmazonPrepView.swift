//
//  AmazonPrepView.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/19/25.
//

import SwiftUI

struct AmazonPrepView: View {
    @State private var listing: AmazonListing
    let capturedImage: UIImage
    @Environment(\.presentationMode) var presentationMode

    @State private var showingFBACalculator = false
    @State private var selectedFulfillment: FulfillmentMethod = .fba
    @State private var estimatedFees: AmazonFees?
    @State private var copiedField: String?

    // Amazon Brand Colors & Styling
    private let amazonOrange = Color(red: 1.0, green: 0.6, blue: 0.0) // Amazon orange
    private let amazonBlue = Color(red: 0.14, green: 0.25, blue: 0.38) // Amazon navy
    private let amazonGray = Color(red: 0.95, green: 0.95, blue: 0.96) // Amazon light gray
    private let amazonWhite = Color.white
    private let amazonGreen = Color(red: 0.0, green: 0.47, blue: 0.0) // Amazon success green

    init(listing: AmazonListing, capturedImage: UIImage) {
        self._listing = State(initialValue: listing)
        self.capturedImage = capturedImage
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Amazon Header
                    amazonHeaderView

                    // Product Overview Card
                    productOverviewCard

                    // Listing Details Sections
                    VStack(spacing: 1) {
                        productTitleSection
                        categorySection
                        pricingSection
                        productDetailsSection
                        keywordsSection
                        fulfillmentSection

                        if selectedFulfillment == .fba {
                            fbaCalculatorSection
                        }
                    }

                    // Action Buttons
                    actionButtonsSection

                    Spacer(minLength: 30)
                }
            }
            .background(amazonGray.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFBACalculator) {
            FBACalculatorSheet(
                listing: listing,
                fees: $estimatedFees
            )
        }
        .onAppear {
            calculateAmazonFees()
        }
    }
}

// MARK: - Amazon Header
private extension AmazonPrepView {
    var amazonHeaderView: some View {
        VStack(spacing: 0) {
            // Top bar with Amazon branding
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(amazonWhite)
                        .font(.headline)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("amazon")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(amazonWhite)

                    Text(".com")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(amazonWhite.opacity(0.9))
                }

                Spacer()

                // Menu button
                Button(action: {}) {
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(amazonWhite)
                        .font(.headline)
                }
            }
            .padding()
            .background(amazonBlue)

            // Seller Central breadcrumb
            HStack {
                Text("Seller Central")
                    .font(.caption)
                    .foregroundColor(.gray)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.gray)

                Text("Add a Product")
                    .font(.caption)
                    .foregroundColor(.gray)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.gray)

                Text("Listing Preview")
                    .font(.caption)
                    .foregroundColor(amazonBlue)
                    .fontWeight(.medium)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(amazonWhite)
        }
    }
}

// MARK: - Product Overview
private extension AmazonPrepView {
    var productOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Product Listing Preview")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(amazonBlue)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(amazonGreen)
                        .frame(width: 8, height: 8)
                    Text("Ready to List")
                        .font(.caption)
                        .foregroundColor(amazonGreen)
                        .fontWeight(.medium)
                }
            }

            HStack(spacing: 16) {
                // Product Image
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .background(amazonWhite)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text(listing.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(amazonBlue)
                        .lineLimit(3)

                    HStack {
                        Text("$\(String(format: "%.2f", listing.price))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)

                        if listing.price > 25 {
                            HStack(spacing: 2) {
                                Image(systemName: "truck.box.fill")
                                    .font(.caption)
                                    .foregroundColor(amazonBlue)
                                Text("Prime")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(amazonBlue)
                            }
                        }
                    }

                    HStack {
                        Text("Category:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(listing.category)
                            .font(.caption)
                            .foregroundColor(amazonBlue)
                    }

                    // Star rating mockup
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(amazonOrange)
                        }
                        Text("(New)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(amazonWhite)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Listing Sections
private extension AmazonPrepView {
    var productTitleSection: some View {
        AmazonSection(title: "Product Title", isRequired: true) {
            VStack(spacing: 12) {
                TextEditor(text: $listing.title)
                    .frame(height: 80)
                    .padding(8)
                    .background(amazonWhite)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                HStack {
                    Text("\(listing.title.count)/250 characters")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    CopyButton(text: listing.title, fieldName: "Title", copiedField: $copiedField)
                }

                // Amazon title optimization tips
                AmazonTipBox(
                    icon: "lightbulb.fill",
                    title: "Title Optimization",
                    tips: [
                        "Include main keywords early",
                        "Mention brand, model, and key features",
                        "Use proper capitalization",
                        "No promotional language (Best, Sale, etc.)"
                    ]
                )
            }
        }
    }

    var categorySection: some View {
        AmazonSection(title: "Product Category", isRequired: true) {
            VStack(spacing: 12) {
                HStack {
                    Text("Suggested Category:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(listing.category)
                        .font(.subheadline)
                        .foregroundColor(amazonBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(amazonBlue.opacity(0.1))
                        .cornerRadius(6)
                }

                if listing.browseNode != nil {
                    HStack {
                        Text("Browse Node:")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(listing.browseNode ?? "")
                            .font(.caption)
                            .foregroundColor(amazonBlue)

                        Spacer()

                        CopyButton(text: listing.browseNode ?? "", fieldName: "Browse Node", copiedField: $copiedField)
                    }
                }

                if listing.requiresApproval {
                    AmazonWarningBox(
                        title: "Category Approval Required",
                        message: "This category may require approval before listing. Check Seller Central for requirements."
                    )
                }
            }
        }
    }

    var pricingSection: some View {
        AmazonSection(title: "Pricing & Offers", isRequired: true) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Your Price")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            Text("$")
                                .font(.headline)
                                .foregroundColor(.gray)

                            TextField("0.00", value: $listing.price, format: .number.precision(.fractionLength(2)))
                                .font(.headline)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(AmazonTextFieldStyle())
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Estimated Fees")
                            .font(.caption)
                            .foregroundColor(.gray)

                        if let fees = estimatedFees {
                            Text("$\(String(format: "%.2f", fees.totalFees))")
                                .font(.headline)
                                .foregroundColor(.red)
                        } else {
                            Text("Calculating...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                if let fees = estimatedFees {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Net Profit:")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Text("$\(String(format: "%.2f", fees.netProfit))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(fees.netProfit > 0 ? amazonGreen : .red)
                        }

                        HStack {
                            Text("Profit Margin:")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Spacer()

                            Text("\(String(format: "%.1f", fees.profitMargin))%")
                                .font(.caption)
                                .foregroundColor(fees.profitMargin > 15 ? amazonGreen : .orange)
                        }
                    }
                    .padding()
                    .background(amazonGray)
                    .cornerRadius(6)
                }

                Button("Calculate Detailed Fees") {
                    showingFBACalculator = true
                }
                .font(.subheadline)
                .foregroundColor(amazonBlue)
            }
        }
    }

    var productDetailsSection: some View {
        AmazonSection(title: "Product Details", isRequired: false) {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextEditor(text: $listing.description)
                        .frame(height: 100)
                        .padding(8)
                        .background(amazonWhite)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    HStack {
                        Spacer()
                        CopyButton(text: listing.description, fieldName: "Description", copiedField: $copiedField)
                    }
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("UPC/EAN")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextField("Required for most categories", text: $listing.upc)
                            .textFieldStyle(AmazonTextFieldStyle())
                    }

                    VStack(alignment: .leading) {
                        Text("Brand")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextField("Brand name", text: $listing.brand)
                            .textFieldStyle(AmazonTextFieldStyle())
                    }
                }
            }
        }
    }

    var keywordsSection: some View {
        AmazonSection(title: "Keywords & Search Terms", isRequired: false) {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search Terms")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextEditor(text: $listing.searchTerms)
                        .frame(height: 80)
                        .padding(8)
                        .background(amazonWhite)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    HStack {
                        Text("Separate with spaces, no commas")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer()

                        CopyButton(text: listing.searchTerms, fieldName: "Search Terms", copiedField: $copiedField)
                    }
                }

                AmazonTipBox(
                    icon: "magnifyingglass",
                    title: "Keyword Strategy",
                    tips: [
                        "Use relevant synonyms and variations",
                        "Include misspellings customers might use",
                        "Add complementary product terms",
                        "Max 250 bytes total"
                    ]
                )
            }
        }
    }

    var fulfillmentSection: some View {
        AmazonSection(title: "Fulfillment Method", isRequired: true) {
            VStack(spacing: 12) {
                Picker("Fulfillment", selection: $selectedFulfillment) {
                    Text("Fulfillment by Amazon (FBA)").tag(FulfillmentMethod.fba)
                    Text("Fulfillment by Merchant (FBM)").tag(FulfillmentMethod.fbm)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedFulfillment) { _ in
                    calculateAmazonFees()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedFulfillment == .fba ? "FBA Benefits" : "FBM Benefits")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if selectedFulfillment == .fba {
                            Text("• Prime eligibility\n• Amazon handles shipping\n• Customer service included")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("• Lower fees\n• Full control over shipping\n• Direct customer contact")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    var fbaCalculatorSection: some View {
        AmazonSection(title: "FBA Fee Calculator", isRequired: false) {
            VStack(spacing: 12) {
                if let fees = estimatedFees {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Referral Fee")
                            Spacer()
                            Text("$\(String(format: "%.2f", fees.referralFee))")
                        }
                        .font(.caption)

                        HStack {
                            Text("FBA Fee")
                            Spacer()
                            Text("$\(String(format: "%.2f", fees.fbaFee))")
                        }
                        .font(.caption)

                        HStack {
                            Text("Storage Fee (Monthly)")
                            Spacer()
                            Text("$\(String(format: "%.2f", fees.storageFee))")
                        }
                        .font(.caption)

                        Divider()

                        HStack {
                            Text("Total Amazon Fees")
                                .fontWeight(.medium)
                            Spacer()
                            Text("$\(String(format: "%.2f", fees.totalFees))")
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(amazonGray)
                    .cornerRadius(6)
                }

                Button("View Detailed Calculator") {
                    showingFBACalculator = true
                }
                .font(.subheadline)
                .foregroundColor(amazonBlue)
            }
        }
    }

    var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Primary action - Go to Amazon
            Button(action: {
                openAmazonSellerCentral()
            }) {
                HStack {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Continue on Amazon")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("Opens Amazon Seller Central")
                            .font(.caption)
                            .opacity(0.9)
                    }

                    Spacer()

                    Text("SELLER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(amazonWhite)
                        .foregroundColor(amazonOrange)
                        .cornerRadius(4)
                }
                .foregroundColor(amazonWhite)
                .padding()
                .background(amazonOrange)
                .cornerRadius(8)
            }
            .padding(.horizontal)

            // Secondary actions
            HStack(spacing: 12) {
                Button("Copy All Details") {
                    copyAllListingDetails()
                }
                .font(.subheadline)
                .foregroundColor(amazonBlue)
                .padding()
                .background(amazonWhite)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(amazonBlue, lineWidth: 1)
                )

                Button("Save Draft") {
                    saveDraft()
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
                .background(amazonGray)
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

// MARK: - Amazon UI Components
struct AmazonSection<Content: View>: View {
    let title: String
    let isRequired: Bool
    let content: Content

    init(title: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isRequired = isRequired
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.14, green: 0.25, blue: 0.38))

                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }

                Spacer()
            }
            .padding()
            .background(Color(red: 0.94, green: 0.94, blue: 0.95))

            VStack {
                content
            }
            .padding()
            .background(Color.white)
        }
    }
}

struct AmazonTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(8)
            .background(Color.white)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

struct AmazonTipBox: View {
    let icon: String
    let title: String
    let tips: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.0))
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.14, green: 0.25, blue: 0.38))

                ForEach(tips, id: \.self) { tip in
                    Text("• \(tip)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.1))
        .cornerRadius(6)
    }
}

struct AmazonWarningBox: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - FBA Calculator Sheet
struct FBACalculatorSheet: View {
    let listing: AmazonListing
    @Binding var fees: AmazonFees?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                Text("FBA Fee Calculator")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()

                // Detailed fee breakdown would go here
                Text("Detailed calculator coming soon...")
                    .foregroundColor(.gray)

                Spacer()
            }
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Helper Functions
private extension AmazonPrepView {
    func calculateAmazonFees() {
        // Simplified fee calculation
        let referralFeeRate: Double = listing.category.lowercased().contains("electronics") ? 0.08 : 0.15
        let referralFee = listing.price * referralFeeRate

        let fbaFee: Double = selectedFulfillment == .fba ? 3.22 : 0 // Simplified
        let storageFee: Double = 0.75 // Monthly estimate

        let totalFees = referralFee + fbaFee + storageFee
        let netProfit = listing.price - totalFees
        let profitMargin = (netProfit / listing.price) * 100

        estimatedFees = AmazonFees(
            referralFee: referralFee,
            fbaFee: fbaFee,
            storageFee: storageFee,
            totalFees: totalFees,
            netProfit: netProfit,
            profitMargin: profitMargin
        )
    }

    func openAmazonSellerCentral() {
        let url = URL(string: "https://sellercentral.amazon.com/hz/inventory/add-products/search")!
        UIApplication.shared.open(url)
    }

    func copyAllListingDetails() {
        let details = """
        AMAZON LISTING DETAILS
        
        Title: \(listing.title)
        
        Price: $\(String(format: "%.2f", listing.price))
        
        Category: \(listing.category)
        
        Description:
        \(listing.description)
        
        Brand: \(listing.brand)
        UPC: \(listing.upc)
        
        Search Terms: \(listing.searchTerms)
        
        Fulfillment: \(selectedFulfillment == .fba ? "FBA" : "FBM")
        """

        UIPasteboard.general.string = details
        copiedField = "All Details"

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedField = nil
        }
    }

    func saveDraft() {
        // Save to UserDefaults or Core Data
        print("Saving Amazon listing draft...")
    }
}

// MARK: - Models
struct AmazonListing {
    var title: String
    var description: String
    var price: Double
    var category: String
    var browseNode: String?
    var brand: String
    var upc: String
    var searchTerms: String
    var requiresApproval: Bool

    // Convenience initializer from ItemAnalysis
    init(from itemAnalysis: ItemAnalysis, image: UIImage) {
        self.title = AmazonListing.optimizeTitle(itemAnalysis.itemName)
        self.description = itemAnalysis.description
        self.price = AmazonListing.extractPrice(from: itemAnalysis.estimatedValue)
        self.category = itemAnalysis.category
        self.browseNode = nil // Would need category mapping
        self.brand = AmazonListing.extractBrand(from: itemAnalysis.itemName)
        self.upc = ""
        self.searchTerms = AmazonListing.generateSearchTerms(from: itemAnalysis)
        self.requiresApproval = AmazonListing.checkApprovalRequired(category: itemAnalysis.category)
    }

    private static func optimizeTitle(_ title: String) -> String {
        // Amazon title optimization
        return title.replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "25") ?? 25.0
    }

    private static func extractBrand(from title: String) -> String {
        let commonBrands = ["Apple", "Samsung", "Nike", "Sony", "Microsoft", "Google", "Amazon", "Dell", "HP", "Canon", "Nikon"]
        for brand in commonBrands {
            if title.lowercased().contains(brand.lowercased()) {
                return brand
            }
        }
        return "Generic"
    }

    private static func generateSearchTerms(from analysis: ItemAnalysis) -> String {
        var terms: [String] = []

        // Add item name words
        let words = analysis.itemName.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 }

        terms.append(contentsOf: words)

        // Add category terms
        terms.append(analysis.category.lowercased())

        // Add condition synonyms
        if analysis.condition.lowercased().contains("new") {
            terms.append(contentsOf: ["brand new", "unopened", "sealed"])
        } else {
            terms.append(contentsOf: ["used", "pre-owned", "second hand"])
        }

        // Remove duplicates and join
        let uniqueTerms = Array(Set(terms)).prefix(20)
        return uniqueTerms.joined(separator: " ")
    }

    private static func checkApprovalRequired(category: String) -> Bool {
        let restrictedCategories = ["electronics", "beauty", "grocery", "automotive", "clothing"]
        return restrictedCategories.contains { category.lowercased().contains($0) }
    }
}

struct AmazonFees {
    let referralFee: Double
    let fbaFee: Double
    let storageFee: Double
    let totalFees: Double
    let netProfit: Double
    let profitMargin: Double
}

enum FulfillmentMethod {
    case fba, fbm
}
