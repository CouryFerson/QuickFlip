import Foundation
import SwiftUI
import UIKit

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
        let urlString = "https://auth.sandbox.ebay.com/oauth2/authorize?client_id=\(eBayConfig.clientID)&response_type=code&redirect_uri=\(eBayConfig.redirectURI)&scope=https://api.ebay.com/oauth/api_scope/sell.inventory"

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
    private let debugMode = true
    private let authService: eBayAuthService

    init(authService: eBayAuthService) {
        self.authService = authService
    }

    func createListing(_ listing: EbayListing) async throws -> eBayListingResponse {
        // Get token from the passed auth service
        guard authService.isAuthenticated,
              let accessToken = authService.accessToken else {
            throw eBayError.notAuthenticated
        }

        // Check token validity if your auth service has this method
        // if !authService.isTokenValid() {
        //     throw eBayError.tokenExpired
        // }

        await MainActor.run {
            isUploading = true
            uploadProgress = 0.1
            lastError = nil
        }

        if debugMode {
            print("=== Token Debug ===")
            print("Is authenticated: \(authService.isAuthenticated)")
            print("Access token: \(accessToken.prefix(20))...")
            print("Full token: \(accessToken)")
            print("==================")
        }

        do {
            // Create inventory item
            let sku = "quickflip-\(UUID().uuidString.prefix(8))"
            try await createInventoryItem(listing: listing, sku: sku, accessToken: accessToken)

            await MainActor.run {
                uploadProgress = 1.0
                isUploading = false
            }

            return eBayListingResponse(
                listingID: sku,
                listingURL: "https://www.sandbox.ebay.com/itm/\(sku)",
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

        // CRITICAL: Make sure Bearer token format is correct
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
            print("=== Final API Request Debug ===")
            print("URL: \(url)")
            print("Method: \(request.httpMethod ?? "")")
            print("Authorization Header: \(request.value(forHTTPHeaderField: "Authorization") ?? "Missing!")")
            print("================================")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if debugMode {
            print("=== eBay API Response ===")
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body: \(responseString)")
            }
            print("========================")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw eBayError.networkError
        }


        if httpResponse.statusCode == 204 {
            // Success - eBay returns 204 with empty body for successful creation
            return
        }

        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 && httpResponse.statusCode != 204 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
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
