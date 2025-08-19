//
//  BulkAnalysisService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import Foundation
import UIKit

class BulkAnalysisService: ObservableObject {

    func analyzeBulkItems(image: UIImage) async throws -> BulkAnalysisResult {
        print("QuickFlip: Starting bulk analysis...")

        let resizedImage = image.resize(maxDimension: 800)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            print("QuickFlip: Failed to convert image to JPEG data")
            throw BulkAnalysisError.imageProcessingFailed
        }

        print("QuickFlip: Image size: \(imageData.count) bytes")

        let base64Image = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64Image)"

        print("QuickFlip: Making API request to OpenAI...")

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

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": dataURL,
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1500,
            "temperature": 0.3
        ]

        guard let url = URL(string: OpenAIConfig.apiURL) else {
            print("QuickFlip: Invalid API URL")
            throw BulkAnalysisError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60.0 // Add timeout

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("QuickFlip: Request body created successfully")
        } catch {
            print("QuickFlip: Failed to encode request: \(error)")
            throw BulkAnalysisError.requestEncodingFailed
        }

        do {
            print("QuickFlip: Sending request to OpenAI...")
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("QuickFlip: Response status code: \(httpResponse.statusCode)")

                if httpResponse.statusCode != 200 {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("QuickFlip: API Error Response: \(errorString)")
                    }
                    throw BulkAnalysisError.responseParsingFailed
                }
            }

            print("QuickFlip: Received response, parsing JSON...")

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("QuickFlip: Failed to parse top-level JSON")
                throw BulkAnalysisError.responseParsingFailed
            }

            guard let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                print("QuickFlip: Failed to extract content from response")
                print("QuickFlip: JSON structure: \(json)")
                throw BulkAnalysisError.responseParsingFailed
            }

            print("QuickFlip: Successfully extracted content, parsing bulk analysis...")
            print("QuickFlip: Content length: \(content.count) characters")

            let result = parseBulkAnalysisResponse(content, originalImage: image)
            print("QuickFlip: Parsed \(result.items.count) items successfully")

            return result

        } catch {
            print("QuickFlip: Network/parsing error: \(error)")
            throw BulkAnalysisError.responseParsingFailed
        }
    }

    private func parseBulkAnalysisResponse(_ content: String, originalImage: UIImage) -> BulkAnalysisResult {
        let lines = content.components(separatedBy: .newlines)
        var items: [BulkAnalyzedItem] = []
        var currentItem: BulkAnalyzedItem?
        var totalCount = 0
        var totalValue = ""
        var sceneDescription = ""

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Start of new item
            if trimmedLine.hasPrefix("ITEM_") {
                // Save previous item if exists
                if let item = currentItem {
                    items.append(item)
                }
                // Start new item
                currentItem = BulkAnalyzedItem()
            }
            // Parse item properties
            else if trimmedLine.hasPrefix("NAME:") {
                currentItem?.name = String(trimmedLine.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            else if trimmedLine.hasPrefix("CONDITION:") {
                currentItem?.condition = String(trimmedLine.dropFirst(10)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            else if trimmedLine.hasPrefix("DESCRIPTION:") {
                currentItem?.description = String(trimmedLine.dropFirst(12)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            else if trimmedLine.hasPrefix("VALUE:") {
                currentItem?.estimatedValue = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            else if trimmedLine.hasPrefix("CATEGORY:") {
                currentItem?.category = String(trimmedLine.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            else if trimmedLine.hasPrefix("LOCATION:") {
                currentItem?.location = String(trimmedLine.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // Parse summary
            else if trimmedLine.hasPrefix("TOTAL_COUNT:") {
                totalCount = Int(String(trimmedLine.dropFirst(13)).trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            }
            else if trimmedLine.hasPrefix("TOTAL_VALUE:") {
                totalValue = String(trimmedLine.dropFirst(13)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            else if trimmedLine.hasPrefix("SCENE_DESCRIPTION:") {
                sceneDescription = String(trimmedLine.dropFirst(19)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Don't forget the last item
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

// MARK: - Models
struct BulkAnalysisResult {
    let items: [BulkAnalyzedItem]
    let totalCount: Int
    let totalValue: String
    let sceneDescription: String
    let originalImage: UIImage
    let timestamp: Date

    var formattedItemCount: String {
        return "\(items.count) item\(items.count == 1 ? "" : "s")"
    }
}

class BulkAnalyzedItem: ObservableObject {
    var name: String = ""
    var condition: String = ""
    var description: String = ""
    var estimatedValue: String = ""
    var category: String = ""
    var location: String = ""

    func toItemAnalysis() -> ItemAnalysis {
        return ItemAnalysis(
            itemName: name,
            condition: condition,
            description: description,
            estimatedValue: estimatedValue,
            category: category
        )
    }
}

enum BulkAnalysisError: Error {
    case imageProcessingFailed
    case invalidURL
    case requestEncodingFailed
    case responseParsingFailed
}
