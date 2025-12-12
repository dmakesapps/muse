import Foundation

/// Service to access shared data between app and widget using App Group
class SharedDataService {
    static let appGroupIdentifier = "group.Ephesian28LLC.Muse"
    
    private static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Quotes
    static func loadQuotes() -> [Quote] {
        guard let defaults = sharedUserDefaults else {
            print("Widget: Failed to access App Group UserDefaults")
            return []
        }
        
        guard let data = defaults.data(forKey: "savedQuotes") else {
            print("Widget: No quotes data found in App Group")
            return []
        }
        
        guard let decoded = try? JSONDecoder().decode([Quote].self, from: data) else {
            print("Widget: Failed to decode quotes")
            return []
        }
        
        print("Widget: Successfully loaded \(decoded.count) quotes")
        return decoded
    }
    
    static func saveQuotes(_ quotes: [Quote]) {
        if let encoded = try? JSONEncoder().encode(quotes) {
            sharedUserDefaults?.set(encoded, forKey: "savedQuotes")
        }
    }
    
    // MARK: - Affirmations
    static func loadAffirmations() -> [Affirmation] {
        guard let defaults = sharedUserDefaults else {
            print("Widget: Failed to access App Group UserDefaults")
            return []
        }
        
        guard let data = defaults.data(forKey: "savedAffirmations") else {
            print("Widget: No affirmations data found in App Group")
            return []
        }
        
        guard let decoded = try? JSONDecoder().decode([Affirmation].self, from: data) else {
            print("Widget: Failed to decode affirmations")
            return []
        }
        
        print("Widget: Successfully loaded \(decoded.count) affirmations")
        return decoded
    }
    
    static func saveAffirmations(_ affirmations: [Affirmation]) {
        if let encoded = try? JSONEncoder().encode(affirmations) {
            sharedUserDefaults?.set(encoded, forKey: "savedAffirmations")
        }
    }
}

