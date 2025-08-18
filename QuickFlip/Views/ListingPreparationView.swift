import SwiftUI

struct ListingPreparationView: View {
    @State private var listing: EbayListing
    let capturedImage: UIImage
    let selectedMarketplace: Marketplace
    @State private var showingSuccessAlert = false
    @State private var showingFinalListing = false
    @EnvironmentObject var itemStorage: ItemStorageService

    init(itemAnalysis: ItemAnalysis, capturedImage: UIImage, selectedMarketplace: Marketplace) {
        self.capturedImage = capturedImage
        self.selectedMarketplace = selectedMarketplace
        _listing = State(initialValue: EbayListing(
            title: itemAnalysis.itemName,
            description: itemAnalysis.description,
            category: itemAnalysis.category,
            condition: itemAnalysis.condition,
            startingPrice: AppState.extractStartingPrice(from: itemAnalysis.estimatedValue),
            buyItNowPrice: AppState.extractBuyItNowPrice(from: itemAnalysis.estimatedValue),
            listingType: .buyItNow,
            duration: 7,
            shippingCost: 0.0,
            returnsAccepted: true,
            returnPeriod: 30,
            photos: [capturedImage]
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Photos")
                        .font(.headline)
                        .padding(.horizontal)

                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .padding(.horizontal)

                    TextField("Item title", text: $listing.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }

                // Description Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .padding(.horizontal)

                    TextEditor(text: $listing.description)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }

                // Pricing Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pricing")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        // Listing Type
                        Picker("Listing Type", selection: $listing.listingType) {
                            Text("Buy It Now").tag(ListingType.buyItNow)
                            Text("Auction").tag(ListingType.auction)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        HStack {
                            if listing.listingType == .auction {
                                VStack(alignment: .leading) {
                                    Text("Starting Price")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    TextField("$0.00", value: $listing.startingPrice, format: .currency(code: "USD"))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                }
                            }

                            VStack(alignment: .leading) {
                                Text(listing.listingType == .auction ? "Buy It Now Price" : "Price")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextField("$0.00", value: $listing.buyItNowPrice, format: .currency(code: "USD"))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Shipping Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shipping")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Shipping Cost")
                            Spacer()
                            TextField("$0.00", value: $listing.shippingCost, format: .currency(code: "USD"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }
                        .padding(.horizontal)

                        if listing.shippingCost == 0 {
                            Text("💡 Free shipping (recommended - include cost in item price)")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal)
                        }
                    }
                }

                // Listing Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Listing Details")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        // Duration
                        HStack {
                            Text("Duration")
                            Spacer()
                            Picker("Duration", selection: $listing.duration) {
                                Text("3 days").tag(3)
                                Text("5 days").tag(5)
                                Text("7 days").tag(7)
                                Text("10 days").tag(10)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding(.horizontal)

                        // Condition
                        HStack {
                            Text("Condition")
                            Spacer()
                            Picker("Condition", selection: $listing.condition) {
                                Text("New").tag("New")
                                Text("Like New").tag("Like New")
                                Text("Good").tag("Good")
                                Text("Fair").tag("Fair")
                                Text("Poor").tag("Poor")
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding(.horizontal)

                        // Returns
                        HStack {
                            Text("Returns Accepted")
                            Spacer()
                            Toggle("", isOn: $listing.returnsAccepted)
                        }
                        .padding(.horizontal)

                        if listing.returnsAccepted {
                            HStack {
                                Text("Return Period")
                                Spacer()
                                Picker("Return Period", selection: $listing.returnPeriod) {
                                    Text("14 days").tag(14)
                                    Text("30 days").tag(30)
                                    Text("60 days").tag(60)
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .padding(.horizontal)

                    Text(listing.category)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                }

                actionsButtonsView

                Spacer(minLength: 50)
            }
        }
        .navigationTitle("Create Listing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Image(systemName: selectedMarketplace.iconName)
                        .foregroundColor(selectedMarketplace.color)
                    Text(selectedMarketplace.rawValue)
                        .font(.caption)
                        .foregroundColor(selectedMarketplace.color)
                }
            }
        }
        .alert("Listing Created!", isPresented: $showingSuccessAlert) {
            Button("Take Another Photo") {
                // This will pop back to root (camera view)
            }
            Button("View on \(selectedMarketplace.rawValue)") {
                // TODO: Open marketplace app or website
            }
        } message: {
            Text("Your listing has been created successfully on \(selectedMarketplace.rawValue)!")
        }
        // Add this navigation link at the end of the view:
        .fullScreenCover(isPresented: $showingFinalListing) {
            FinalListingView(
                listing: listing,
                selectedMarketplace: selectedMarketplace
            )
        }
    }

    private func createListing() {
        // Navigate to final listing view instead of just printing
        showingFinalListing = true
    }

    private func copyListingDetails() {
        let details = """
        Title: \(listing.title)
        
        Description:
        \(listing.description)
        
        Condition: \(listing.condition)
        Price: $\(String(format: "%.2f", listing.buyItNowPrice))
        Shipping: \(listing.shippingCost == 0 ? "Free" : "$\(String(format: "%.2f", listing.shippingCost))")
        Duration: \(listing.duration) days
        Returns: \(listing.returnsAccepted ? "\(listing.returnPeriod) days" : "No returns")
        
        Category: \(listing.category)
        
        Marketplace: \(selectedMarketplace.rawValue)
        """

        UIPasteboard.general.string = details

        // Show brief feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func savePhotoToLibrary() {
        UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)

        // Show brief feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

private extension ListingPreparationView {
    var actionsButtonsView: some View {
        VStack(spacing: 12) {
            // Replace the "Create eBay Listing" button with:
            NavigationLink(
                destination: FinalListingView(
                    listing: listing,
                    selectedMarketplace: selectedMarketplace
                )
                .environmentObject(itemStorage)
            ) {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)

                    Text("Create \(selectedMarketplace.rawValue) Listing")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.leading, 10)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                    Spacer()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedMarketplace.color)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
    }
}
