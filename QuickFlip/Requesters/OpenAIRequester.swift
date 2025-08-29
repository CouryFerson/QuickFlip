//
//  OpenAIRequester.swift
//  QuickFlip
//
//  Created by Ferson, Coury on 8/28/25.
//

import Foundation

// MARK: - Token Management Protocol
protocol TokenManaging {
    func hasTokens() -> Bool
    func consumeTokens(_ amount: Int) async throws -> Int
}

// MARK: - Network Errors
enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case responseParsingFailed
    case apiError(Int)
    case insufficientTokens(required: Int)
}

// MARK: - Base OpenAI Requester Protocol
protocol OpenAIRequester {
    associatedtype RequestType
    associatedtype ResponseType

    var tokenCost: Int { get }
    var model: String { get }
    var maxTokens: Int { get }
    var temperature: Double { get }
    var tokenManager: TokenManaging { get }

    func buildRequestBody(_ request: RequestType) -> [String: Any]
    func parseResponse(_ content: String) throws -> ResponseType
}

// MARK: - Default Implementation
extension OpenAIRequester {
    func makeRequest(_ request: RequestType) async throws -> ResponseType {
        // Check if user has tokens before making expensive API call
        guard tokenManager.hasTokens() else {
            throw NetworkError.insufficientTokens(required: tokenCost)
        }

        let requestBody = buildRequestBody(request)

        guard let url = URL(string: OpenAIConfig.apiURL) else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = 60.0

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            // Validate HTTP response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("QuickFlip: API Error Response: \(errorString)")
                }
                throw NetworkError.apiError(httpResponse.statusCode)
            }

            // Parse OpenAI response format
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw NetworkError.responseParsingFailed
            }

            // Parse the specific response type
            let result = try parseResponse(content)

            // Only consume tokens AFTER successful response
            try await consumeRequiredTokens()

            return result

        } catch {
            print("QuickFlip: Request failed: \(error)")
            throw NetworkError.requestFailed(error)
        }
    }

    private func consumeRequiredTokens() async throws {
        let remaining = try await tokenManager.consumeTokens(tokenCost)
        print("QuickFlip: Consumed \(tokenCost) tokens. Remaining: \(remaining)")
    }
}
