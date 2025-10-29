//
//  QuikListView.swift
//  QuickFlip
//
//  Created by Claude on 2025-10-28.
//

import SwiftUI
import PhotosUI

struct QuikListView: View {
    @StateObject private var viewModel: QuikListViewModel
    @Environment(\.dismiss) private var dismiss

    // Photo picker
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingImagePicker = false

    init(supabaseService: SupabaseService) {
        _viewModel = StateObject(wrappedValue: QuikListViewModel(supabaseService: supabaseService))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                StepProgressView(currentStep: viewModel.currentStep)
                    .padding()

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch viewModel.currentStep {
                        case .itemDetails:
                            ItemDetailsStepView(
                                listingData: $viewModel.listingData,
                                selectedPhotos: $selectedPhotos,
                                showingImagePicker: $showingImagePicker
                            )

                        case .platformSelection:
                            PlatformSelectionStepView(
                                listingData: $viewModel.listingData,
                                viewModel: viewModel
                            )

                        case .platformDetails:
                            PlatformDetailsStepView(
                                listingData: $viewModel.listingData,
                                viewModel: viewModel
                            )

                        case .review:
                            ReviewStepView(
                                listingData: viewModel.listingData,
                                viewModel: viewModel
                            )
                        }

                        // Validation errors
                        if !viewModel.validationErrors.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.validationErrors, id: \.self) { error in
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }

