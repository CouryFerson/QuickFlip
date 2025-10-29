//
//  QuikListViewModel.swift
//  QuickFlip
//
//  Created by Claude on 2025-10-28.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class QuikListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var listingData = QuikListingData()
    @Published var currentStep: QuikListStep = .itemDetails
    @Published var isSubmitting = false
    @Published var submissionResult: QuikListSubmissionResult?
    @Published var showingResults = false
    @Published var validationErrors: [String] = []

    // StockX search state
    @Published var stockXSearchQuery = ""
    @Published var stockXSearchResults: [StockXProduct] = []
    @Published var isSearchingStockX = false
    @Published var stockXVariants: [StockXVariant] = []
    @Published var isLoadingVariants = false

    // Services
    let ebayAuthService: eBayAuthService
    private let ebayTradingService: eBayTradingListingService
    let stockXAuthService: StockXAuthService
    private let stockXListingService: StockXListingService
    private let supabaseService: SupabaseService

    // MARK: - Computed Properties
    var canProceedFromItemDetails: Bool {
        let errors = listingData.validateUniversalFields()
        return errors.isEmpty
    }

    var canProceedFromPlatformSelection: Bool {
        return listingData.listToEbay || listingData.listToStockX
    }

    var needsEbayAuth: Bool {
        listingData.listToEbay && !ebayAuthService.isAuthenticated
    }

    var needsStockXAuth: Bool {
        listingData.listToStockX && !stockXAuthService.isAuthenticated
    }

    var canSubmit: Bool {
        let validation = listingData.canSubmit()
        return validation.canSubmit && !isSubmitting
    }

    // MARK: - Initialization
    init(supabaseService: SupabaseService, scannedItem: ScannedItem? = nil, capturedImage: UIImage? = nil) {
        self.supabaseService = supabaseService

        // Initialize auth services
        let ebayAuth = eBayAuthService(supabaseService: supabaseService)
        let stockXAuth = StockXAuthService(supabaseService: supabaseService)

        self.ebayAuthService = ebayAuth
        self.stockXAuthService = stockXAuth

        // Initialize listing services with auth dependencies
        self.ebayTradingService = eBayTradingListingService(
            authService: ebayAuth,
            supabaseService: supabaseService
        )
        self.stockXListingService = StockXListingService(
            supabaseService: supabaseService,
            authService: stockXAuth
        )

        // Pre-populate with scanned item data if provided
        if let scannedItem = scannedItem, let capturedImage = capturedImage {
            self.listingData = QuikListingData(from: scannedItem, image: capturedImage)
        }
    }

    // MARK: - Navigation
    func nextStep() {
        validationErrors = []

        switch currentStep {
        case .itemDetails:
            let errors = listingData.validateUniversalFields()
            if errors.isEmpty {
                currentStep = .platformSelection
            } else {
                validationErrors = errors
            }

        case .platformSelection:
            if !canProceedFromPlatformSelection {
                validationErrors = ["Please select at least one platform"]
                return
            }
            // Check if any platform needs specific details
            if listingData.listToStockX && (listingData.stockXProductId == nil || listingData.stockXVariantId == nil) {
                currentStep = .platformDetails
            } else if listingData.listToEbay {
                currentStep = .platformDetails
            } else {
                currentStep = .review
            }

        case .platformDetails:
            // Validate platform-specific fields
            var errors: [String] = []
            if listingData.listToEbay {
                errors.append(contentsOf: listingData.validateEbayFields())
            }
            if listingData.listToStockX {
                errors.append(contentsOf: listingData.validateStockXFields())
            }

            if errors.isEmpty {
                currentStep = .review
            } else {
                validationErrors = errors
            }

        case .review:
            break
        }
    }

    func previousStep() {
        validationErrors = []

        switch currentStep {
        case .itemDetails:
            break
        case .platformSelection:
            currentStep = .itemDetails
        case .platformDetails:
            currentStep = .platformSelection
        case .review:
            currentStep = .platformDetails
        }
    }

    // MARK: - StockX Product Search
    func searchStockXProducts() async {
        guard !stockXSearchQuery.isEmpty else {
            stockXSearchResults = []
            return
        }

        isSearchingStockX = true

        do {
            // Get valid access token
            let accessToken = try await stockXAuthService.getValidAccessToken()

            let response = try await supabaseService.searchStockXProducts(
                query: stockXSearchQuery,
                pageSize: 20,
                pageNumber: 1,
                accessToken: accessToken
            )
            stockXSearchResults = response.products
        } catch {
            print("Error searching StockX products: \(error)")
            stockXSearchResults = []
        }

        isSearchingStockX = false
    }

    func selectStockXProduct(_ product: StockXProduct) async {
        listingData.stockXProduct = product
        listingData.stockXProductId = product.productId

        // Load variants for this product
        await loadStockXVariants(productId: product.productId)
    }

    func loadStockXVariants(productId: String) async {
        isLoadingVariants = true

        do {
            // Get valid access token
            let accessToken = try await stockXAuthService.getValidAccessToken()

            let variants = try await supabaseService.getStockXVariants(
                productId: productId,
                accessToken: accessToken
            )
            stockXVariants = variants

            // Auto-select if only one variant
            if variants.count == 1, let variant = variants.first {
                selectStockXVariant(variant)
            }
        } catch {
            print("Error loading StockX variants: \(error)")
            stockXVariants = []
        }

        isLoadingVariants = false
    }

    func selectStockXVariant(_ variant: StockXVariant) {
        listingData.stockXVariant = variant
        listingData.stockXVariantId = variant.variantId

        // Load market data for pricing guidance
        Task {
            await loadStockXMarketData(variantId: variant.variantId)
        }
    }

    func loadStockXMarketData(variantId: String) async {
        // Need productId for market data call
        guard let productId = listingData.stockXProductId else {
            print("Cannot load market data: missing productId")
            return
        }

        do {
            // Get valid access token
            let accessToken = try await stockXAuthService.getValidAccessToken()

            let marketData = try await supabaseService.getStockXMarketData(
                productId: productId,
                variantId: variantId,
                currencyCode: "USD",
                country: "US",
                accessToken: accessToken
            )
            listingData.stockXMarketData = marketData

            // Suggest price based on market data if ask price is 0
            if listingData.stockXAskPrice == 0, let lowestAsk = marketData.lowestAsk {
                listingData.stockXAskPrice = lowestAsk
            }
        } catch {
            print("Error loading StockX market data: \(error)")
        }
    }

    // MARK: - Submission
    func submitListings() async {
        guard canSubmit else { return }

        isSubmitting = true
        var result = QuikListSubmissionResult()

        // Submit to eBay if selected
        if listingData.listToEbay {
            result.ebayResult = await submitToEbay()
        }

        // Submit to StockX if selected
        if listingData.listToStockX {
            result.stockXResult = await submitToStockX()
        }

        submissionResult = result
        isSubmitting = false
        showingResults = true
    }

    private func submitToEbay() async -> EbaySubmissionResult {
        // Create EbayListing from our data
        let ebayListing = EbayListing(
            title: listingData.title,
            description: listingData.description,
            category: "", // Will be auto-generated by service
            condition: mapConditionToEbayString(listingData.condition),
            startingPrice: listingData.ebayListingType == .auction ? listingData.ebayStartingPrice : 0,
            buyItNowPrice: listingData.ebayListingType == .buyItNow ? listingData.basePrice : 0,
            listingType: listingData.ebayListingType == .auction ? .auction : .buyItNow,
            duration: listingData.ebayDuration,
            shippingCost: listingData.ebayShippingCost,
            returnsAccepted: listingData.ebayReturnsAccepted,
            returnPeriod: listingData.ebayReturnPeriod,
            photos: listingData.photos
        )

        // Use first photo for listing
        guard let mainPhoto = listingData.photos.first else {
            return EbaySubmissionResult(success: false, error: "No photo available")
        }

        do {
            let response = try await ebayTradingService.createListing(ebayListing, image: mainPhoto)

            return EbaySubmissionResult(
                success: true,
                itemID: response.listingID,
                listingURL: response.listingURL
            )
        } catch {
            return EbaySubmissionResult(success: false, error: error.localizedDescription)
        }
    }

    private func submitToStockX() async -> StockXSubmissionResult {
        guard let variantId = listingData.stockXVariantId else {
            return StockXSubmissionResult(success: false, error: "No variant selected")
        }

        do {
            let response = try await stockXListingService.placeAsk(
                variantId: variantId,
                askPrice: listingData.stockXAskPrice,
                currencyCode: "USD",
                inventoryType: "STANDARD"
            )

            if let error = response.error {
                return StockXSubmissionResult(success: false, error: error)
            }

            return StockXSubmissionResult(
                success: true,
                listingId: response.listingId,
                operationStatus: response.operationStatus
            )
        } catch {
            return StockXSubmissionResult(success: false, error: error.localizedDescription)
        }
    }

    // MARK: - Helper Methods
    private func mapConditionToEbayString(_ condition: ItemCondition) -> String {
        return condition.rawValue
    }

    func reset() {
        listingData = QuikListingData()
        currentStep = .itemDetails
        submissionResult = nil
        showingResults = false
        validationErrors = []
        stockXSearchQuery = ""
        stockXSearchResults = []
        stockXVariants = []
    }
}

// MARK: - Step Enum
enum QuikListStep: Int, CaseIterable {
    case itemDetails = 0
    case platformSelection = 1
    case platformDetails = 2
    case review = 3

    var title: String {
        switch self {
        case .itemDetails: return "Item Details"
        case .platformSelection: return "Select Platforms"
        case .platformDetails: return "Platform Details"
        case .review: return "Review & Submit"
        }
    }

    var icon: String {
        switch self {
        case .itemDetails: return "doc.text.image"
        case .platformSelection: return "square.grid.2x2"
        case .platformDetails: return "slider.horizontal.3"
        case .review: return "checkmark.circle"
        }
    }
}
