import Foundation
import SwiftUI
import UIKit

// MARK: - eBay Authentication Service
class eBayAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var currentEnvironment: String = eBayConfig.environmentName

    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "eBayAccessToken"
    private let tokenExpiryKey = "eBayTokenExpiry"
    private let authKey = "eBayAuthenticated"
    private let environmentKey = "eBayEnvironment"

    init() {
        loadStoredToken()
        currentEnvironment = eBayConfig.environmentName
    }

    func startAuthentication() {
        // Build OAuth URL with proper scopes
        let urlString = "\(eBayConfig.authURL)?client_id=\(eBayConfig.clientID)&response_type=code&redirect_uri=\(eBayConfig.redirectURI)&scope=\(eBayConfig.requiredScopes)"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    func exchangeCodeForToken(code: String) async {
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

    private func handleTokenResponse(data: Data?, response: URLResponse?, error: Error?) {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let expiresIn = json["expires_in"] as? Int else {
            print("eBay: Failed to get access token")
            if let data = data, let errorString = String(data: data, encoding: .utf8) {
                print("eBay: Error response: \(errorString)")
            }
            return
        }

        self.accessToken = accessToken
        self.isAuthenticated = true

        // Store token, expiry, and environment
        let expiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        userDefaults.set(accessToken, forKey: accessTokenKey)
        userDefaults.set(expiryDate, forKey: tokenExpiryKey)
        userDefaults.set(true, forKey: authKey)
        userDefaults.set(eBayConfig.environmentName, forKey: environmentKey)

        print("eBay: Successfully authenticated in \(eBayConfig.environmentName) environment!")
    }

    private func loadStoredToken() {
        // Check if stored token matches current environment
        let storedEnvironment = userDefaults.string(forKey: environmentKey)

        guard storedEnvironment == eBayConfig.environmentName,
              let token = userDefaults.string(forKey: accessTokenKey),
              let expiry = userDefaults.object(forKey: tokenExpiryKey) as? Date,
              expiry > Date() else {
            // Clear auth if environment changed or token expired
            signOut()
            return
        }

        accessToken = token
        isAuthenticated = true
    }

    func isTokenValid() -> Bool {
        guard let expiry = userDefaults.object(forKey: tokenExpiryKey) as? Date else {
            return false
        }
        return expiry > Date()
    }

    func signOut() {
        accessToken = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: tokenExpiryKey)
        userDefaults.removeObject(forKey: authKey)
        userDefaults.removeObject(forKey: environmentKey)
    }
}

// MARK: - eBay Listing Service
class eBayListingService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var lastError: String?

    private let debugMode = true
    private let authService: eBayAuthService

    init(authService: eBayAuthService) {
        self.authService = authService
    }

    func createListing(_ listing: EbayListing) async throws -> eBayListingResponse {
        guard authService.isAuthenticated,
              let accessToken = authService.accessToken else {
            throw eBayError.notAuthenticated
        }

        // Verify token is still valid
        if !authService.isTokenValid() {
            throw eBayError.tokenExpired
        }

        await MainActor.run {
            isUploading = true
            uploadProgress = 0.1
            lastError = nil
        }

        if debugMode {
            print("=== eBay API Debug ===")
            print("Environment: \(eBayConfig.environmentName)")
            print("Is Production: \(eBayConfig.isProduction)")
            print("Is authenticated: \(authService.isAuthenticated)")
            print("Access token: \(accessToken.prefix(20))...")
            print("======================")
        }

        do {
            // Create inventory item
            let sku = "quickflip-\(UUID().uuidString.prefix(8))"
            try await createInventoryItem(listing: listing, sku: sku, accessToken: accessToken)

            await MainActor.run {
                uploadProgress = 0.5
            }

            // Create offer for the inventory item
            try await createOffer(listing: listing, sku: sku, accessToken: accessToken)

            await MainActor.run {
                uploadProgress = 1.0
                isUploading = false
            }

            // Generate proper listing URL based on environment
            let listingURL = eBayConfig.isProduction
                ? "https://www.ebay.com/itm/\(sku)"
                : "https://www.sandbox.ebay.com/itm/\(sku)"

            return eBayListingResponse(
                listingID: sku,
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

    private func createInventoryItem(listing: EbayListing, sku: String, accessToken: String) async throws {
        let url = URL(string: "\(eBayConfig.baseAPIURL)/sell/inventory/v1/inventory_item/\(sku)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("en-US", forHTTPHeaderField: "Content-Language")

        let inventoryData: [String: Any] = [
            "product": [
                "title": listing.title,
                "description": listing.description,
                "aspects": [
                    "Brand": ["Generic"],
                    "Type": [listing.category]
                ]
            ],
            "condition": mapConditionToeBay(listing.condition),
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

        request.httpBody = try JSONSerialization.data(withJSONObject: inventoryData)

        if debugMode {
            print("=== Creating Inventory Item ===")
            print("URL: \(url)")
            print("SKU: \(sku)")
            print("================================")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if debugMode {
            if let httpResponse = response as? HTTPURLResponse {
                print("Inventory Item Status: \(httpResponse.statusCode)")
            }
            if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                print("Response: \(responseString)")
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw eBayError.networkError
        }

        // eBay returns 204 No Content on success
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("eBay Error: \(errorMessage)")
            throw eBayError.listingCreationFailed
        }
    }

    private func createOffer(listing: EbayListing, sku: String, accessToken: String) async throws {
        let url = URL(string: "\(eBayConfig.baseAPIURL)/sell/inventory/v1/offer")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("en-US", forHTTPHeaderField: "Content-Language")

        // Use appropriate marketplace ID
        let marketplaceId = eBayConfig.isProduction ? "EBAY_US" : "EBAY_US"

        let offerData: [String: Any] = [
            "sku": sku,
            "marketplaceId": marketplaceId,
            "format": "FIXED_PRICE",
            "listingDescription": listing.description,
            "availableQuantity": 1,
            "categoryId": "20081", // Generic category - you may want to make this dynamic
            "listingPolicies": [
                "paymentPolicyId": "PAYMENT_POLICY_ID", // You'll need to create these in eBay
                "returnPolicyId": "RETURN_POLICY_ID",
                "fulfillmentPolicyId": "FULFILLMENT_POLICY_ID"
            ],
            "pricingSummary": [
                "price": [
                    "value": String(format: "%.2f", listing.buyItNowPrice),
                    "currency": "USD"
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: offerData)

        if debugMode {
            print("=== Creating Offer ===")
            print("URL: \(url)")
            print("======================")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if debugMode {
            if let httpResponse = response as? HTTPURLResponse {
                print("Offer Status: \(httpResponse.statusCode)")
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw eBayError.networkError
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("eBay Offer Error: \(errorMessage)")
            throw eBayError.listingCreationFailed
        }
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
    case tokenExpired
    case imageProcessingFailed
    case imageUploadFailed
    case listingCreationFailed
    case networkError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to eBay first"
        case .tokenExpired:
            return "Your eBay session has expired. Please sign in again"
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
