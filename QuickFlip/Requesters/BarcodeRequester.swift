//
//  BarcodeRequester.swift
//  QuickFlip
//
//  Updated to use Supabase Edge Functions
//

import UIKit

struct BarcodeRequest {
    let image: UIImage
}

struct BarcodeRequester: SupabaseRequester {
    typealias RequestType = BarcodeRequest
    typealias ResponseType = ItemAnalysis

    let tokenCost = 1
    let model = "gpt-4o"
    let maxTokens = 300
    let temperature = 0.1
    let tokenManager: TokenManaging
    let edgeFunctionCaller: EdgeFunctionCalling

    var functionName: String { "analyze-barcode" }

    func buildRequestBody(_ request: BarcodeRequest) -> [String: Any] {
        let resizedImage = request.image.resize(maxDimension: 800)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
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
        // Extract JSON from response
        let jsonStartIndex = content.firstIndex(of: "{") ?? content.startIndex
        let jsonEndIndex = content.lastIndex(of: "}") ?? content.endIndex
        let jsonString = String(content[jsonStartIndex...jsonEndIndex])

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NetworkError.responseParsingFailed
        }

        struct BarcodeResponse: Codable {
            let item_name: String
            let description: String
            let estimated_value: String
            let category: String
        }

        do {
            let barcodeResult = try JSONDecoder().decode(BarcodeResponse.self, from: jsonData)

            return ItemAnalysis(
                itemName: barcodeResult.item_name,
                condition: "Unknown",
                description: barcodeResult.description,
                estimatedValue: barcodeResult.estimated_value,
                category: barcodeResult.category
            )
        } catch {
            throw NetworkError.responseParsingFailed
        }
    }
}
