//
//  AdvancedAnalysisRequester.swift
//  QuickFlip
//
//  Advanced AI analysis using live eBay data as anchor
//

import Foundation

struct AdvancedAnalysisRequest {
    let itemName: String
    let category: String
    let ebayData: MarketPriceData
    let isFirstGeneration: Bool // true = free (first time), false = costs 1 token (refresh)
}

struct AdvancedAnalysisRequester: SupabaseRequester {
    typealias RequestType = AdvancedAnalysisRequest
    typealias ResponseType = MarketplacePriceAnalysis

    let tokenManager: TokenManaging
    let edgeFunctionCaller: EdgeFunctionCalling
    private let isFirstGeneration: Bool
    
    var tokenCost: Int {
        // Free on first generation, charge 1 token on every refresh
        return isFirstGeneration ? 0 : 1
    }
    
    let model = "gpt-4o-mini"
    let maxTokens = 500
    let temperature = 0.3

    var functionName: String { "ebay-anchored-market-analysis" }
    
    init(tokenManager: TokenManaging, edgeFunctionCaller: EdgeFunctionCalling, isFirstGeneration: Bool) {
        self.tokenManager = tokenManager
        self.edgeFunctionCaller = edgeFunctionCaller
        self.isFirstGeneration = isFirstGeneration
    }

    func buildRequestBody(_ request: AdvancedAnalysisRequest) -> [String: Any] {
        return [
            "itemName": request.itemName,
            "category": request.category,
            "ebayData": [
                "avg": request.ebayData.averagePrice,
                "min": request.ebayData.minPrice,
                "max": request.ebayData.maxPrice,
                "soldListings": request.ebayData.totalListings
            ],
            "model": model,
            "maxTokens": maxTokens,
            "temperature": temperature
        ]
    }

    func parseResponse(_ content: String) throws -> MarketplacePriceAnalysis {
        let lines = content.components(separatedBy: .newlines)
        var prices: [Marketplace: Double] = [:]
        var recommendedMarketplace: Marketplace = .ebay
        var reasoning = ""
        var confidence: AnalysisConfidence = .medium

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.hasPrefix("EBAY:") {
                prices[.ebay] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("STOCKX:") {
                prices[.stockx] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("ETSY:") {
                prices[.etsy] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("FACEBOOK:") {
                prices[.facebook] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("MERCARI:") {
                prices[.mercari] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("POSHMARK:") {
                prices[.poshmark] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("DEPOP:") {
                prices[.depop] = extractPrice(from: trimmedLine)
            } else if trimmedLine.hasPrefix("OFFERUP:") {
                // OfferUp isn't in your Marketplace enum yet
            } else if trimmedLine.hasPrefix("RECOMMENDED:") {
                let marketplaceStr = String(trimmedLine.dropFirst(12))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                recommendedMarketplace = parseMarketplace(from: marketplaceStr)
            } else if trimmedLine.hasPrefix("REASONING:") {
                reasoning = String(trimmedLine.dropFirst(10))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("CONFIDENCE:") {
                let confidenceStr = String(trimmedLine.dropFirst(11))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                confidence = parseConfidence(from: confidenceStr)
            }
        }

        return MarketplacePriceAnalysis(
            recommendedMarketplace: recommendedMarketplace,
            confidence: confidence,
            averagePrices: prices.compactMapValues { $0 },
            reasoning: reasoning.isEmpty ? "Based on live eBay data and market analysis" : reasoning
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

    private func parseMarketplace(from marketplaceStr: String) -> Marketplace {
        let lowercased = marketplaceStr.lowercased()
        
        if lowercased.contains("ebay") { return .ebay }
        if lowercased.contains("stockx") || lowercased.contains("stock x") { return .stockx }
        if lowercased.contains("etsy") { return .etsy }
        if lowercased.contains("facebook") { return .facebook }
        if lowercased.contains("mercari") { return .mercari }
        if lowercased.contains("poshmark") { return .poshmark }
        if lowercased.contains("depop") { return .depop }
        if lowercased.contains("amazon") { return .amazon }
        
        return .ebay // default fallback
    }

    private func parseConfidence(from confidenceStr: String) -> AnalysisConfidence {
        let lowercased = confidenceStr.lowercased()
        if lowercased.contains("high") { return .high }
        if lowercased.contains("low") { return .low }
        return .medium
    }
}
