//
//  SupabaseRequester.swift
//  QuickFlip
//
//  Replaces OpenAIRequester - now calls Supabase Edge Functions
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
    case apiError(Int, String?)
    case insufficientTokens(required: Int)
    case authenticationFailed
}

// MARK: - Edge Function Caller Protocol
protocol EdgeFunctionCalling {
    func invokeEdgeFunction(_ functionName: String, body: [String: Any]) async throws -> Data
}

// MARK: - Base Supabase Requester Protocol
protocol SupabaseRequester {
    associatedtype RequestType
    associatedtype ResponseType

    var tokenCost: Int { get }
    var model: String { get }
    var maxTokens: Int { get }
    var temperature: Double { get }
    var tokenManager: TokenManaging { get }
    var edgeFunctionCaller: EdgeFunctionCalling { get }
    var functionName: String { get }

    func buildRequestBody(_ request: RequestType) -> [String: Any]
    func parseResponse(_ content: String) throws -> ResponseType
}

// MARK: - Default Implementation
extension SupabaseRequester {
    func makeRequest(_ request: RequestType) async throws -> ResponseType {
        // Check if user has tokens before making expensive API call
        guard tokenManager.hasTokens() else {
            throw NetworkError.insufficientTokens(required: tokenCost)
        }

        let requestBody = buildRequestBody(request)

        do {
            // Call Supabase Edge Function through the service
            let response = try await edgeFunctionCaller.invokeEdgeFunction(functionName, body: requestBody)

            // Parse response
            guard let json = try JSONSerialization.jsonObject(with: response) as? [String: Any] else {
                throw NetworkError.responseParsingFailed
            }

            // Check for error in response
            if let error = json["error"] as? String {
                throw NetworkError.apiError(500, error)
            }

            // Parse OpenAI response format (from Edge Function)
            guard let choices = json["choices"] as? [[String: Any]],
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
