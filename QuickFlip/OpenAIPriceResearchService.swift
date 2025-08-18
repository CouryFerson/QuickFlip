//
//  OpenAIPriceResearchService.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import Foundation

enum PriceServiceError: Error {
    case invalidURL
    case noData
    case parsingError
}

class OpenAIPriceResearchService: ObservableObject {

    func researchPrices(for itemName: String, category: String) async throws -> MarketplacePriceAnalysis {
        let prompt = """
        I need you to research current market prices for this item: "\(itemName)"
        Category: \(category)
        
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

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 300,
            "temperature": 0.3 // Lower temperature for more consistent pricing
        ]

        guard let url = URL(string: OpenAIConfig.apiURL) else {
            throw PriceServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw PriceServiceError.parsingError
        }

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw PriceServiceError.parsingError
        }

        print("QuickFlip: OpenAI Price Research Result:\n\(content)")

        return parseOpenAIPriceResponse(content)
    }

    private func parseOpenAIPriceResponse(_ content: String) -> MarketplacePriceAnalysis {
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
            } else if trimmedLine.hasPrefix("REASONING:") {
                break
            } else if trimmedLine.hasPrefix("CONFIDENCE:") {
                let confidenceStr = String(trimmedLine.dropFirst(11)).trimmingCharacters(in: .whitespacesAndNewlines)
                confidence = parseConfidence(from: confidenceStr)
            }
        }

        // Remove nil prices
        let validPrices = prices.compactMapValues { $0 }

        // ALWAYS recommend the marketplace with the highest price
        let recommendedMarketplace = validPrices.max(by: { $0.value < $1.value })?.key ?? .ebay
        let highestPrice = validPrices[recommendedMarketplace] ?? 0

        // Calculate how much higher the best marketplace is
        let averagePrice = validPrices.values.reduce(0, +) / Double(validPrices.count)
        let percentHigher = ((highestPrice - averagePrice) / averagePrice) * 100

        // Generate new reasoning based on the highest price
        let newReasoning: String
        if percentHigher > 20 {
            newReasoning = "\(recommendedMarketplace.rawValue) offers \(Int(percentHigher))% higher prices than average for this item"
        } else if percentHigher > 10 {
            newReasoning = "\(recommendedMarketplace.rawValue) has the highest price at $\(String(format: "%.2f", highestPrice))"
        } else {
            newReasoning = "\(recommendedMarketplace.rawValue) offers the best value among available marketplaces"
        }

        print("QuickFlip: Highest price marketplace: \(recommendedMarketplace.rawValue) at $\(highestPrice)")
        print("QuickFlip: Average price: $\(String(format: "%.2f", averagePrice))")
        print("QuickFlip: Price advantage: \(Int(percentHigher))%")

        return MarketplacePriceAnalysis(
            recommendedMarketplace: recommendedMarketplace,
            confidence: confidence,
            averagePrices: validPrices,
            reasoning: newReasoning
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

    private func parseMarketplace(from name: String) -> Marketplace {
        let lowercased = name.lowercased()

        if lowercased.contains("ebay") { return .ebay }
        if lowercased.contains("facebook") { return .facebook }
        if lowercased.contains("amazon") { return .amazon }
        if lowercased.contains("stockx") { return .stockx }
        if lowercased.contains("etsy") { return .etsy }
        if lowercased.contains("mercari") { return .mercari }
        if lowercased.contains("poshmark") { return .poshmark }
        if lowercased.contains("depop") { return .depop }

        return .ebay // Default
    }

    private func parseConfidence(from confidenceStr: String) -> AnalysisConfidence {
        let lowercased = confidenceStr.lowercased()

        if lowercased.contains("high") { return .high }
        if lowercased.contains("low") { return .low }
        return .medium
    }
}
