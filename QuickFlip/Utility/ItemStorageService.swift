//
//  ItemStorageService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import Foundation
import Combine
import UIKit

@MainActor
class ItemStorageService: ObservableObject {
    @Published var scannedItems: [ScannedItem] = []
    @Published var userStats: UserStats = UserStats(from: [])
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabaseService: SupabaseService

    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }

    // MARK: - Public Methods

    func saveItem(_ item: ScannedItem, image: UIImage?) async {
        do {
            let updatedItem = try await supabaseService.saveScannedItem(item, image: image)
            // Now add the updated item with proper imageUrl
            scannedItems.insert(updatedItem, at: 0)
            updateStatsLocally()

            try await supabaseService.saveUserStats(userStats)
            print("QuickFlip: Saved item '\(updatedItem.itemName)' to database")
            clearError()
        } catch {
            // Revert stats update on failure since we never added the item
            updateStatsLocally()
            setError("Failed to save item: \(error.localizedDescription)")
            print("QuickFlip: Failed to save item: \(error)")
        }
    }

    func deleteItem(_ item: ScannedItem) async {
        // Store the item and its index for potential rollback
        guard let index = scannedItems.firstIndex(where: { $0.id == item.id }) else { return }
        let itemToDelete = scannedItems[index]

        // Optimistically update UI
        scannedItems.remove(at: index)
        updateStatsLocally()

        do {
            try await supabaseService.deleteScannedItem(item)
            try await supabaseService.saveUserStats(userStats)
            print("QuickFlip: Deleted item '\(item.itemName)' from database")
            clearError()
        } catch {
            // Revert optimistic update on failure
            scannedItems.insert(itemToDelete, at: index)
            updateStatsLocally()
            setError("Failed to delete item: \(error.localizedDescription)")
            print("QuickFlip: Failed to delete item: \(error)")
        }
    }

    func updateItem(matching predicate: (ScannedItem) -> Bool, with newItem: ScannedItem) async {
        if let index = scannedItems.firstIndex(where: predicate) {
            let oldItem = scannedItems[index]

            // Optimistically update UI
            scannedItems[index] = newItem
            updateStatsLocally()

            do {
                try await supabaseService.updateScannedItem(newItem)
                try await supabaseService.saveUserStats(userStats)
                print("QuickFlip: Updated existing item")
                clearError()
            } catch {
                // Revert optimistic update on failure
                scannedItems[index] = oldItem
                updateStatsLocally()
                setError("Failed to update item: \(error.localizedDescription)")
                print("QuickFlip: Failed to update item: \(error)")
            }
        } else {
            await saveItem(newItem, image: nil)
            print("QuickFlip: Created new item (no match found)")
        }
    }

    func updateItemImage(for item: ScannedItem, newImage: UIImage) async {
        do {
            // Update the image via SupabaseService
            try await supabaseService.updateScannedItem(item, newImage: newImage)

            // Fetch the updated item to get the new image URL
            let updatedItems = try await supabaseService.fetchUserScannedItems()

            // Find and update the item in our local array
            if let updatedItem = updatedItems.first(where: { $0.id == item.id }) {
                if let index = scannedItems.firstIndex(where: { $0.id == item.id }) {
                    scannedItems[index] = updatedItem
                }
            }

            ImageCacheManager.shared.invalidateImage(for: item.imageUrl ?? "")

            print("QuickFlip: Updated image for item '\(item.itemName)'")
            clearError()
        } catch {
            setError("Failed to update image: \(error.localizedDescription)")
            print("QuickFlip: Failed to update image: \(error)")
        }
    }

    func updateItemImage(for item: ScannedItem, newImage: UIImage) {
        Task {
            await updateItemImage(for: item, newImage: newImage)
        }
    }

    // MARK: - Synchronous Methods (for existing SwiftUI compatibility)

    func saveItem(_ item: ScannedItem, image: UIImage?) {
        Task {
            await saveItem(item, image: image)
        }
    }

    func deleteItem(_ item: ScannedItem) {
        Task { await deleteItem(item) }
    }

    func updateItem(matching predicate: @escaping (ScannedItem) -> Bool, with newItem: ScannedItem) {
        Task { await updateItem(matching: predicate, with: newItem) }
    }

    // MARK: - Search and Filter Methods

    func searchItems(query: String) -> [ScannedItem] {
        guard !query.isEmpty else { return scannedItems }

        return scannedItems.filter { item in
            item.itemName.localizedCaseInsensitiveContains(query) ||
            item.category.localizedCaseInsensitiveContains(query) ||
            item.description.localizedCaseInsensitiveContains(query) ||
            (item.storageLocation?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func getItemsByMarketplace(_ marketplace: String) -> [ScannedItem] {
        return scannedItems.filter { $0.priceAnalysis.recommendedMarketplace == marketplace }
    }

    func getRecentItems(limit: Int = 5) -> [ScannedItem] {
        return Array(scannedItems.prefix(limit))
    }

    func exportData() -> Data? {
        do {
            return try JSONEncoder().encode(scannedItems)
        } catch {
            setError("Failed to export data: \(error.localizedDescription)")
            return nil
        }
    }

    func clearAllData() async {
        let itemsToDelete = scannedItems

        // Optimistically clear UI
        scannedItems.removeAll()
        updateStatsLocally()

        do {
            // Delete all items from database
            for item in itemsToDelete {
                try await supabaseService.deleteScannedItem(item)
            }
            try await supabaseService.saveUserStats(userStats)
            print("QuickFlip: Cleared all data")
            clearError()
        } catch {
            // Revert optimistic update on failure
            scannedItems = itemsToDelete
            updateStatsLocally()
            setError("Failed to clear data: \(error.localizedDescription)")
            print("QuickFlip: Failed to clear data: \(error)")
        }
    }

    func fetchScannedItems() async {
        isLoading = true
        clearError()

        do {
            // Run both queries simultaneously
            async let itemsTask = supabaseService.fetchUserScannedItems()
            async let statsTask = supabaseService.fetchUserStats()

            let (items, stats) = try await (itemsTask, statsTask)

            scannedItems = items
            print("QuickFlip: Loaded \(scannedItems.count) items from database")

            if let stats = stats {
                userStats = stats
            } else {
                // Create initial stats if none exist
                userStats = UserStats(from: scannedItems)
                try await supabaseService.saveUserStats(userStats)
                print("Created initial user stats")
            }

            clearError()
        } catch {
            setError("Failed to load data: \(error.localizedDescription)")
            print("QuickFlip: Failed to load user data: \(error)")
        }

        isLoading = false
    }

    // MARK: - Private Methods

    private func updateStatsLocally() {
        userStats = UserStats(from: scannedItems)
    }

    private func setError(_ message: String) {
        errorMessage = message
    }

    private func clearError() {
        errorMessage = nil
    }
}

// MARK: - Convenience Extensions
extension ItemStorageService {
    var isEmpty: Bool {
        return scannedItems.isEmpty
    }

    var totalItemCount: Int {
        return scannedItems.count
    }

    var totalSavings: String {
        return String(format: "$%.0f", userStats.totalPotentialSavings)
    }

    var totalPotentialProfit: String {
        return String(format: "$%.0f", userStats.totalPotentialProfit)
    }

    var topMarketplace: String {
        return userStats.favoriteMarketplace
    }

    var hasError: Bool {
        return errorMessage != nil
    }
}

// MARK: - Listing Status Update Methods
// Add these methods to your ItemStorageService class

extension ItemStorageService {

    /// Updates the listing status for a specific item
    func updateListingStatus(for item: ScannedItem, newStatus: ListingStatus) async {
        guard let index = scannedItems.firstIndex(where: { $0.id == item.id }) else {
            setError("Item not found")
            return
        }

        let oldItem = scannedItems[index]
        var updatedItem = oldItem
        updatedItem.listingStatus = newStatus

        // Optimistically update UI
        scannedItems[index] = updatedItem

        do {
            try await supabaseService.updateScannedItem(updatedItem)
            print("QuickFlip: Updated listing status for '\(updatedItem.itemName)' to \(newStatus.status.rawValue)")
            clearError()
        } catch {
            // Revert optimistic update on failure
            scannedItems[index] = oldItem
            setError("Failed to update listing status: \(error.localizedDescription)")
            print("QuickFlip: Failed to update listing status: \(error)")
        }
    }

    /// Synchronous wrapper for SwiftUI compatibility
    func updateListingStatus(for item: ScannedItem, newStatus: ListingStatus) {
        Task {
            await updateListingStatus(for: item, newStatus: newStatus)
        }
    }

    /// Mark item as listed on specific marketplaces
    func markItemAsListed(item: ScannedItem, on marketplaces: [Marketplace]) async {
        var newStatus = item.listingStatus
        newStatus.markAsListed(on: marketplaces)
        await updateListingStatus(for: item, newStatus: newStatus)
    }

    /// Mark item as sold
    func markItemAsSold(
        item: ScannedItem,
        price: Double,
        marketplace: Marketplace,
        costBasis: Double? = nil
    ) async {
        var newStatus = item.listingStatus
        newStatus.markAsSold(price: price, marketplace: marketplace, costBasis: costBasis)
        await updateListingStatus(for: item, newStatus: newStatus)
    }

    /// Mark item as ready to list (reset status)
    func markItemAsReadyToList(item: ScannedItem) async {
        var newStatus = item.listingStatus
        newStatus.markAsReadyToList()
        await updateListingStatus(for: item, newStatus: newStatus)
    }

    /// Update storage location for an item
    func updateStorageLocation(for item: ScannedItem, location: String?) async {
        guard let index = scannedItems.firstIndex(where: { $0.id == item.id }) else { return }

        var updatedItem = scannedItems[index]
        updatedItem.storageLocation = location

        // Optimistically update UI
        scannedItems[index] = updatedItem

        do {
            try await supabaseService.updateScannedItem(updatedItem)
            print("QuickFlip: Updated storage location to '\(location ?? "none")'")
            clearError()
        } catch {
            // Revert on failure
            scannedItems[index] = item
            setError("Failed to update storage location: \(error.localizedDescription)")
            print("QuickFlip: Failed to update storage location: \(error)")
        }
    }

    // MARK: - Query Methods for Listing Status

    /// Get all items with a specific status
    func getItems(withStatus status: ItemStatus) -> [ScannedItem] {
        return scannedItems.filter { $0.listingStatus.status == status }
    }

    /// Get all listed items
    var listedItems: [ScannedItem] {
        return getItems(withStatus: .listed)
    }

    /// Get all sold items
    var soldItems: [ScannedItem] {
        return getItems(withStatus: .sold)
    }

    /// Get all items ready to list
    var readyToListItems: [ScannedItem] {
        return getItems(withStatus: .readyToList)
    }

    /// Calculate total revenue from sold items
    var totalRevenue: Double {
        return soldItems.compactMap { $0.listingStatus.soldPrice }.reduce(0, +)
    }

    /// Calculate total profit from sold items (if cost basis is provided)
    var totalProfit: Double {
        return soldItems.compactMap { $0.listingStatus.netProfit }.reduce(0, +)
    }

    /// Get formatted total revenue
    var formattedTotalRevenue: String {
        return String(format: "$%.2f", totalRevenue)
    }

    /// Get formatted total profit
    var formattedTotalProfit: String {
        let sign = totalProfit >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", totalProfit))"
    }

    // MARK: - Inventory Health Properties

    /// Get all unsold items (ready to list + listed)
    var unsoldItems: [ScannedItem] {
        return scannedItems.filter { $0.listingStatus.status != .sold }
    }

    /// Get fresh items (scanned 0-7 days ago, not sold)
    var freshItems: [ScannedItem] {
        return unsoldItems.filter { $0.daysSinceScanned <= 7 }
    }

    /// Get active items (scanned 8-30 days ago, not sold)
    var activeItems: [ScannedItem] {
        let days = unsoldItems.map { $0.daysSinceScanned }
        return unsoldItems.filter { $0.daysSinceScanned > 7 && $0.daysSinceScanned <= 30 }
    }

    /// Get stale items (scanned 30+ days ago, not sold)
    var staleItems: [ScannedItem] {
        return unsoldItems.filter { $0.daysSinceScanned > 30 }
    }

    /// Get items that need attention (ready to list for 14+ days OR listed for 30+ days)
    var itemsNeedingAttention: [ScannedItem] {
        return scannedItems.filter { item in
            if item.listingStatus.status == .readyToList && item.daysSinceScanned > 14 {
                return true
            }
            if item.listingStatus.status == .listed,
               let dateListed = item.listingStatus.dateListed {
                let daysListed = Calendar.current.dateComponents([.day], from: dateListed, to: Date()).day ?? 0
                return daysListed > 30
            }
            return false
        }
    }

    /// Calculate total inventory value (estimated value of unsold items)
    var totalInventoryValue: Double {
        return unsoldItems.compactMap { item -> Double? in
            // Parse estimated value string (e.g., "$50-75" -> take midpoint)
            let cleaned = item.estimatedValue.replacingOccurrences(of: "$", with: "")
            let components = cleaned.components(separatedBy: "-")

            if components.count == 2,
               let min = Double(components[0].trimmingCharacters(in: .whitespaces)),
               let max = Double(components[1].trimmingCharacters(in: .whitespaces)) {
                return (min + max) / 2
            } else if let single = Double(cleaned.trimmingCharacters(in: .whitespaces)) {
                return single
            }
            return nil
        }.reduce(0, +)
    }

    /// Get formatted total inventory value
    var formattedTotalInventoryValue: String {
        return String(format: "$%.0f", totalInventoryValue)
    }

    // MARK: - Inventory Velocity Metrics

    /// Average days from scan to list
    var averageDaysToList: Double? {
        let listedAndSoldItems = scannedItems.filter {
            $0.listingStatus.status == .listed || $0.listingStatus.status == .sold
        }

        guard !listedAndSoldItems.isEmpty else { return nil }

        let totalDays = listedAndSoldItems.compactMap { item -> Int? in
            guard let dateListed = item.listingStatus.dateListed else { return nil }
            return Calendar.current.dateComponents([.day], from: item.timestamp, to: dateListed).day
        }.reduce(0, +)

        guard !listedAndSoldItems.isEmpty else { return nil }
        return Double(totalDays) / Double(listedAndSoldItems.count)
    }

    /// Average days from list to sold
    var averageDaysToSell: Double? {
        guard !soldItems.isEmpty else { return nil }

        let totalDays = soldItems.compactMap { item -> Int? in
            guard let dateListed = item.listingStatus.dateListed,
                  let dateSold = item.listingStatus.dateSold else { return nil }
            return Calendar.current.dateComponents([.day], from: dateListed, to: dateSold).day
        }.reduce(0, +)

        return Double(totalDays) / Double(soldItems.count)
    }

    /// Average total cycle time (scan to sold)
    var averageCycleTime: Double? {
        guard !soldItems.isEmpty else { return nil }

        let totalDays = soldItems.compactMap { item -> Int? in
            guard let dateSold = item.listingStatus.dateSold else { return nil }
            return Calendar.current.dateComponents([.day], from: item.timestamp, to: dateSold).day
        }.reduce(0, +)

        return Double(totalDays) / Double(soldItems.count)
    }

    /// Get fastest selling items (top 3)
    var fastestFlips: [ScannedItem] {
        return soldItems
            .compactMap { item -> (item: ScannedItem, days: Int)? in
                guard let dateSold = item.listingStatus.dateSold else { return nil }
                let days = Calendar.current.dateComponents([.day], from: item.timestamp, to: dateSold).day ?? 0
                return (item, days)
            }
            .sorted { $0.days < $1.days }
            .prefix(3)
            .map { $0.item }
    }

    /// Get slowest selling items (top 3)
    var slowestFlips: [ScannedItem] {
        return soldItems
            .compactMap { item -> (item: ScannedItem, days: Int)? in
                guard let dateSold = item.listingStatus.dateSold else { return nil }
                let days = Calendar.current.dateComponents([.day], from: item.timestamp, to: dateSold).day ?? 0
                return (item, days)
            }
            .sorted { $0.days > $1.days }
            .prefix(3)
            .map { $0.item }
    }
}
