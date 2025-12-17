import Foundation

/// Configuration for OpenAI API
/// 
/// IMPORTANT: For the API key, either:
/// 1. Set OPENAI_API_KEY environment variable in Xcode scheme
/// 2. Create OpenAIConfig.local.swift with localApiKey (gitignored)
/// 3. Hardcode below (NOT recommended for public repos)
///
/// Get your key at: https://platform.openai.com/api-keys
struct OpenAIConfig {
    // Uses: environment variable -> local file extension -> empty fallback
    static var apiKey: String {
        // First try environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // Then try the local extension (defined in OpenAIConfig.local.swift if it exists)
        // This is handled by checking if localApiKey exists
        #if DEBUG
        return localApiKey
        #else
        return ""
        #endif
    }
    
    // Default empty key - override in OpenAIConfig.local.swift
    static var localApiKey: String { "" }
    
    /// Check if a valid API key is configured
    static var isConfigured: Bool {
        !apiKey.isEmpty
    }
}
