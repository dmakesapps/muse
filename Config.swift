import Foundation

enum Config {
    // Get API key from environment variable
    // Set in Xcode scheme → Run → Arguments → Environment Variables
    // Key: ANTHROPIC_API_KEY
    static var anthropicAPIKey: String? {
        // Get API key from environment variable
        if let envKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        return nil
    }
}



