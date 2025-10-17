//
//  ItemStatus.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 10/16/25.
//

import Foundation
import SwiftUI

// MARK: - Item Status Enum
enum ItemStatus: String, Codable, CaseIterable {
    case readyToList = "Ready to List"
    case listed = "Listed"
    case sold = "Sold"

    var displayColor: Color {
        switch self {
        case .readyToList:
            return .orange
        case .listed:
            return .blue
        case .sold:
            return .green
        }
    }

    var iconName: String {
        switch self {
        case .readyToList:
            return "clock.fill"
        case .listed:
            return "tag.fill"
        case .sold:
            return "checkmark.circle.fill"
        }
    }
}

// MARK: - Listing Status
struct ListingStatus: Codable, Equatable {
    var status: ItemStatus
    var listedMarketplaces: [String] // Store as String array for Marketplace.rawValue
    var dateListed: Date?

    // Sold-specific data
    var soldPrice: Double?
    var soldMarketplace: String? // Store as String for Marketplace.rawValue
    var dateSold: Date?
    var costBasis: Double? // Optional - what user paid for the item

    // MARK: - Computed Properties
    var netProfit: Double? {
        guard let soldPrice = soldPrice else { return nil }
        guard let costBasis = costBasis else { return nil }
        return soldPrice - costBasis
    }

    var profitMargin: Double? {
        guard let netProfit = netProfit, let soldPrice = soldPrice, soldPrice > 0 else { return nil }
        return (netProfit / soldPrice) * 100
    }

    var formattedSoldPrice: String? {
        guard let soldPrice = soldPrice else { return nil }
        return String(format: "$%.2f", soldPrice)
    }

    var formattedNetProfit: String? {
        guard let netProfit = netProfit else { return nil }
        let sign = netProfit >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", netProfit))"
    }

    var profitColor: Color {
        guard let netProfit = netProfit else { return .secondary }
        if netProfit > 0 { return .green }
        if netProfit == 0 { return .orange }
        return .red
    }

    // MARK: - Initializers

    // Default initializer for new items
    init() {
        self.status = .readyToList
        self.listedMarketplaces = []
        self.dateListed = nil
        self.soldPrice = nil
        self.soldMarketplace = nil
        self.dateSold = nil
        self.costBasis = nil
    }

    // Full initializer
    init(
        status: ItemStatus,
        listedMarketplaces: [String] = [],
        dateListed: Date? = nil,
        soldPrice: Double? = nil,
        soldMarketplace: String? = nil,
        dateSold: Date? = nil,
        costBasis: Double? = nil
    ) {
        self.status = status
        self.listedMarketplaces = listedMarketplaces
        self.dateListed = dateListed
        self.soldPrice = soldPrice
        self.soldMarketplace = soldMarketplace
        self.dateSold = dateSold
        self.costBasis = costBasis
    }

    // MARK: - Helpers for Marketplace enum conversion
    func getListedMarketplacesAsEnum() -> [Marketplace] {
        listedMarketplaces.compactMap { rawValue in
            Marketplace.allCases.first { $0.rawValue == rawValue }
        }
    }

    func getSoldMarketplaceAsEnum() -> Marketplace? {
        guard let soldMarketplace = soldMarketplace else { return nil }
        return Marketplace.allCases.first { $0.rawValue == soldMarketplace }
    }

    // MARK: - Mutation Methods
    mutating func markAsListed(on marketplaces: [Marketplace]) {
        self.status = .listed
        self.listedMarketplaces = marketplaces.map { $0.rawValue }
        self.dateListed = Date()
    }

    mutating func markAsSold(
        price: Double,
        marketplace: Marketplace,
        costBasis: Double? = nil
    ) {
        self.status = .sold
        self.soldPrice = price
        self.soldMarketplace = marketplace.rawValue
        self.dateSold = Date()
        self.costBasis = costBasis
    }

    mutating func markAsReadyToList() {
        self.status = .readyToList
        self.listedMarketplaces = []
        self.dateListed = nil
        self.soldPrice = nil
        self.soldMarketplace = nil
        self.dateSold = nil
        // Keep costBasis if they want to relist
    }
}
