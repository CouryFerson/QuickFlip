//
//  CachedMarketTrends.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import Foundation

struct CachedMarketTrends: Codable {
    let trends: MarketTrends
    let timestamp: Date
}
