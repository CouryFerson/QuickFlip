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
    private let supabaseService: SupabaseService

    init(authManager: AuthManager, supabaseService: SupabaseService) {
        self.authManager = authManager
        self.supabaseService = supabaseService
    }

    func analyzeSingleItem(_ image: UIImage) async throws -> ItemAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let requester = SingleItemRequester(tokenManager: authManager, edgeFunctionCaller: supabaseService)
        let request = SingleItemRequest(image: image)
        return try await requester.makeRequest(request)
    }

    func analyzeBulkItems(_ image: UIImage) async throws -> BulkAnalysisResult {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let requester = BulkAnalysisRequester(tokenManager: authManager, edgeFunctionCaller: supabaseService, image: image)
        let request = BulkAnalysisRequest(image: image)
        return try await requester.makeRequest(request)
    }

    func analyzeBarcode(_ image: UIImage) async throws -> ItemAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let requester = BarcodeRequester(tokenManager: authManager, edgeFunctionCaller: supabaseService)
        let request = BarcodeRequest(image: image)
        return try await requester.makeRequest(request)
    }

    func researchPrices(for itemName: String, category: String) async throws -> MarketplacePriceAnalysis {
        let requester = PriceResearchRequester(tokenManager: authManager, edgeFunctionCaller: supabaseService)
        let request = PriceResearchRequest(itemName: itemName, category: category)
        return try await requester.makeRequest(request)
    }

    /// Generates advanced AI analysis using live eBay data as an anchor
    /// Generates advanced AI analysis using live eBay data as an anchor
    func generateAdvancedAnalysis(for itemName: String, category: String, ebayData: MarketPriceData, isFirstGeneration: Bool) async throws -> MarketplacePriceAnalysis {
        let requester = AdvancedAnalysisRequester(tokenManager: authManager, edgeFunctionCaller: supabaseService, isFirstGeneration: isFirstGeneration)
        let request = AdvancedAnalysisRequest( itemName: itemName, category: category, ebayData: ebayData, isFirstGeneration: isFirstGeneration)

        return try await requester.makeRequest(request)
    }
}