                // Navigation buttons
                HStack(spacing: 15) {
                    if viewModel.currentStep != .itemDetails {
                        Button(action: { viewModel.previousStep() }) {
                            Label("Back", systemImage: "chevron.left")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }

                    if viewModel.currentStep == .review {
                        Button(action: {
                            Task {
                                await viewModel.submitListings()
                            }
                        }) {
                            HStack {
                                if viewModel.isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Label("Submit Listings", systemImage: "paperplane.fill")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canSubmit ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                    } else {
                        Button(action: { viewModel.nextStep() }) {
                            Label("Next", systemImage: "chevron.right")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Quik List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedPhotos,
                maxSelectionCount: 10,
                matching: .images
            )
            .onChange(of: selectedPhotos) { newPhotos in
                loadPhotos(newPhotos)
            }
            .sheet(isPresented: $viewModel.showingResults) {
                ResultsView(result: viewModel.submissionResult!) {
                    dismiss()
                }
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        Task {
            viewModel.listingData.photos = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.listingData.photos.append(image)
                    }
                }
            }
        }
    }
}

// MARK: - Step Progress View
struct StepProgressView: View {
    let currentStep: QuikListStep

    var body: some View {
        HStack(spacing: 0) {
            ForEach(QuikListStep.allCases, id: \.self) { step in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 30, height: 30)

                        Image(systemName: step.icon)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }

                    Text(step.title)
                        .font(.caption2)
                        .foregroundColor(step.rawValue <= currentStep.rawValue ? .primary : .gray)
                }
                .frame(maxWidth: .infinity)

                if step != QuikListStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Item Details Step
struct ItemDetailsStepView: View {
    @Binding var listingData: QuikListingData
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var showingImagePicker: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Photos section
            VStack(alignment: .leading, spacing: 10) {
                Text("Photos")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Add photo button
                        Button(action: { showingImagePicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                Text("Add Photos")
                                    .font(.caption)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }

                        // Photo thumbnails
                        ForEach(Array(listingData.photos.enumerated()), id: \.offset) { index, photo in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
                                    .clipped()

                                Button(action: {
                                    listingData.photos.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(4)
                            }
                        }
                    }
                }
            }

            Divider()

            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                TextField("Item title (max 80 characters)", text: $listingData.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("\(listingData.title.count)/80")
                    .font(.caption)
                    .foregroundColor(listingData.title.count > 80 ? .red : .gray)
            }

            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                TextEditor(text: $listingData.description)
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            // Condition
            VStack(alignment: .leading, spacing: 8) {
                Text("Condition")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ItemCondition.allCases, id: \.self) { condition in
                            Button(action: { listingData.condition = condition }) {
                                VStack(spacing: 8) {
                                    Image(systemName: condition.icon)
                                        .font(.system(size: 24))
                                    Text(condition.rawValue)
                                        .font(.caption)
                                }
                                .frame(width: 80, height: 80)
                                .background(listingData.condition == condition ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundColor(listingData.condition == condition ? .blue : .primary)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(listingData.condition == condition ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                }
            }

            // Base Price
            VStack(alignment: .leading, spacing: 8) {
                Text("Base Price")
                    .font(.headline)
                HStack {
                    Text("$")
                    TextField("0.00", value: $listingData.basePrice, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
}

// MARK: - Platform Selection Step
struct PlatformSelectionStepView: View {
    @Binding var listingData: QuikListingData
    @ObservedObject var viewModel: QuikListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select platforms to list on:")
                .font(.headline)

            // eBay
            PlatformSelectionCard(
                platformName: "eBay",
                platformLogo: "e.square.fill",
                platformColor: Color(red: 0, green: 0.4, blue: 0.8),
                isSelected: $listingData.listToEbay,
                isAuthenticated: viewModel.ebayAuthService.isAuthenticated,
                onAuthenticate: {
                    viewModel.ebayAuthService.startAuthentication()
                }
            )

            // StockX
            PlatformSelectionCard(
                platformName: "StockX",
                platformLogo: "s.square.fill",
                platformColor: Color(red: 0, green: 0.7, blue: 0.4),
                isSelected: $listingData.listToStockX,
                isAuthenticated: viewModel.stockXAuthService.isAuthenticated,
                onAuthenticate: {
                    viewModel.stockXAuthService.startAuthentication()
                }
            )
        }
    }
}

struct PlatformSelectionCard: View {
    let platformName: String
    let platformLogo: String
    let platformColor: Color
    @Binding var isSelected: Bool
    let isAuthenticated: Bool
    let onAuthenticate: () -> Void

    var body: some View {
        Button(action: {
            if isAuthenticated {
                isSelected.toggle()
            }
        }) {
            HStack(spacing: 15) {
                // Logo
                Image(systemName: platformLogo)
                    .font(.system(size: 40))
                    .foregroundColor(platformColor)
                    .frame(width: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(platformName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isAuthenticated ? .green : .red)
                        Text(isAuthenticated ? "Connected" : "Not Connected")
                            .font(.caption)
                            .foregroundColor(isAuthenticated ? .green : .red)
                    }
                }

                Spacer()

                if isAuthenticated {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? platformColor : .gray)
                } else {
                    Button(action: onAuthenticate) {
                        Text("Sign In")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(platformColor)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }
            .padding()
            .background(isSelected ? platformColor.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? platformColor : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!isAuthenticated && isSelected)
    }
}

// MARK: - Platform Details Step
struct PlatformDetailsStepView: View {
    @Binding var listingData: QuikListingData
    @ObservedObject var viewModel: QuikListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if listingData.listToEbay {
                EbayDetailsSection(listingData: $listingData)
                    .padding()
                    .background(Color(red: 0, green: 0.4, blue: 0.8).opacity(0.05))
                    .cornerRadius(12)
            }

            if listingData.listToStockX {
                StockXDetailsSection(listingData: $listingData, viewModel: viewModel)
                    .padding()
                    .background(Color(red: 0, green: 0.7, blue: 0.4).opacity(0.05))
                    .cornerRadius(12)
            }
        }
    }
}

struct EbayDetailsSection: View {
    @Binding var listingData: QuikListingData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "e.square.fill")
                    .foregroundColor(Color(red: 0, green: 0.4, blue: 0.8))
                Text("eBay Settings")
                    .font(.headline)
            }

            // Listing Type
            Picker("Listing Type", selection: $listingData.ebayListingType) {
                ForEach(ListingType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // Starting Price (for auctions)
            if listingData.ebayListingType == .auction {
                HStack {
                    Text("Starting Price: $")
                    TextField("0.00", value: $listingData.ebayStartingPrice, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }

            // Shipping
            HStack {
                Text("Shipping: $")
                TextField("0.00", value: $listingData.ebayShippingCost, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            if listingData.ebayShippingCost == 0 {
                Text("Free shipping")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            // Duration
            Picker("Duration", selection: $listingData.ebayDuration) {
                Text("3 days").tag(3)
                Text("5 days").tag(5)
                Text("7 days").tag(7)
                Text("10 days").tag(10)
            }
            .pickerStyle(MenuPickerStyle())

            // Returns
            Toggle("Accept Returns", isOn: $listingData.ebayReturnsAccepted)

            if listingData.ebayReturnsAccepted {
                Picker("Return Period", selection: $listingData.ebayReturnPeriod) {
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                    Text("60 days").tag(60)
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}

struct StockXDetailsSection: View {
    @Binding var listingData: QuikListingData
    @ObservedObject var viewModel: QuikListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "s.square.fill")
                    .foregroundColor(Color(red: 0, green: 0.7, blue: 0.4))
                Text("StockX Settings")
                    .font(.headline)
            }

            // Product Search
            if listingData.stockXProduct == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search for Product")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("Search StockX catalog...", text: $viewModel.stockXSearchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: viewModel.stockXSearchQuery) { _ in
                                Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000) // Debounce
                                    await viewModel.searchStockXProducts()
                                }
                            }

                        if viewModel.isSearchingStockX {
                            ProgressView()
                        }
                    }

                    // Search Results
                    if !viewModel.stockXSearchResults.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.stockXSearchResults.prefix(5), id: \.productId) { product in
                                Button(action: {
                                    Task {
                                        await viewModel.selectStockXProduct(product)
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(product.title)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Text(product.brand ?? "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            } else {
                // Selected Product
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(listingData.stockXProduct!.title)
                                .font(.subheadline)
                            Text(listingData.stockXProduct!.brand ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            listingData.stockXProduct = nil
                            listingData.stockXProductId = nil
                            listingData.stockXVariant = nil
                            listingData.stockXVariantId = nil
                        }) {
                            Text("Change")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                // Variant Selection
                if viewModel.isLoadingVariants {
                    HStack {
                        ProgressView()
                        Text("Loading sizes...")
                            .font(.caption)
                    }
                } else if !viewModel.stockXVariants.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Size/Variant")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.stockXVariants, id: \.variantId) { variant in
                                    Button(action: {
                                        viewModel.selectStockXVariant(variant)
                                    }) {
                                        Text(variant.sizeDisplay ?? "N/A")
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                listingData.stockXVariantId == variant.variantId ?
                                                Color.green : Color.gray.opacity(0.2)
                                            )
                                            .foregroundColor(
                                                listingData.stockXVariantId == variant.variantId ?
                                                .white : .primary
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                }

                // Market Data & Pricing
                if let marketData = listingData.stockXMarketData {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Market Data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            if let lowestAsk = marketData.lowestAsk {
                                VStack {
                                    Text("$\(Int(lowestAsk))")
                                        .font(.headline)
                                    Text("Lowest Ask")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }

                            if let highestBid = marketData.highestBid {
                                VStack {
                                    Text("$\(Int(highestBid))")
                                        .font(.headline)
                                    Text("Highest Bid")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                // Ask Price
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Ask Price")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("$")
                        TextField("0.00", value: $listingData.stockXAskPrice, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Review Step
struct ReviewStepView: View {
    let listingData: QuikListingData
    @ObservedObject var viewModel: QuikListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Review Your Listings")
                .font(.title2)
                .bold()

            // Item Overview
            VStack(alignment: .leading, spacing: 12) {
                Text("Item Details")
                    .font(.headline)

                if let firstPhoto = listingData.photos.first {
                    Image(uiImage: firstPhoto)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                }

                Text(listingData.title)
                    .font(.title3)
                    .bold()

                Text(listingData.condition.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(listingData.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)

            // Platform Summaries
            if listingData.listToEbay {
                EbaySummaryCard(listingData: listingData)
            }

            if listingData.listToStockX {
                StockXSummaryCard(listingData: listingData)
            }
        }
    }
}

struct EbaySummaryCard: View {
    let listingData: QuikListingData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "e.square.fill")
                    .foregroundColor(Color(red: 0, green: 0.4, blue: 0.8))
                Text("eBay Listing")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Type:")
                    Spacer()
                    Text(listingData.ebayListingType.displayName)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Price:")
                    Spacer()
                    Text("$\(String(format: "%.2f", listingData.basePrice))")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Shipping:")
                    Spacer()
                    Text(listingData.ebayShippingCost == 0 ? "Free" : "$\(String(format: "%.2f", listingData.ebayShippingCost))")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Duration:")
                    Spacer()
                    Text("\(listingData.ebayDuration) days")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Returns:")
                    Spacer()
                    Text(listingData.ebayReturnsAccepted ? "\(listingData.ebayReturnPeriod) days" : "Not accepted")
                        .foregroundColor(.secondary)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(red: 0, green: 0.4, blue: 0.8).opacity(0.05))
        .cornerRadius(12)
    }
}

struct StockXSummaryCard: View {
    let listingData: QuikListingData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "s.square.fill")
                    .foregroundColor(Color(red: 0, green: 0.7, blue: 0.4))
                Text("StockX Listing")
                    .font(.headline)
            }

            if let product = listingData.stockXProduct {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Product:")
                        Spacer()
                        Text(product.title)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }

                    if let variant = listingData.stockXVariant {
                        HStack {
                            Text("Size:")
                            Spacer()
                            Text(variant.sizeDisplay ?? "N/A")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Ask Price:")
                        Spacer()
                        Text("$\(String(format: "%.2f", listingData.stockXAskPrice))")
                            .foregroundColor(.secondary)
                    }

                    if let marketData = listingData.stockXMarketData,
                       let lowestAsk = marketData.lowestAsk {
                        HStack {
                            Text("Current Lowest Ask:")
                            Spacer()
                            Text("$\(Int(lowestAsk))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(red: 0, green: 0.7, blue: 0.4).opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Results View
struct ResultsView: View {
    let result: QuikListSubmissionResult
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Overall Status
                    if result.allSuccessful {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("Successfully Listed!")
                                .font(.title2)
                                .bold()
                            Text("Your item has been listed on all selected platforms")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else if result.hasAnySuccess {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            Text("Partially Listed")
                                .font(.title2)
                                .bold()
                            Text("Some listings succeeded, others failed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                            Text("Listing Failed")
                                .font(.title2)
                                .bold()
                            Text("All listings failed to create")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }

                    // Individual Results
                    VStack(spacing: 16) {
                        if let ebayResult = result.ebayResult {
                            ResultCard(
                                platformName: "eBay",
                                platformIcon: "e.square.fill",
                                platformColor: Color(red: 0, green: 0.4, blue: 0.8),
                                success: ebayResult.success,
                                itemID: ebayResult.itemID,
                                listingURL: ebayResult.listingURL,
                                error: ebayResult.error
                            )
                        }

                        if let stockXResult = result.stockXResult {
                            ResultCard(
                                platformName: "StockX",
                                platformIcon: "s.square.fill",
                                platformColor: Color(red: 0, green: 0.7, blue: 0.4),
                                success: stockXResult.success,
                                itemID: stockXResult.listingId,
                                listingURL: nil,
                                error: stockXResult.error
                            )
                        }
                    }

                    Button(action: onDismiss) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Listing Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ResultCard: View {
    let platformName: String
    let platformIcon: String
    let platformColor: Color
    let success: Bool
    let itemID: String?
    let listingURL: String?
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: platformIcon)
                    .foregroundColor(platformColor)
                Text(platformName)
                    .font(.headline)
                Spacer()
                Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(success ? .green : .red)
            }

            if success {
                if let itemID = itemID {
                    HStack {
                        Text("Item ID:")
                            .foregroundColor(.secondary)
                        Text(itemID)
                            .font(.system(.body, design: .monospaced))
                    }
                    .font(.subheadline)
                }

                if let listingURL = listingURL, let url = URL(string: listingURL) {
                    Link(destination: url) {
                        HStack {
                            Text("View Listing")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
            } else if let error = error {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(success ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(success ? Color.green : Color.red, lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct QuikListView_Previews: PreviewProvider {
    static var previews: some View {
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://example.supabase.co")!,
            supabaseKey: "example-key"
        )
        let supabaseService = SupabaseService(client: client)
        return QuikListView(supabaseService: supabaseService)
    }
}
