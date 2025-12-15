import Foundation

/// Configuration for OpenAI API
/// 
/// IMPORTANT: Replace the placeholder with your actual API key
/// Get your key at: https://platform.openai.com/api-keys
///
/// For production, consider using:
/// - Environment variables
/// - Keychain storage
/// - A backend proxy to protect your key
struct OpenAIConfig {
    // Replace with your OpenAI API key
    static let apiKey = ""
    
    /// Check if a valid API key is configured
    static var isConfigured: Bool {
        !apiKey.isEmpty && apiKey != "YOUR_OPENAI_API_KEY_HERE"
    }

