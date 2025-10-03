import SwiftUI

// MARK: - eBay Trading API Listing Service (No Business Policies Required)
class eBayTradingListingService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var lastError: String?

    private let debugMode = true
    private let authService: eBayAuthService

    init(authService: eBayAuthService) {
        self.authService = authService
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
            print("Is Production: \(eBayConfig.isProduction)")
            print("===========================")
        }

        do {
            // Step 1: Get correct category ID from eBay
            await MainActor.run { uploadProgress = 0.2 }
            let categoryID = try await getSuggestedCategoryID(for: listing, accessToken: accessToken)

            // Step 2: Get required item specifics for this category
            await MainActor.run { uploadProgress = 0.3 }
            let itemSpecifics = try await getItemSpecifics(for: categoryID, listing: listing, accessToken: accessToken)

            // Step 3: Upload image and get URL
            await MainActor.run { uploadProgress = 0.5 }
            let imageURL = try await uploadImage(image: image, accessToken: accessToken)

            // Step 4: Create listing with correct category, specifics, and image
            await MainActor.run { uploadProgress = 0.7 }
            let itemID = try await createFixedPriceItem(listing: listing, categoryID: categoryID, itemSpecifics: itemSpecifics, imageURL: imageURL, accessToken: accessToken)

            await MainActor.run {
                uploadProgress = 1.0
                isUploading = false
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

    private func getItemSpecifics(for categoryID: String, listing: EbayListing, accessToken: String) async throws -> String {
        // For now, provide generic item specifics that work for most categories
        // You could enhance this by calling GetCategorySpecifics API to get required fields

        if debugMode {
            print("=== Building Item Specifics for Category \(categoryID) ===")
        }

        // Extract potential brand from title
        let brand = extractBrand(from: listing.title) ?? "Unbranded"

        // Build comprehensive item specifics that cover most common requirements
        return """
        <ItemSpecifics>
            <NameValueList>
                <Name>Brand</Name>
                <Value>\(escapeXML(brand))</Value>
            </NameValueList>
            <NameValueList>
                <Name>Type</Name>
                <Value>Not Specified</Value>
            </NameValueList>
            <NameValueList>
                <Name>Model</Name>
                <Value>Generic</Value>
            </NameValueList>
            <NameValueList>
                <Name>Color</Name>
                <Value>Multicolor</Value>
            </NameValueList>
            <NameValueList>
                <Name>Connectivity</Name>
                <Value>Wireless</Value>
            </NameValueList>
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

    private func createFixedPriceItem(listing: EbayListing, categoryID: String, itemSpecifics: String, imageURL: String, accessToken: String) async throws -> String {
        let url = URL(string: "\(eBayConfig.tradingAPIURL)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(eBayConfig.clientID, forHTTPHeaderField: "X-EBAY-API-APP-NAME")
        request.setValue(eBayConfig.devID, forHTTPHeaderField: "X-EBAY-API-DEV-NAME")
        request.setValue(eBayConfig.clientSecret, forHTTPHeaderField: "X-EBAY-API-CERT-NAME")
        request.setValue("AddFixedPriceItem", forHTTPHeaderField: "X-EBAY-API-CALL-NAME")
        request.setValue("0", forHTTPHeaderField: "X-EBAY-API-SITEID")
        request.setValue("1211", forHTTPHeaderField: "X-EBAY-API-COMPATIBILITY-LEVEL")

        let xmlBody = buildAddItemXML(listing: listing, categoryID: categoryID, itemSpecifics: itemSpecifics, imageURL: imageURL, token: accessToken)
        request.httpBody = xmlBody.data(using: .utf8)

        if debugMode {
            print("=== Creating Trading API Listing ===")
            print("URL: \(url)")
            print("=== XML Being Sent ===")
            print(xmlBody)
            print("======================")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw eBayError.networkError
        }

        if debugMode {
            print("Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        }

        guard httpResponse.statusCode == 200 else {
            throw eBayError.listingCreationFailed
        }

        // Parse XML response to get ItemID
        guard let responseString = String(data: data, encoding: .utf8),
              let itemID = parseItemIDFromResponse(responseString) else {
            throw eBayError.invalidResponse
        }

        // Check for errors in response
        if responseString.contains("<Ack>Failure</Ack>") || responseString.contains("<Ack>PartialFailure</Ack>") {
            if let errorMessage = parseErrorFromResponse(responseString) {
                print("eBay Error: \(errorMessage)")
            }
            throw eBayError.listingCreationFailed
        }

        return itemID
    }

    private func getSuggestedCategoryID(for listing: EbayListing, accessToken: String) async throws -> String {
        let url = URL(string: "\(eBayConfig.tradingAPIURL)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(eBayConfig.clientID, forHTTPHeaderField: "X-EBAY-API-APP-NAME")
        request.setValue(eBayConfig.devID, forHTTPHeaderField: "X-EBAY-API-DEV-NAME")
        request.setValue(eBayConfig.clientSecret, forHTTPHeaderField: "X-EBAY-API-CERT-NAME")
        request.setValue("GetSuggestedCategories", forHTTPHeaderField: "X-EBAY-API-CALL-NAME")
        request.setValue("0", forHTTPHeaderField: "X-EBAY-API-SITEID")
        request.setValue("1211", forHTTPHeaderField: "X-EBAY-API-COMPATIBILITY-LEVEL")

        let xmlBody = """
        <?xml version="1.0" encoding="utf-8"?>
        <GetSuggestedCategoriesRequest xmlns="urn:ebay:apis:eBLBaseComponents">
            <RequesterCredentials>
                <eBayAuthToken>\(accessToken)</eBayAuthToken>
            </RequesterCredentials>
            <Query>\(escapeXML(listing.title))</Query>
        </GetSuggestedCategoriesRequest>
        """

        request.httpBody = xmlBody.data(using: .utf8)

        if debugMode {
            print("=== Getting Suggested Category ===")
            print("Query: \(listing.title)")
            print("==================================")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if debugMode {
                if let httpResponse = response as? HTTPURLResponse {
                    print("Category API Status: \(httpResponse.statusCode)")
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Category API Response: \(responseString)")
                }
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("⚠️ Category API unavailable, using fallback")
                return getFallbackCategoryID(for: listing)
            }

            guard let responseString = String(data: data, encoding: .utf8) else {
                print("⚠️ Could not parse category response, using fallback")
                return getFallbackCategoryID(for: listing)
            }

            // Parse the category ID from response
            if let categoryID = parseCategoryIDFromResponse(responseString) {
                if debugMode {
                    print("✅ Suggested Category ID: \(categoryID)")
                }
                return categoryID
            }

            // No suggestion found, use fallback
            if debugMode {
                print("⚠️ No category suggestion, using fallback")
            }
            return getFallbackCategoryID(for: listing)

        } catch {
            print("⚠️ Category API error: \(error.localizedDescription), using fallback")
            return getFallbackCategoryID(for: listing)
        }
    }

    private func getFallbackCategoryID(for listing: EbayListing) -> String {
        // Use category name from your AI to make best guess
        let categoryName = listing.category.components(separatedBy: " > ").last?.lowercased() ?? ""

        if debugMode {
            print("Using fallback for category: \(categoryName)")
        }

        // Map to known working leaf categories
        if categoryName.contains("headphone") || categoryName.contains("audio") {
            return "112529" // Headphones
        } else if categoryName.contains("shoe") || categoryName.contains("footwear") {
            return "15709" // Athletic Shoes
        } else if categoryName.contains("electronic") || categoryName.contains("phone") {
            return "20349" // Cell Phone Cables & Adapters
        } else if categoryName.contains("clothing") || categoryName.contains("apparel") {
            return "15687" // Men's T-Shirts
        } else if categoryName.contains("book") {
            return "29223" // Fiction Books
        } else {
            return "20349" // Cell Phone Accessories as safe default
        }
    }

    private func parseCategoryIDFromResponse(_ xml: String) -> String? {
        // Parse the first suggested category ID
        let pattern = "<CategoryID>(\\d+)</CategoryID>"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
           let range = Range(match.range(at: 1), in: xml) {
            return String(xml[range])
        }
        return nil
    }

    private func uploadImage(image: UIImage, accessToken: String) async throws -> String {
        // Resize to smaller dimensions and compress more aggressively for eBay
        guard let resizedImage = image.resized(toMaxDimension: 1000),
              let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw eBayError.imageProcessingFailed
        }

        // eBay has a limit of around 7MB for base64 encoded images
        if imageData.count > 5_000_000 {
            print("⚠️ Image too large: \(imageData.count) bytes")
            throw eBayError.imageProcessingFailed
        }

        // Use multipart form data instead of base64 XML - more reliable
        let boundary = "----WebKitFormBoundary\(UUID().uuidString)"

        let url = URL(string: "\(eBayConfig.tradingAPIURL)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(eBayConfig.clientID, forHTTPHeaderField: "X-EBAY-API-APP-NAME")
        request.setValue(eBayConfig.devID, forHTTPHeaderField: "X-EBAY-API-DEV-NAME")
        request.setValue(eBayConfig.clientSecret, forHTTPHeaderField: "X-EBAY-API-CERT-NAME")
        request.setValue("UploadSiteHostedPictures", forHTTPHeaderField: "X-EBAY-API-CALL-NAME")
        request.setValue("0", forHTTPHeaderField: "X-EBAY-API-SITEID")
        request.setValue("1211", forHTTPHeaderField: "X-EBAY-API-COMPATIBILITY-LEVEL")

        var body = Data()

        // Add XML request part
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

        // Add image data part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"dummy\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        if debugMode {
            print("=== Uploading Image (Multipart) ===")
            print("Image size: \(imageData.count) bytes")
            print("Total payload: \(body.count) bytes")
            print("===================================")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if debugMode {
            if let httpResponse = response as? HTTPURLResponse {
                print("Image Upload Status: \(httpResponse.statusCode)")
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("Image Upload Response: \(responseString)")
            }
        }

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("❌ Image upload failed - HTTP status code issue")
            throw eBayError.imageUploadFailed
        }

        guard let responseString = String(data: data, encoding: .utf8) else {
            print("❌ Image upload failed - couldn't parse response")
            throw eBayError.imageUploadFailed
        }

        // Check for eBay API errors
        if responseString.contains("<Ack>Failure</Ack>") || responseString.contains("<Ack>PartialFailure</Ack>") {
            if let errorMessage = parseErrorFromResponse(responseString) {
                print("❌ eBay Image Upload Error: \(errorMessage)")
            }
            throw eBayError.imageUploadFailed
        }

        guard let imageURL = parseImageURLFromResponse(responseString) else {
            print("❌ Image upload failed - couldn't extract image URL from response")
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

    private func buildAddItemXML(listing: EbayListing, categoryID: String, itemSpecifics: String, imageURL: String, token: String) -> String {
        let condition = mapConditionToeBayCode(listing.condition)
        let shippingCost = String(format: "%.2f", listing.shippingCost)
        let price = String(format: "%.2f", listing.buyItNowPrice)

        return """
        <?xml version="1.0" encoding="utf-8"?>
        <AddFixedPriceItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
            <RequesterCredentials>
                <eBayAuthToken>\(token)</eBayAuthToken>
            </RequesterCredentials>
            <Item>
                <Title>\(escapeXML(listing.title))</Title>
                <Description>\(escapeXML(listing.description))</Description>
                <PrimaryCategory>
                    <CategoryID>\(categoryID)</CategoryID>
                </PrimaryCategory>
                <StartPrice>\(price)</StartPrice>
                <ConditionID>\(condition)</ConditionID>
                <CategoryMappingAllowed>true</CategoryMappingAllowed>
                <Country>US</Country>
                <Currency>USD</Currency>
                <DispatchTimeMax>3</DispatchTimeMax>
                <ListingDuration>GTC</ListingDuration>
                <ListingType>FixedPriceItem</ListingType>
                <PostalCode>66049</PostalCode>
                <Quantity>1</Quantity>
                \(itemSpecifics)
                <ReturnPolicy>
                    <ReturnsAcceptedOption>ReturnsAccepted</ReturnsAcceptedOption>
                    <RefundOption>MoneyBack</RefundOption>
                    <ReturnsWithinOption>Days_30</ReturnsWithinOption>
                    <ShippingCostPaidByOption>Buyer</ShippingCostPaidByOption>
                </ReturnPolicy>
                <ShippingDetails>
                    <ShippingType>Flat</ShippingType>
                    <ShippingServiceOptions>
                        <ShippingServicePriority>1</ShippingServicePriority>
                        <ShippingService>USPSFirstClass</ShippingService>
                        <ShippingServiceCost>\(shippingCost)</ShippingServiceCost>
                    </ShippingServiceOptions>
                </ShippingDetails>
                <Site>US</Site>
                <PictureDetails>
                    <PictureURL>\(escapeXML(imageURL))</PictureURL>
                </PictureDetails>
            </Item>
        </AddFixedPriceItemRequest>
        """
    }

    private func mapCategoryToeBayID(_ category: String) -> String {
        // Map your app's category names to eBay's leaf category IDs
        switch category.lowercased() {
        case "electronics":
            return "293"  // Cell Phones & Accessories
        case "clothing":
            return "11450"  // Clothing, Shoes & Accessories > Men's Clothing
        case "home":
            return "11700"  // Home & Garden > Home Décor
        case "toys":
            return "220"  // Toys & Hobbies
        case "books":
            return "377"  // Books, Movies & Music > Books & Magazines
        case "sports":
            return "382"  // Sporting Goods
        case "collectibles":
            return "1"  // Collectibles
        case "other":
            return "99"  // Everything Else > Other
        default:
            return "99"  // Everything Else > Other (catch-all)
        }
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
        // Order matters! & must be first to avoid double-escaping
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }

    private func parseItemIDFromResponse(_ xml: String) -> String? {
        let pattern = "<ItemID>(\\d+)</ItemID>"
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
}

// MARK: - UIImage Extension for Resizing
extension UIImage {
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage? {
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        if ratio >= 1 {
            return self // Image is already smaller than max dimension
        }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
