import Foundation

/// Service for loading quotes and affirmations from bundled JSON files
class ContentLoader {
    static let shared = ContentLoader()
    
    private init() {}
    
    // MARK: - Load Quotes
    func loadQuotes() -> [Quote] {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json") else {
            print("❌ Could not find quotes.json in bundle")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let quotes = try JSONDecoder().decode([Quote].self, from: data)
            print("✅ Loaded \(quotes.count) quotes from JSON")
            return quotes
        } catch {
            print("❌ Error loading quotes: \(error)")
            return []
        }
    }
    
    // MARK: - Load Affirmations
    func loadAffirmations() -> [Affirmation] {
        guard let url = Bundle.main.url(forResource: "affirmations", withExtension: "json") else {
            print("❌ Could not find affirmations.json in bundle")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let affirmations = try JSONDecoder().decode([Affirmation].self, from: data)
            print("✅ Loaded \(affirmations.count) affirmations from JSON")
            return affirmations
        } catch {
            print("❌ Error loading affirmations: \(error)")
            return []
        }
    }
    
    // MARK: - Get Unique Categories
    func getQuoteCategories() -> [String] {
        let quotes = loadQuotes()
        let categories = Set(quotes.map { $0.category })
        return Array(categories).sorted()
    }
    
    func getAffirmationCategories() -> [String] {
        let affirmations = loadAffirmations()
        let categories = Set(affirmations.map { $0.category })
        return Array(categories).sorted()
    }
}

