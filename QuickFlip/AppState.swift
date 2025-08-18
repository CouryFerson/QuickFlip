//
//  AppState.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var currentListing: EbayListing?
    @Published var capturedImage: UIImage?
    @Published var selectedMarketplace: Marketplace?
    @Published var showingMarketplaceSelection = false

    // Add this property to access the pending analysis
    var pendingAnalysis: ItemAnalysis? {
        get { _pendingAnalysis }
        set { _pendingAnalysis = newValue }
    }
    private var _pendingAnalysis: ItemAnalysis?

    func showMarketplaceSelection(from analysis: ItemAnalysis, image: UIImage) {
        capturedImage = image
        // Store the analysis for later use
        pendingAnalysis = analysis
        showingMarketplaceSelection = true
    }

    func createListing(from analysis: ItemAnalysis, image: UIImage, for marketplace: Marketplace) {
        capturedImage = image
        selectedMarketplace = marketplace
        currentListing = EbayListing(
            title: analysis.itemName,
            description: analysis.description,
            category: analysis.category,
            condition: analysis.condition,
            startingPrice: AppState.extractStartingPrice(from: analysis.estimatedValue),
            buyItNowPrice: AppState.extractBuyItNowPrice(from: analysis.estimatedValue),
            listingType: .buyItNow,
            duration: 7,
            shippingCost: 0.0,
            returnsAccepted: true,
            returnPeriod: 30,
            photos: [image]
        )
        showingMarketplaceSelection = false
    }

    func resetToCamera() {
        currentListing = nil
        capturedImage = nil
        selectedMarketplace = nil
        showingMarketplaceSelection = false
        pendingAnalysis = nil
    }

    static func extractStartingPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0.0
    }

    static func extractBuyItNowPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        return Double(numbers.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0.0
    }
}
