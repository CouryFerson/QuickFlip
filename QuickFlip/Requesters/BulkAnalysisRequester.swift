//
//  BulkAnalysisRequester.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/28/25.
//

import UIKit

struct BulkAnalysisRequest {
    let image: UIImage
}

struct BulkAnalysisRequester: OpenAIRequester {
    typealias RequestType = BulkAnalysisRequest
    typealias ResponseType = BulkAnalysisResult

    let tokenCost = 2
    let model = "gpt-4o"
    let maxTokens = 1500
    let temperature = 0.3
    let tokenManager: TokenManaging

    private let originalImage: UIImage

    init(tokenManager: TokenManaging, image: UIImage) {
        self.tokenManager = tokenManager
        self.originalImage = image
    }

    func buildRequestBody(_ request: BulkAnalysisRequest) -> [String: Any] {
        let resizedImage = request.image.resize(maxDimension: 800)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            fatalError("Image processing failed")
        }

        let base64Image = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64Image)"

        let prompt = """
        You are an expert at identifying multiple items for resale. Analyze this image and identify ALL sellable items you can see. For each item, provide detailed analysis.

        Respond in this EXACT format:

        ITEM_1:
        NAME: [Exact product name, brand, model if identifiable]
        CONDITION: [New/Like New/Good/Fair/Poor based on visible condition]
        DESCRIPTION: [2-3 sentences suitable for eBay listing]
        VALUE: $[low]-$[high] [estimated resale value range]
        CATEGORY: [eBay category]
        LOCATION: [describe where in image - "top left", "center", etc.]

        ITEM_2:
        [repeat format if another item found]

        SUMMARY:
        TOTAL_COUNT: [number of sellable items found]
        TOTAL_VALUE: $[sum of low estimates]-$[sum of high estimates]
        SCENE_DESCRIPTION: [brief description of the scene/setting]

        Be thorough but concise. If you see fewer than 3 items, that's fine - just analyze what you can clearly identify.
        """

        return [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": dataURL]]
                    ]
                ]
            ],
            "max_tokens": maxTokens,
            "temperature": temperature
        ]
    }

    func parseResponse(_ content: String) throws -> BulkAnalysisResult {
        // Use your existing parsing logic from BulkAnalysisService
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
