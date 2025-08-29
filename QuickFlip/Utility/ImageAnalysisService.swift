//
//  ImageAnalysisService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/28/25.
//

import SwiftUI

@MainActor
class ImageAnalysisService: ObservableObject {
    @Published var isAnalyzing = false

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func analyzeSingleItem(_ image: UIImage) async throws -> ItemAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let requester = SingleItemRequester(tokenManager: authManager)
        let request = SingleItemRequest(image: image)
        return try await requester.makeRequest(request)
    }

    func analyzeBulkItems(_ image: UIImage) async throws -> BulkAnalysisResult {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let requester = BulkAnalysisRequester(tokenManager: authManager, image: image)
        let request = BulkAnalysisRequest(image: image)
        return try await requester.makeRequest(request)
    }

    func analyzeBarcode(_ image: UIImage) async throws -> ItemAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let requester = BarcodeRequester(tokenManager: authManager)
        let request = BarcodeRequest(image: image)
        return try await requester.makeRequest(request)
    }

    func researchPrices(for itemName: String, category: String) async throws -> MarketplacePriceAnalysis {
        let requester = PriceResearchRequester(tokenManager: authManager)
        let request = PriceResearchRequest(itemName: itemName, category: category)
        return try await requester.makeRequest(request)
    }
}
