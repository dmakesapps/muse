import Foundation

/// Configuration for OpenAI API
/// 
/// SETUP: Create a file called `LocalSecrets.swift` in the Services folder with:
/// ```
/// struct LocalSecrets {
///     static let openAIKey = "your-actual-api-key"
///     static let openRouterKey = "your-actual-openrouter-key"
/// }
/// ```
/// This file is gitignored and will NOT be pushed to the repository.
struct OpenAIConfig {
    static var apiKey: String {
        // First try environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // Use LocalSecrets if available (gitignored file)
        #if canImport(LocalSecrets)
        return LocalSecrets.openAIKey
        #else
        // Fallback - you need to create LocalSecrets.swift
        return ""
        #endif
    }
    
    /// Check if a valid API key is configured
    static var isConfigured: Bool {
        !apiKey.isEmpty
    }
}

