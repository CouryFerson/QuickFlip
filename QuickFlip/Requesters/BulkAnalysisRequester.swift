//
//  BulkAnalysisRequester.swift
//  QuickFlip
//
//  Updated to use Supabase Edge Functions
//

import UIKit

struct BulkAnalysisRequest {
    let image: UIImage
}

struct BulkAnalysisRequester: SupabaseRequester {
    typealias RequestType = BulkAnalysisRequest
    typealias ResponseType = BulkAnalysisResult

    let tokenCost = 2
    let model = "gpt-4o"
    let maxTokens = 1500
    let temperature = 0.3
    let tokenManager: TokenManaging
    let edgeFunctionCaller: EdgeFunctionCalling

    private let originalImage: UIImage

    var functionName: String { "analyze-bulk-items" }

    init(tokenManager: TokenManaging, edgeFunctionCaller: EdgeFunctionCalling, image: UIImage) {
        self.tokenManager = tokenManager
        self.edgeFunctionCaller = edgeFunctionCaller
        self.originalImage = image
    }

    func buildRequestBody(_ request: BulkAnalysisRequest) -> [String: Any] {
        let resizedImage = request.image.resize(maxDimension: 800)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            fatalError("Image processing failed")
        }

        let base64Image = imageData.base64EncodedString()

        return [
            "base64Image": base64Image,
            "model": model,
            "maxTokens": maxTokens,
            "temperature": temperature
        ]
    }

    func parseResponse(_ content: String) throws -> BulkAnalysisResult {
        let lines = content.components(separatedBy: .newlines)
        var items: [BulkAnalyzedItem] = []
        var currentItem: BulkAnalyzedItem?
        var totalCount = 0
        var totalValue = ""
        var sceneDescription = ""

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.hasPrefix("ITEM_") {
                if let item = currentItem {
                    items.append(item)
                }
                currentItem = BulkAnalyzedItem()
            } else if trimmedLine.hasPrefix("NAME:") {
                currentItem?.name = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("CONDITION:") {
                currentItem?.condition = String(trimmedLine.dropFirst(10)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("DESCRIPTION:") {
                currentItem?.description = String(trimmedLine.dropFirst(12)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("VALUE:") {
                currentItem?.estimatedValue = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("CATEGORY:") {
                currentItem?.category = String(trimmedLine.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("LOCATION:") {
                currentItem?.location = String(trimmedLine.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("TOTAL_COUNT:") {
                totalCount = Int(String(trimmedLine.dropFirst(13)).trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            } else if trimmedLine.hasPrefix("TOTAL_VALUE:") {
                totalValue = String(trimmedLine.dropFirst(13)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("SCENE_DESCRIPTION:") {
                sceneDescription = String(trimmedLine.dropFirst(19)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if let item = currentItem {
            items.append(item)
        }

        return BulkAnalysisResult(
            items: items,
            totalCount: totalCount,
            totalValue: totalValue,
            sceneDescription: sceneDescription,
            originalImage: originalImage,
            timestamp: Date()
        )
    }
}
