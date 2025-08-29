//
//  BulkAnalysisService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import Foundation
import UIKit

// MARK: - Models
struct BulkAnalysisResult {
    let items: [BulkAnalyzedItem]
    let totalCount: Int
    let totalValue: String
    let sceneDescription: String
    let originalImage: UIImage
    let timestamp: Date

    var formattedItemCount: String {
        return "\(items.count) item\(items.count == 1 ? "" : "s")"
    }
}

class BulkAnalyzedItem: ObservableObject {
    var name: String = ""
    var condition: String = ""
    var description: String = ""
    var estimatedValue: String = ""
    var category: String = ""
    var location: String = ""

    func toItemAnalysis() -> ItemAnalysis {
        return ItemAnalysis(
            itemName: name,
            condition: condition,
            description: description,
            estimatedValue: estimatedValue,
            category: category
        )
    }
}

enum BulkAnalysisError: Error {
    case imageProcessingFailed
    case invalidURL
    case requestEncodingFailed
    case responseParsingFailed
}
