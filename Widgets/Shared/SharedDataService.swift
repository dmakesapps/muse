import Foundation

/// Service to access shared data between app and widget using App Group
class SharedDataService {
    static let appGroupIdentifier = "group.Ephesian28LLC.Muse"
    
    private static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Quotes
    static func loadQuotes() -> [Quote] {
        guard let data = sharedUserDefaults?.data(forKey: "savedQuotes"),
              let decoded = try? JSONDecoder().decode([Quote].self, from: data) else {
            return []
        }
        return decoded
    }
    
    static func saveQuotes(_ quotes: [Quote]) {
        if let encoded = try? JSONEncoder().encode(quotes) {
            sharedUserDefaults?.set(encoded, forKey: "savedQuotes")
        }
    }
    
    // MARK: - Affirmations
    static func loadAffirmations() -> [Affirmation] {
        guard let data = sharedUserDefaults?.data(forKey: "savedAffirmations"),
              let decoded = try? JSONDecoder().decode([Affirmation].self, from: data) else {
            return []
        }
        return decoded
    }
    
    static func saveAffirmations(_ affirmations: [Affirmation]) {
        if let encoded = try? JSONEncoder().encode(affirmations) {
            sharedUserDefaults?.set(encoded, forKey: "savedAffirmations")
        }
    }
}

