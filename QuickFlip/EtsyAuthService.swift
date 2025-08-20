//
//  EtsyAuthService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/19/25.
//

import Foundation
import UIKit

// MARK: - Etsy Configuration
struct EtsyConfig {
    static let clientID = "YOUR_ETSY_API_KEY" // Get from Etsy Developer account
    static let clientSecret = "YOUR_ETSY_SHARED_SECRET"
    static let redirectURI = "quickflip://etsy/auth" // Or leave blank for manual

    // Etsy API URLs
    static let authURL = "https://www.etsy.com/oauth/connect"
    static let tokenURL = "https://openapi.etsy.com/v3/public/oauth/token"
    static let baseAPIURL = "https://openapi.etsy.com/v3/application"
}

// MARK: - Etsy Authentication Service
class EtsyAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var shopID: String?

    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "EtsyAccessToken"
    private let shopIDKey = "EtsyShopID"
    private let tokenExpiryKey = "EtsyTokenExpiry"

    init() {
        loadStoredToken()
    }

    func startAuthentication() {
        let state = UUID().uuidString
        let scope = "listings_w shops_r profile_r"

        var components = URLComponents(string: EtsyConfig.authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: EtsyConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: EtsyConfig.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: scope)
        ]

        if let url = components.url {
            print("=== Etsy OAuth Debug ===")
            print("Auth URL: \(url)")
            print("======================")
            UIApplication.shared.open(url)
        }
    }

    func exchangeCodeForToken(code: String) async {
        await exchangeCodeForTokenInternal(code: code)
    }

    private func exchangeCodeForTokenInternal(code: String) async {
        let tokenURL = URL(string: EtsyConfig.tokenURL)!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Create authorization header
        let credentials = "\(EtsyConfig.clientID):\(EtsyConfig.clientSecret)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        let bodyParameters = [
            "grant_type": "authorization_code",
            "client_id": EtsyConfig.clientID,
            "code": code,
            "redirect_uri": EtsyConfig.redirectURI
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
                print("Etsy: Token exchange error: \(error)")
            }
        }
    }

    private func handleTokenResponse(data: Data?, response: URLResponse?, error: Error?) {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            print("Etsy: Failed to get access token")
            return
        }

        self.accessToken = accessToken

        // Store token
        userDefaults.set(accessToken, forKey: accessTokenKey)

        // Get shop information
        Task {
            await fetchShopInfo()
        }

        print("Etsy: Successfully authenticated!")
    }

    private func fetchShopInfo() async {
        guard let accessToken = accessToken else { return }

        let url = URL(string: "\(EtsyConfig.baseAPIURL)/users/__SELF__/shops")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(EtsyConfig.clientID, forHTTPHeaderField: "x-api-key")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let firstShop = results.first,
               let shopID = firstShop["shop_id"] as? Int {

                await MainActor.run {
                    self.shopID = String(shopID)
                    self.isAuthenticated = true
                    self.userDefaults.set(String(shopID), forKey: self.shopIDKey)
                }

                print("Etsy: Found shop ID: \(shopID)")
            }
        } catch {
            print("Etsy: Failed to fetch shop info: \(error)")
        }
    }

    private func loadStoredToken() {
        guard let token = userDefaults.string(forKey: accessTokenKey),
              let shopID = userDefaults.string(forKey: shopIDKey) else {
            return
        }

        self.accessToken = token
        self.shopID = shopID
        self.isAuthenticated = true
    }

    func signOut() {
        accessToken = nil
        shopID = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: accessTokenKey)
        userDefaults.removeObject(forKey: shopIDKey)
        userDefaults.removeObject(forKey: tokenExpiryKey)
    }
}

