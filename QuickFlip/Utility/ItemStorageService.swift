//
//  ItemStorageService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import Foundation
import Combine

class ItemStorageService: ObservableObject {
    @Published var scannedItems: [ScannedItem] = []
    @Published var userStats: UserStats = UserStats(from: [])

    private let fileName = "scannedItems.json"
    private let statsFileName = "userStats.json"

    init() {
        loadItems()
        updateStats()
    }

    // MARK: - Public Methods
    func saveItem(_ item: ScannedItem) {
        scannedItems.insert(item, at: 0) // Most recent first
        saveToFile()
        updateStats()

        print("QuickFlip: Saved item '\(item.itemName)' to storage")
    }

    func deleteItem(_ item: ScannedItem) {
        scannedItems.removeAll { $0.id == item.id }
        saveToFile()
        updateStats()

        print("QuickFlip: Deleted item '\(item.itemName)' from storage")
    }

    func updateItem(matching predicate: (ScannedItem) -> Bool, with newItem: ScannedItem) {
        if let index = scannedItems.firstIndex(where: predicate) {
            scannedItems[index] = newItem
            saveToFile()
            updateStats()
            print("QuickFlip: Updated existing item")
        } else {
            saveItem(newItem)
            print("QuickFlip: Created new item (no match found)")
        }
    }

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
            print("QuickFlip: Failed to export data: \(error)")
            return nil
        }
    }

    func clearAllData() {
        scannedItems.removeAll()
        saveToFile()
        updateStats()
    }

    // MARK: - Private Methods
    private func saveToFile() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)

        do {
            let data = try JSONEncoder().encode(scannedItems)
            try data.write(to: url)
        } catch {
            print("QuickFlip: Failed to save items: \(error)")
        }
    }

    private func loadItems() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("QuickFlip: No saved items file found - starting fresh")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            scannedItems = try JSONDecoder().decode([ScannedItem].self, from: data)
            print("QuickFlip: Loaded \(scannedItems.count) items from storage")
        } catch {
            print("QuickFlip: Failed to load items: \(error)")
            // Don't crash - just start with empty array
            scannedItems = []
        }
    }

    private func updateStats() {
        userStats = UserStats(from: scannedItems)
        saveStats()
    }

    private func saveStats() {
        let url = getDocumentsDirectory().appendingPathComponent(statsFileName)

        do {
            let data = try JSONEncoder().encode(userStats)
            try data.write(to: url)
        } catch {
            print("QuickFlip: Failed to save stats: \(error)")
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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

    var topMarketplace: String {
        return userStats.favoriteMarketplace
    }
}
