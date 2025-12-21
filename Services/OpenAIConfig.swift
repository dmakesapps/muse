import Foundation

/// Configuration for OpenAI API
/// All API keys are stored in APIKeys.swift (gitignored)
struct OpenAIConfig {
    static var apiKey: String {
        return APIKeys.openAI
    }
    
    static var isConfigured: Bool {
        !apiKey.isEmpty
    }
}
