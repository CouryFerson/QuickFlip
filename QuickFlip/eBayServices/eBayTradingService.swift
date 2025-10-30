//
//  eBayTradingListingService.swift
//  QuickFlip
//
//  Updated to use Supabase Edge Functions
//

import SwiftUI

// MARK: - eBay Trading API Listing Service
class eBayTradingListingService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var lastError: String?

    private let debugMode = true
    private let authService: eBayAuthService
    private let supabaseService: SupabaseService

    init(authService: eBayAuthService, supabaseService: SupabaseService) {
        self.authService = authService
        self.supabaseService = supabaseService
    }

    func createListing(_ listing: EbayListing, image: UIImage) async throws -> eBayListingResponse {
        guard authService.isAuthenticated,
              let accessToken = authService.accessToken else {
            throw eBayError.notAuthenticated
        }

        if !authService.isTokenValid() {
            throw eBayError.tokenExpired
        }

        await MainActor.run {
            isUploading = true
            uploadProgress = 0.1
            lastError = nil
        }

        if debugMode {
            print("=== Trading API Listing ===")
            print("Environment: \(eBayConfig.environmentName)")
            print("===========================")
        }

        do {
            // Step 1: Get correct category ID
            await MainActor.run { uploadProgress = 0.2 }
            let categoryID = getFallbackCategoryID(for: listing)

            // Step 2: Get item specifics
            await MainActor.run { uploadProgress = 0.3 }
            let itemSpecifics = getItemSpecifics(for: categoryID, listing: listing)

            // Step 3: Upload image (still done locally for now - would need separate Edge Function)
            await MainActor.run { uploadProgress = 0.5 }
            let imageURL = try await uploadImage(image: image, accessToken: accessToken)

            // Step 4: Create listing via Edge Function
            await MainActor.run { uploadProgress = 0.7 }
            let conditionID = mapConditionToeBayCode(listing.condition)
            let price = String(format: "%.2f", listing.buyItNowPrice)
            let shippingCost = String(format: "%.2f", listing.shippingCost)

            let response = try await supabaseService.createeBayListing(
                userToken: accessToken,
                title: listing.title,
                description: listing.description,
                categoryID: categoryID,
                price: price,
                conditionID: conditionID,
                itemSpecifics: itemSpecifics,
                imageURL: imageURL,
                shippingCost: shippingCost,
                isProduction: eBayConfig.isProduction
            )

            await MainActor.run {
                uploadProgress = 1.0
                isUploading = false
            }

            guard let itemID = response.itemID, response.success else {
                throw eBayError.listingCreationFailed
            }

            let listingURL = eBayConfig.isProduction
                ? "https://www.ebay.com/itm/\(itemID)"
                : "https://www.sandbox.ebay.com/itm/\(itemID)"

            return eBayListingResponse(
                listingID: itemID,
                listingURL: listingURL,
                status: "Active"
            )

        } catch {
            await MainActor.run {
                uploadProgress = 0.0
                isUploading = false
            }
            throw error
        }
    }

    private func getItemSpecifics(for categoryID: String, listing: EbayListing) -> String {
        if debugMode {
            print("=== Building Item Specifics for Category \(categoryID) ===")
        }

        // Use AI-extracted attributes if available, otherwise fall back to basic extraction
        guard let itemSpecifics = listing.itemSpecifics, !itemSpecifics.isEmpty else {
            // Fallback: basic brand extraction for legacy items without AI attributes
            let brand = extractBrand(from: listing.title) ?? "Unbranded"
            return """
            <ItemSpecifics>
                <NameValueList>
                    <Name>Brand</Name>
                    <Value>\(escapeXML(brand))</Value>
                </NameValueList>
            </ItemSpecifics>
            """
        }

        // Build XML from AI-extracted attributes
        var nameValueLists = ""
        for (name, value) in itemSpecifics.sorted(by: { $0.key < $1.key }) {
            // Skip empty or "Unknown"/"Not Specified" values to keep listing clean
            guard !value.isEmpty && value != "Unknown" && value != "Not Specified" else {
                continue
            }

            nameValueLists += """
                <NameValueList>
                    <Name>\(escapeXML(name))</Name>
                    <Value>\(escapeXML(value))</Value>
                </NameValueList>

            """
        }

        if debugMode {
            print("Generated \(itemSpecifics.count) item specifics from AI data")
        }

        return """
        <ItemSpecifics>
        \(nameValueLists.trimmingCharacters(in: .whitespacesAndNewlines))
        </ItemSpecifics>
        """
    }

    private func extractBrand(from text: String) -> String? {
        let commonBrands = [
            "apple", "samsung", "sony", "bose", "beats", "jbl", "anker", "airpods",
            "nike", "adidas", "puma", "reebok", "vans", "converse",
            "microsoft", "dell", "hp", "lenovo", "asus",
            "canon", "nikon", "gopro", "dji"
        ]

        let lowercased = text.lowercased()
        for brand in commonBrands {
            if lowercased.contains(brand) {
                return brand.capitalized
            }
        }
        return nil
    }

    private func getFallbackCategoryID(for listing: EbayListing) -> String {
        let categoryName = listing.category.components(separatedBy: " > ").last?.lowercased() ?? ""

        if debugMode {
            print("Using fallback for category: \(categoryName)")
        }

        if categoryName.contains("headphone") || categoryName.contains("audio") {
            return "112529"
        } else if categoryName.contains("shoe") || categoryName.contains("footwear") {
            return "15709"
        } else if categoryName.contains("electronic") || categoryName.contains("phone") {
            return "20349"
        } else if categoryName.contains("clothing") || categoryName.contains("apparel") {
            return "15687"
        } else if categoryName.contains("book") {
            return "29223"
        } else {
            return "20349"
        }
    }

    private func uploadImage(image: UIImage, accessToken: String) async throws -> String {
        // Image upload still uses Trading API directly with user's OAuth token
        // This doesn't expose clientSecret/devID since it uses the user's token
        guard let resizedImage = image.resized(toMaxDimension: 1000),
              let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw eBayError.imageProcessingFailed
        }

        if imageData.count > 5_000_000 {
            print("⚠️ Image too large: \(imageData.count) bytes")
            throw eBayError.imageProcessingFailed
        }

        let boundary = "----WebKitFormBoundary\(UUID().uuidString)"
        let tradingURL = eBayConfig.isProduction
            ? "https://api.ebay.com/ws/api.dll"
            : "https://api.sandbox.ebay.com/ws/api.dll"

        guard let url = URL(string: tradingURL) else {
            throw eBayError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(eBayConfig.clientID, forHTTPHeaderField: "X-EBAY-API-APP-NAME")
        request.setValue("UploadSiteHostedPictures", forHTTPHeaderField: "X-EBAY-API-CALL-NAME")
        request.setValue("0", forHTTPHeaderField: "X-EBAY-API-SITEID")
        request.setValue("1211", forHTTPHeaderField: "X-EBAY-API-COMPATIBILITY-LEVEL")

        var body = Data()

        let xmlPart = """
        <?xml version="1.0" encoding="utf-8"?>
        <UploadSiteHostedPicturesRequest xmlns="urn:ebay:apis:eBLBaseComponents">
            <RequesterCredentials>
                <eBayAuthToken>\(accessToken)</eBayAuthToken>
            </RequesterCredentials>
            <PictureName>listing.jpg</PictureName>
        </UploadSiteHostedPicturesRequest>
        """

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"XML Payload\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/xml\r\n\r\n".data(using: .utf8)!)
        body.append(xmlPart.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"dummy\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        if debugMode {
            print("=== Uploading Image ===")
            print("Image size: \(imageData.count) bytes")
            print("=======================")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("❌ Image upload failed")
            throw eBayError.imageUploadFailed
        }

        guard let responseString = String(data: data, encoding: .utf8) else {
            throw eBayError.imageUploadFailed
        }

        if responseString.contains("<Ack>Failure</Ack>") || responseString.contains("<Ack>PartialFailure</Ack>") {
            if let errorMessage = parseErrorFromResponse(responseString) {
                print("❌ eBay Image Upload Error: \(errorMessage)")
            }
            throw eBayError.imageUploadFailed
        }

        guard let imageURL = parseImageURLFromResponse(responseString) else {
            throw eBayError.imageUploadFailed
        }

        if debugMode {
            print("✅ Image uploaded: \(imageURL)")
        }

        return imageURL
    }

    private func parseImageURLFromResponse(_ xml: String) -> String? {
        let pattern = "<FullURL>(.*?)</FullURL>"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
           let range = Range(match.range(at: 1), in: xml) {
            return String(xml[range])
        }
        return nil
    }

    private func parseErrorFromResponse(_ xml: String) -> String? {
        let pattern = "<LongMessage>(.*?)</LongMessage>"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
           let range = Range(match.range(at: 1), in: xml) {
            return String(xml[range])
        }
        return nil
    }

    private func mapConditionToeBayCode(_ condition: String) -> String {
        switch condition.lowercased() {
        case "new":
            return "1000"
        case "like new":
            return "1500"
        case "good":
            return "3000"
        case "fair":
            return "4000"
        case "poor":
            return "5000"
        default:
            return "3000"
        }
    }

    private func escapeXML(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage? {
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        if ratio >= 1 {
            return self
        }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
