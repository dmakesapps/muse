import Foundation

/// Configuration for OpenAI API
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
