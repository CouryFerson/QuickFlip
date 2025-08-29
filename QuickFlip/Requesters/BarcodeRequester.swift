//
//  BarcodeRequester.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/28/25.
//

import UIKit

struct BarcodeRequest {
    let image: UIImage
}

struct BarcodeRequester: OpenAIRequester {
    typealias RequestType = BarcodeRequest
    typealias ResponseType = ItemAnalysis

    let tokenCost = 1
    let model = "gpt-4o"
    let maxTokens = 300
    let temperature = 0.1
    let tokenManager: TokenManaging

    func buildRequestBody(_ request: BarcodeRequest) -> [String: Any] {
        let resizedImage = request.image.resize(maxDimension: 800)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            fatalError("Image processing failed")
        }

        let base64Image = imageData.base64EncodedString()

        let prompt = """
        Analyze this product image and identify the item. Focus on:
        
        1. VISUAL IDENTIFICATION (Primary):
        - Read all visible text, brand names, product names
        - Identify the product from packaging design and labels
        - Note product size, variant, edition information
        
        2. BARCODE READING (Secondary):
        - If you can see a barcode, try to read the numbers
        - Use barcode info to confirm product identification
        
        Provide JSON response:
        {
            "barcode_number": "barcode if visible, or 'not visible'",
            "barcode_format": "UPC-A/EAN-13/etc or 'unknown'",
            "item_name": "exact product name from packaging",
            "brand": "brand name from packaging",
            "category": "product category",
            "description": "product description based on visible features",
            "estimated_value": "estimated price range",
            "product_notes": "additional details about variant/size/etc"
        }
        
        Focus primarily on what you can read and see on the packaging, not just the barcode.
        """

        return [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)",
                            "detail": "high"
                        ]]
                    ]
                ]
            ],
            "max_tokens": maxTokens,
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
