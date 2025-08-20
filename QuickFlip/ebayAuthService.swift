import Foundation
import UIKit

// MARK: - eBay Configuration
struct eBayConfig {
    static let clientID = "CouryFer-QuickFli-SBX-bbc0e4d93-f7df68a1"
    static let clientSecret = "SBX-bc0e4d937996-723d-4fe4-86b6-d7bb"
    static let devID = "db79ecc5-88e5-4d24-8e1b-44fcf38d3990"
    static let redirectURI = "Coury_Ferson-CouryFer-QuickF-kbvwx" // Keep what eBay expects

    // Sandbox URLs
    static let authURL = "https://auth.sandbox.ebay.com/oauth2/authorize"
    static let tokenURL = "https://api.sandbox.ebay.com/identity/v1/oauth2/token"
    static let baseAPIURL = "https://api.sandbox.ebay.com"
}

// MARK: - eBay Authentication Service
class eBayAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var accessToken: String?

    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "eBayAccessToken"
    private let tokenExpiryKey = "eBayTokenExpiry"
    private let authKey = "eBayAuthenticated"

    init() {
        isAuthenticated = userDefaults.bool(forKey: authKey)

//        loadStoredToken()
    }

    func markAsAuthenticated() {
        isAuthenticated = true
        // Use a placeholder token for now
        accessToken = "sandbox_authenticated_user"
        userDefaults.set(true, forKey: authKey)
    }

    func signOut() {
        isAuthenticated = false
        accessToken = nil
        userDefaults.removeObject(forKey: authKey)
    }

    func startAuthentication() {
        // Use your known working eBay URL
        let urlString = "https://auth.sandbox.ebay.com/oauth2/authorize?client_id=CouryFer-QuickFli-SBX-bbc0e4d93-f7df68a1&response_type=code&redirect_uri=Coury_Ferson-CouryFer-QuickF-kbvwx&scope=https://api.ebay.com/oauth/api_scope/sell.inventory"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    func exchangeCodeForToken(code: String) async {
        await MainActor.run {
            // Show loading state while exchanging
        }

        await exchangeCodeForTokenInternal(code: code)
    }

    private func exchangeCodeForTokenInternal(code: String) async {
        let tokenURL = URL(string: eBayConfig.tokenURL)!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Create authorization header
        let credentials = "\(eBayConfig.clientID):\(eBayConfig.clientSecret)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        let bodyParameters = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": eBayConfig.redirectURI
        ]

        let bodyString = bodyParameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            await MainActor.run {
                self.handleTokenResponse(data: data, response: response, error: nil)
            }
        } catch {
            await MainActor.run {
                print("eBay: Token exchange error: \(error)")
            }
        }
    }

    private func exchangeCodeForToken(code: String) {
        let tokenURL = URL(string: eBayConfig.tokenURL)!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Create authorization header
        let credentials = "\(eBayConfig.clientID):\(eBayConfig.clientSecret)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        let bodyParameters = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": eBayConfig.redirectURI
        ]

        let bodyString = bodyParameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleTokenResponse(data: data, response: response, error: error)
            }
        }.resume()
    }

    private func handleTokenResponse(data: Data?, response: URLResponse?, error: Error?) {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let expiresIn = json["expires_in"] as? Int else {
            print("eBay: Failed to get access token")
            return
        }

        self.accessToken = accessToken
        self.isAuthenticated = true

        // Store token and expiry
        userDefaults.set(accessToken, forKey: accessTokenKey)
        userDefaults.set(Date().addingTimeInterval(TimeInterval(expiresIn)), forKey: tokenExpiryKey)

        print("eBay: Successfully authenticated!")
    }

    private func loadStoredToken() {
        guard let token = userDefaults.string(forKey: accessTokenKey),
              let expiry = userDefaults.object(forKey: tokenExpiryKey) as? Date,
              expiry > Date() else {
            return
        }

        accessToken = token
        isAuthenticated = true
    }

//    func signOut() {
//        accessToken = nil
//        isAuthenticated = false
//        userDefaults.removeObject(forKey: accessTokenKey)
//        userDefaults.removeObject(forKey: tokenExpiryKey)
//    }
}

