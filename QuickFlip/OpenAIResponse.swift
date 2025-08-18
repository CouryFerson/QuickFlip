//
//  OpenAIResponse.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/17/25.
//

import Foundation

// MARK: - OpenAI Response Models
struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
    let serviceTier: String?
    let systemFingerprint: String?

    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
        case serviceTier = "service_tier"
        case systemFingerprint = "system_fingerprint"
    }
}

struct Choice: Codable {
    let index: Int
    let message: Message
    let logprobs: String? // Can be null
    let finishReason: String

    enum CodingKeys: String, CodingKey {
        case index, message, logprobs
        case finishReason = "finish_reason"
    }
}

struct Message: Codable {
    let role: String
    let content: String
    let refusal: String? // Can be null
    let annotations: [String] // Usually empty array
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let promptTokensDetails: TokenDetails?
    let completionTokensDetails: CompletionTokenDetails?

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case promptTokensDetails = "prompt_tokens_details"
        case completionTokensDetails = "completion_tokens_details"
    }
}

struct TokenDetails: Codable {
    let cachedTokens: Int
    let audioTokens: Int

    enum CodingKeys: String, CodingKey {
        case cachedTokens = "cached_tokens"
        case audioTokens = "audio_tokens"
    }
}

struct CompletionTokenDetails: Codable {
    let reasoningTokens: Int
    let audioTokens: Int
    let acceptedPredictionTokens: Int
    let rejectedPredictionTokens: Int

    enum CodingKeys: String, CodingKey {
        case reasoningTokens = "reasoning_tokens"
        case audioTokens = "audio_tokens"
        case acceptedPredictionTokens = "accepted_prediction_tokens"
        case rejectedPredictionTokens = "rejected_prediction_tokens"
    }
}

// MARK: - Convenience Extensions
extension OpenAIResponse {
    /// Gets the content from the first choice, if available
    var firstContent: String? {
        return choices.first?.message.content
    }

    /// Gets the total cost estimate (rough calculation)
    var estimatedCost: Double {
        // Rough pricing: $0.00300 per 1K prompt tokens, $0.01200 per 1K completion tokens for GPT-4o
        let promptCost = (Double(usage.promptTokens) / 1000.0) * 0.00300
        let completionCost = (Double(usage.completionTokens) / 1000.0) * 0.01200
        return promptCost + completionCost
    }
}
