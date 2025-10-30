//
//  SingleItemRequester.swift
//  QuickFlip
//
//  Updated to use Supabase Edge Functions via SupabaseService
//

import UIKit

struct SingleItemRequest {
    let image: UIImage
}

struct SingleItemRequester: SupabaseRequester {
    typealias RequestType = SingleItemRequest
    typealias ResponseType = ItemAnalysis

    let tokenCost = 1
    let model = "gpt-4o"
    let maxTokens = 500
    let temperature = 0.3
    let tokenManager: TokenManaging
    let edgeFunctionCaller: EdgeFunctionCalling

    // Edge function name
    var functionName: String { "analyze-single-item" }

    func buildRequestBody(_ request: SingleItemRequest) -> [String: Any] {
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

    func parseResponse(_ content: String) throws -> ItemAnalysis {
        let lines = content.components(separatedBy: .newlines)

        var itemName = "Unknown Item"
        var condition = ""
        var description = ""
        var estimatedValue = ""
        var category = ""
        var itemSpecifics: [String: String]?

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanLine = trimmedLine.replacingOccurrences(of: "**", with: "")

            if cleanLine.hasPrefix("ITEM:") {
                itemName = String(cleanLine.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if cleanLine.hasPrefix("CONDITION:") {
                condition = String(cleanLine.dropFirst(10)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if cleanLine.hasPrefix("DESCRIPTION:") {
                description = String(cleanLine.dropFirst(12)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if cleanLine.hasPrefix("VALUE:") {
                estimatedValue = String(cleanLine.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if cleanLine.hasPrefix("CATEGORY:") {
                category = String(cleanLine.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if cleanLine.hasPrefix("ATTRIBUTES:") {
                let attributesJSON = String(cleanLine.dropFirst(11)).trimmingCharacters(in: .whitespacesAndNewlines)
                // Parse JSON string to dictionary
                if let data = attributesJSON.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                    itemSpecifics = json
                }
            }
        }

        return ItemAnalysis(
            itemName: itemName,
            condition: condition,
            description: description,
            estimatedValue: estimatedValue,
            category: category,
            itemSpecifics: itemSpecifics
        )
    }
}