// MARK: - eBay Listing Service
class eBayListingService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var lastError: String?

    private let authService: eBayAuthService

    init(authService: eBayAuthService) {
        self.authService = authService
    }

    func createListing(_ listing: EbayListing) async throws -> eBayListingResponse {
        // For V1 sandbox - create a dummy token or skip token validation
        let accessToken = "sandbox_bypass_token"

        await MainActor.run {
            isUploading = true
            uploadProgress = 0.1
        }

        // Skip image upload for now, test with empty array
        let imageURLs: [String] = []

        await MainActor.run {
            uploadProgress = 0.5
        }

        // Test listing creation
        let listingResponse = try await createeBayListing(listing, imageURLs: imageURLs, accessToken: accessToken)

        await MainActor.run {
            uploadProgress = 1.0
            isUploading = false
        }

        return listingResponse
    }

    private func uploadImages(_ images: [UIImage], accessToken: String) async throws -> [String] {
        var imageURLs: [String] = []

        for (index, image) in images.enumerated() {
            let imageURL = try await uploadSingleImage(image, accessToken: accessToken)
            imageURLs.append(imageURL)

            await MainActor.run {
                uploadProgress = 0.1 + (Double(index + 1) / Double(images.count)) * 0.4
            }
        }

        return imageURLs
    }

    private func uploadSingleImage(_ image: UIImage, accessToken: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw eBayError.imageProcessingFailed
        }

        let url = URL(string: "\(eBayConfig.baseAPIURL)/sell/inventory/v1/bulk_upload_file")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fileId = json["fileId"] as? String else {
            throw eBayError.imageUploadFailed
        }

        return fileId
    }

    private func createeBayListing(_ listing: EbayListing, imageURLs: [String], accessToken: String) async throws -> eBayListingResponse {
        let sku = "quickflip-\(UUID().uuidString.prefix(8))"

        // IMPORTANT: URL includes the SKU in the path
        let url = URL(string: "\(eBayConfig.baseAPIURL)/sell/inventory/v1/inventory_item/\(sku)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT" // Changed from POST to PUT
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Corrected request body with required fields
        let listingData: [String: Any] = [
            "product": [
                "title": listing.title,
                "description": listing.description,
                "aspects": [
                    "Brand": ["Apple"],
                    "Model": ["Siri Remote"],
                    "Type": ["Remote Control"]
                ]
            ],
            "condition": "USED_EXCELLENT",
            "packageWeightAndSize": [
                "dimensions": [
                    "height": 2,
                    "length": 5,
                    "width": 1,
                    "unit": "INCH"
                ],
                "packageType": "MAILING_BOX",
                "weight": [
                    "value": 0.5,
                    "unit": "POUND"
                ]
            ],
            "availability": [
                "shipToLocationAvailability": [
                    "quantity": 1
                ]
            ]
        ]

        print("=== eBay API Debug (CORRECTED) ===")
        print("URL: \(url)")
        print("Method: \(request.httpMethod ?? "nil")")

        if let jsonData = try? JSONSerialization.data(withJSONObject: listingData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Request Body:")
            print(jsonString)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: listingData)

        let (data, response) = try await URLSession.shared.data(for: request)

        print("=== eBay API Response ===")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Body:")
            print(responseString)
        }
        print("========================")

        // Return mock success for now
        return eBayListingResponse(
            listingID: sku,
            listingURL: "https://www.sandbox.ebay.com/itm/\(sku)",
            status: "Active"
        )
    }

    private func mapConditionToeBay(_ condition: String) -> String {
        switch condition.lowercased() {
        case "new":
            return "NEW"
        case "like new":
            return "NEW_OTHER"
        case "good":
            return "USED_EXCELLENT"
        case "fair":
            return "USED_GOOD"
        case "poor":
            return "USED_ACCEPTABLE"
        default:
            return "USED_GOOD"
        }
    }
}

// MARK: - Models
struct eBayListingResponse {
    let listingID: String
    let listingURL: String
    let status: String
}

enum eBayError: Error, LocalizedError {
    case notAuthenticated
    case imageProcessingFailed
    case imageUploadFailed
    case listingCreationFailed
    case networkError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to eBay first"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .imageUploadFailed:
            return "Failed to upload image to eBay"
        case .listingCreationFailed:
            return "Failed to create eBay listing"
        case .networkError:
            return "Network connection error"
        case .invalidResponse:
            return "Invalid response from eBay"
        }
    }
}
