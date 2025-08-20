import SwiftUI
import AVFoundation

// MARK: - OpenAI Configuration
struct OpenAIConfig {
    static let apiKey = "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" // Replace with your actual API key
    static let apiURL = "https://api.openai.com/v1/chat/completions"
}


// MARK: - Item Analysis Model
struct ItemAnalysis: Equatable {
    let itemName: String
    let condition: String
    let description: String
    let estimatedValue: String
    let category: String
}