// MARK: - Etsy Listing Service
class EtsyListingService: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var lastError: String?

    private let authService: EtsyAuthService

    init(authService: EtsyAuthService) {
        self.authService = authService
    }

    func createListing(_ listing: EtsyListing) async throws -> EtsyListingResponse {
        guard let accessToken = authService.accessToken,
              let shopID = authService.shopID else {
            throw EtsyError.notAuthenticated
        }

        await MainActor.run {
            isUploading = true
            uploadProgress = 0.1
        }

        // Step 1: Upload images
        let imageURLs = try await uploadImages(listing.photos, accessToken: accessToken)

        await MainActor.run {
            uploadProgress = 0.5
        }

        // Step 2: Create listing
        let listingResponse = try await createEtsyListing(listing, imageURLs: imageURLs, shopID: shopID, accessToken: accessToken)

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
        // For now, return a placeholder - Etsy image upload is complex
        // In production, you'd use Etsy's image upload endpoint
        return "placeholder_image_id"
    }

    private func createEtsyListing(_ listing: EtsyListing, imageURLs: [String], shopID: String, accessToken: String) async throws -> EtsyListingResponse {
        let url = URL(string: "\(EtsyConfig.baseAPIURL)/shops/\(shopID)/listings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(EtsyConfig.clientID, forHTTPHeaderField: "x-api-key")

        // Prepare tags array
        let tagsArray = listing.tags.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(13) // Etsy allows max 13 tags

        let listingData: [String: Any] = [
            "title": listing.title,
            "description": listing.description,
            "price": listing.price,
            "who_made": "i_did", // Required for handmade
            "when_made": "2020_2024", // Required
            "taxonomy_id": getTaxonomyID(for: listing.category),
            "tags": Array(tagsArray),
            "materials": ["handmade"], // Required materials
            "shop_section_id": "nil", // Optional shop section
            "processing_min": 1, // Processing time
            "processing_max": 3,
            "quantity": 1
        ]

        // DEBUG: Log the request
        print("=== Etsy API Debug ===")
        print("URL: \(url)")
        print("Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: listingData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Request Body:")
            print(jsonString)
        }
        print("==================")

        request.httpBody = try JSONSerialization.data(withJSONObject: listingData)

        let (data, response) = try await URLSession.shared.data(for: request)

        // DEBUG: Log response
        print("=== Etsy API Response ===")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Body:")
            print(responseString)
        }
        print("========================")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EtsyError.networkError
        }

        if httpResponse.statusCode != 200 && httpResponse.statusCode != 201 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Etsy API Error: \(errorData)")
            }
            throw EtsyError.listingCreationFailed
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let listingID = json["listing_id"] as? Int else {
            throw EtsyError.invalidResponse
        }

        return EtsyListingResponse(
            listingID: String(listingID),
            listingURL: "https://www.etsy.com/listing/\(listingID)",
            status: "Active"
        )
    }

    private func getTaxonomyID(for category: String) -> Int {
        // Etsy requires taxonomy IDs for categories
        // These are some common ones - you'd need to fetch the full taxonomy
        switch category.lowercased() {
        case "handmade":
            return 69150467 // Craft Supplies & Tools
        case "vintage":
            return 69150425 // Vintage items
        case "art":
            return 69150467 // Art & Collectibles
        case "home_living":
            return 69150467 // Home & Living
        case "craft_supplies":
            return 69150467 // Craft Supplies
        default:
            return 69150467 // Default to Craft Supplies
        }
    }
}

// MARK: - Models
struct EtsyListing {
    var title: String
    var description: String
    var price: Double
    var category: String
    var tags: String
    var photos: [UIImage]

    // Convenience initializer from ItemAnalysis
    init(from itemAnalysis: ItemAnalysis, image: UIImage) {
        self.title = itemAnalysis.itemName
        self.description = itemAnalysis.description
        self.price = EtsyListing.extractPrice(from: itemAnalysis.estimatedValue)
        self.category = itemAnalysis.category.lowercased().contains("vintage") ? "vintage" : "handmade"
        self.tags = EtsyListing.generateTags(from: itemAnalysis)
        self.photos = [image]
    }

    private static func extractPrice(from value: String) -> Double {
        let numbers = value.replacingOccurrences(of: "$", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-–"))
        let price = Double(numbers.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "25") ?? 25.0
        return max(price, 1.0) // Etsy minimum is $0.20, but let's be safe
    }

    private static func generateTags(from analysis: ItemAnalysis) -> String {
        var tags: [String] = []

        // Add category-based tags
        if analysis.category.lowercased().contains("vintage") {
            tags.append("vintage")
        }
        tags.append("handmade")
        tags.append("unique")

        // Add item-specific tags based on name
        let itemWords = analysis.itemName.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 }
            .prefix(5)

        tags.append(contentsOf: itemWords)

        // Remove duplicates and limit to 10 tags
        let uniqueTags = Array(Set(tags)).prefix(10)
        return uniqueTags.joined(separator: ", ")
    }
}

struct EtsyListingResponse {
    let listingID: String
    let listingURL: String
    let status: String
}

enum EtsyError: Error, LocalizedError {
    case notAuthenticated
    case imageProcessingFailed
    case imageUploadFailed
    case listingCreationFailed
    case networkError
    case invalidResponse
    case noShopFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to Etsy first"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .imageUploadFailed:
            return "Failed to upload image to Etsy"
        case .listingCreationFailed:
            return "Failed to create Etsy listing"
        case .networkError:
            return "Network connection error"
        case .invalidResponse:
            return "Invalid response from Etsy"
        case .noShopFound:
            return "No Etsy shop found. Please create a shop first."
        }
    }
}
