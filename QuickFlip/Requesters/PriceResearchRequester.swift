//
//  PriceResearchRequester.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/28/25.
//

import Foundation

struct PriceResearchRequest {
    let itemName: String
    let category: String
}

struct PriceResearchRequester: OpenAIRequester {
    typealias RequestType = PriceResearchRequest
    typealias ResponseType = MarketplacePriceAnalysis

    let tokenCost = 1
    let model = "gpt-4o-mini"
    let maxTokens = 300
    let temperature = 0.3
    let tokenManager: TokenManaging

    func buildRequestBody(_ request: PriceResearchRequest) -> [String: Any] {
        let prompt = """
        I need you to research current market prices for this item: "\(request.itemName)"
        Category: \(request.category)
        
        Please provide realistic price estimates for each marketplace based on your knowledge of:
        1. Typical pricing patterns for this item type
        2. Each marketplace's audience and pricing trends
        3. Current market conditions
        
        Respond ONLY in this exact format:
        
        EBAY: $XX.XX
        FACEBOOK: $XX.XX
        AMAZON: $XX.XX
        STOCKX: $XX.XX (or "N/A" if not suitable)
        ETSY: $XX.XX (or "N/A" if not suitable)
        MERCARI: $XX.XX
        POSHMARK: $XX.XX (or "N/A" if not suitable)
        DEPOP: $XX.XX (or "N/A" if not suitable)
        RECOMMENDED: [marketplace name]
        REASONING: [1-2 sentence explanation why this marketplace is best]
        CONFIDENCE: HIGH/MEDIUM/LOW
        
        Base your estimates on typical resale values, not retail prices. If a marketplace isn't suitable for this item type, use "N/A".
        """

        return [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens,
            "temperature": temperature
        ]
    }

    func parseResponse(_ content: String) throws -> MarketplacePriceAnalysis {
        // Use your existing parsing logic from OpenAIPriceResearchService
        let lines = content.components(separatedBy: .newlines)
        var prices: [Marketplace: Double] = [:]
        var confidence: AnalysisConfidence = .medium

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.hasPrefix("EBAY:") {
                prices[.ebay] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("FACEBOOK:") {
                prices[.facebook] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("AMAZON:") {
                prices[.amazon] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("STOCKX:") {
                prices[.stockx] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("ETSY:") {
                prices[.etsy] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("MERCARI:") {
                prices[.mercari] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("POSHMARK:") {
                prices[.poshmark] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("DEPOP:") {
                prices[.depop] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("CONFIDENCE:") {
                let confidenceStr = String(trimmedLine.dropFirst(11)).trimmingCharacters(in: .whitespacesAndNewlines)
                confidence = parseConfidence(from: confidenceStr)
            }
        }

        let validPrices = prices.compactMapValues { $0 }
        let recommendedMarketplace = validPrices.max(by: { $0.value < $1.value })?.key ?? .ebay
        let highestPrice = validPrices[recommendedMarketplace] ?? 0
        let averagePrice = validPrices.values.reduce(0, +) / Double(validPrices.count)
        let percentHigher = ((highestPrice - averagePrice) / averagePrice) * 100

        let reasoning: String
        if percentHigher > 20 {
            reasoning = "\(recommendedMarketplace.rawValue) offers \(Int(percentHigher))% higher prices than average for this item"
        } else {
            reasoning = "\(recommendedMarketplace.rawValue) has the best price at $\(String(format: "%.2f", highestPrice))"
        }

        return MarketplacePriceAnalysis(
            recommendedMarketplace: recommendedMarketplace,
            confidence: confidence,
            averagePrices: validPrices,
            reasoning: reasoning
        )
    }

    private func extractPrice(from line: String) -> Double? {
        if line.contains("N/A") || line.contains("n/a") {
            return nil
        }

        let pricePattern = #"\$(\d+\.?\d*)"#
        do {
            let regex = try NSRegularExpression(pattern: pricePattern)
            let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))

            if let match = matches.first,
               let range = Range(match.range(at: 1), in: line) {
                return Double(String(line[range]))
            }
        } catch {
            print("QuickFlip: Price extraction error: \(error)")
        }

        return nil
    }

    private func parseConfidence(from confidenceStr: String) -> AnalysisConfidence {
        let lowercased = confidenceStr.lowercased()
        if lowercased.contains("high") { return .high }
        if lowercased.contains("low") { return .low }
        return .medium
    }
}
