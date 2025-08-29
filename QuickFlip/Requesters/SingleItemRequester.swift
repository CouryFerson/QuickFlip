//
//  SingleItemRequester.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/28/25.
//

import UIKit

struct SingleItemRequest {
    let image: UIImage
}

struct SingleItemRequester: OpenAIRequester {
    typealias RequestType = SingleItemRequest
    typealias ResponseType = ItemAnalysis

    let tokenCost = 1
    let model = "gpt-4o"
    let maxTokens = 500
    let temperature = 0.3
    let tokenManager: TokenManaging

    func buildRequestBody(_ request: SingleItemRequest) -> [String: Any] {
        let resizedImage = request.image.resize(maxDimension: 800)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            fatalError("Image processing failed")
        }

        let base64Image = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64Image)"
        let prompt = """
        You are an expert at identifying items for resale on eBay. Analyze this image and provide specific details:

        ITEM: [Exact product name, brand, model if identifiable]
        CONDITION: [New/Like New/Good/Fair/Poor based on visible condition]
        DESCRIPTION: [2-3 sentences suitable for eBay listing]
        VALUE: $[low]-$[high] [estimated resale value range]
        CATEGORY: [Suggested eBay category]

        Be very specific. If it's an Apple TV remote, say "Apple TV Siri Remote (4th generation)" not just "remote". If you can see wear, scratches, or damage, mention it in the condition.
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

    func parseResponse(_ content: String) throws -> ItemAnalysis {
        let lines = content.components(separatedBy: .newlines)

        var itemName = "Unknown Item"
        var condition = ""
        var description = ""
        var estimatedValue = ""
        var category = ""

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.hasPrefix("ITEM:") {
                itemName = extractValue(from: trimmedLine, prefix: "ITEM:")
            } else if trimmedLine.hasPrefix("CONDITION:") {
                condition = extractValue(from: trimmedLine, prefix: "CONDITION:")
            } else if trimmedLine.hasPrefix("DESCRIPTION:") {
                description = extractValue(from: trimmedLine, prefix: "DESCRIPTION:")
            } else if trimmedLine.hasPrefix("VALUE:") {
                estimatedValue = extractValue(from: trimmedLine, prefix: "VALUE:")
            } else if trimmedLine.hasPrefix("CATEGORY:") {
                category = extractValue(from: trimmedLine, prefix: "CATEGORY:")
            }
        }

        return ItemAnalysis(
            itemName: itemName,
            condition: condition,
            description: description,
            estimatedValue: estimatedValue,
            category: category
        )
    }

    private func extractValue(from line: String, prefix: String) -> String {
        guard let colonIndex = line.firstIndex(of: ":") else { return "" }
        let startIndex = line.index(after: colonIndex)
        return String(line[startIndex...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "**", with: "")
    }
}
