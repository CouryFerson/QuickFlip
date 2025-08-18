import SwiftUI
import AVFoundation

// MARK: - OpenAI Configuration
struct OpenAIConfig {
    static let apiKey = "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" // Replace with your actual API key
    static let apiURL = "https://api.openai.com/v1/chat/completions"
}

// MARK: - Content View (Navigation)

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        NavigationStack {
            CameraView(appState: appState)
        }
    }
}

// MARK: - Item Analysis Model
struct ItemAnalysis {
    let itemName: String
    let condition: String
    let description: String
    let estimatedValue: String
    let category: String
}

