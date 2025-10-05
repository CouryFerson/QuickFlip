////
////  eBayResponseModels.swift
////  QuickFlip
////
////  Created by Ferson, Coury on 10/5/25.
//
//import Foundation
//import Supabase
//
//// MARK: - Response Models
//
struct eBayTokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String?
    let token_type: String
}

struct eBayAppTokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}

struct eBayBrowseSearchResponse: Codable {
    let itemSummaries: [BrowseItemSummary]?
    let total: Int?
}

struct eBayListingCreationResponse: Codable {
    let itemID: String?
    let success: Bool
    let response: String
}

