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
        You are a barcode reading and product identification expert. Analyze this image containing a barcode and provide detailed product information.

        INSTRUCTIONS:
        1. First, carefully examine the image to locate and read any visible barcodes (UPC, EAN, ISBN, etc.)
        2. Extract the complete barcode number
        3. Use your knowledge to identify the exact product associated with this barcode
        4. Provide comprehensive product details for resale purposes

        BARCODE ANALYSIS FOCUS:
        - Read the numeric code clearly and completely
        - Identify the barcode format (UPC-A, EAN-13, ISBN, etc.)
        - Match the barcode to the specific product variant (size, color, edition, etc.)
        - If multiple barcodes are visible, focus on the main product barcode

        PRODUCT IDENTIFICATION:
        - Provide the exact product name including brand, model, and specifications
        - Include product category and subcategory
        - Note any important variants (size, color, edition, version)
        - Estimate current market value based on product knowledge

        RESPONSE FORMAT (JSON):
        {
            "barcode_number": "the complete barcode number",
            "barcode_format": "UPC-A/EAN-13/ISBN/etc",
            "item_name": "exact product name with brand and model",
            "brand": "manufacturer/brand name",
            "category": "product category",
            "description": "detailed product description including key features and specifications",
            "estimated_value": "current market price range like $X-$Y",
            "product_notes": "any important details about variants, editions, or product specifics"
        }

        IMPORTANT GUIDELINES:
        - Be precise with barcode number reading - accuracy is critical
        - Focus on exact product identification rather than condition assessment
        - Provide realistic market value estimates based on current resale markets
        - If barcode is unclear or unreadable, indicate this in the response
        - Include all relevant product details that would help with resale listing

        ERROR HANDLING:
        - If no barcode is visible: Return error indicating "No barcode found in image"
        - If barcode is damaged/unreadable: Return error indicating "Barcode not readable - try better lighting or angle"
        - If product cannot be identified: Return basic barcode info with note "Product not found in database"
        """

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
                            "detail": "low"
                        ]
                    ]
                ]
            ]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-4",
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
