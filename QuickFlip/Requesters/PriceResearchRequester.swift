//
//  PriceResearchRequester.swift
//  QuickFlip
//
//  Updated to use Supabase Edge Functions
//

import Foundation

struct PriceResearchRequest {
    let itemName: String
    let category: String
}

struct PriceResearchRequester: SupabaseRequester {
    typealias RequestType = PriceResearchRequest
    typealias ResponseType = MarketplacePriceAnalysis

    let tokenCost = 1
    let model = "gpt-4o-mini"
    let maxTokens = 300
    let temperature = 0.3
    let tokenManager: TokenManaging
    let edgeFunctionCaller: EdgeFunctionCalling

    var functionName: String { "research-prices" }

    func buildRequestBody(_ request: PriceResearchRequest) -> [String: Any] {
        return [
            "itemName": request.itemName,
            "category": request.category,
            "model": model,
            "maxTokens": maxTokens,
            "temperature": temperature
        ]
    }

    func parseResponse(_ content: String) throws -> MarketplacePriceAnalysis {
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
