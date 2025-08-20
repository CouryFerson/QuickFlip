import Foundation
import UIKit

class BarcodeAnalysisService {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func analyzeBarcodeImage(_ image: UIImage) async throws -> ItemAnalysis {
        let resizedImage = image.resize(maxDimension: 800)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw BarcodeAnalysisError.invalidImage
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
        
        Focus primarily on what you can READ and see on the packaging, not just the barcode.
        """

        // Send IMAGE back to AI (your original working approach)
        let messages: [[String: Any]] = [
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
                            "url": "data:image/jpeg;base64,\(base64Image)",
                            "detail": "high"
                        ]
                    ]
                ]
            ]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 300,
            "temperature": 0.1 // Lower temperature for more accurate barcode reading
        ]

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw BarcodeAnalysisError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        print("QuickFlip: Raw API response data received")
        if let responseString = String(data: data, encoding: .utf8) {
            print("QuickFlip: Raw response: \(responseString)")
        } else {
            print("QuickFlip: Could not convert response to string")
        }

        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = response.choices.first?.message.content else {
            throw BarcodeAnalysisError.noResponse
        }

        return try parseBarcodeAnalysis(from: content)
    }

    private func parseBarcodeAnalysis(from content: String) throws -> ItemAnalysis {
        // Extract JSON from the response
        let jsonStartIndex = content.firstIndex(of: "{") ?? content.startIndex
        let jsonEndIndex = content.lastIndex(of: "}") ?? content.endIndex
        let jsonString = String(content[jsonStartIndex...jsonEndIndex])

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw BarcodeAnalysisError.invalidResponse
        }

        do {
            let barcodeResult = try JSONDecoder().decode(BarcodeAnalysisResult.self, from: jsonData)

            // Convert to ItemAnalysis format
            return ItemAnalysis(
                itemName: barcodeResult.item_name,
                condition: "Unknown", // Skip condition for barcode flow
                description: barcodeResult.description,
                estimatedValue: barcodeResult.estimated_value,
                category: barcodeResult.category
            )

        } catch {
            // Fallback parsing if JSON structure is different
            throw BarcodeAnalysisError.parsingFailed
        }
    }
}

// MARK: - Error Types
enum BarcodeAnalysisError: Error {
    case invalidImage
    case invalidURL
    case noResponse
    case invalidResponse
    case parsingFailed

    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .invalidURL:
            return "Invalid API URL"
        case .noResponse:
            return "No response from analysis service"
        case .invalidResponse:
            return "Invalid response format"
        case .parsingFailed:
            return "Failed to parse analysis results"
        }
    }
}

// MARK: - Barcode Analysis Result Structure
struct BarcodeAnalysisResult: Codable {
    let barcode_number: String
    let barcode_format: String
    let item_name: String
    let brand: String
    let category: String
    let description: String
    let estimated_value: String
    let product_notes: String?
}
