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
            item.description.localizedCaseInsensitiveContains(query)
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

    var totalProfit: String {
        return String(format: "$%.0f", userStats.totalPotentialProfit)
    }

    var topMarketplace: String {
        return userStats.favoriteMarketplace
    }

    var hasError: Bool {
        return errorMessage != nil
    }
}
