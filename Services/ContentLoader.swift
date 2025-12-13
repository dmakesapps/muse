import Foundation

/// Service for loading quotes and affirmations from bundled JSON files
class ContentLoader {
    static let shared = ContentLoader()
    
    private init() {}
    
    // MARK: - Load Quotes
    func loadQuotes() -> [Quote] {
        // Try to load from bundle
        if let url = Bundle.main.url(forResource: "quotes", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let quotes = try JSONDecoder().decode([Quote].self, from: data)
                print("✅ Loaded \(quotes.count) quotes from JSON")
                return quotes
            } catch {
                print("❌ Error decoding quotes: \(error)")
            }
        } else {
            print("❌ Could not find quotes.json in bundle")
            // Debug: Print bundle contents
            if let resourcePath = Bundle.main.resourcePath {
                print("📁 Bundle path: \(resourcePath)")
            }
        }
        
        // Return default quotes as fallback
        return defaultQuotes
    }
    
    // MARK: - Load Affirmations
    func loadAffirmations() -> [Affirmation] {
        // Try to load from bundle
        if let url = Bundle.main.url(forResource: "affirmations", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let affirmations = try JSONDecoder().decode([Affirmation].self, from: data)
                print("✅ Loaded \(affirmations.count) affirmations from JSON")
                return affirmations
            } catch {
                print("❌ Error decoding affirmations: \(error)")
            }
        } else {
            print("❌ Could not find affirmations.json in bundle")
        }
        
        // Return default affirmations as fallback
        return defaultAffirmations
    }
    
    // MARK: - Default Quotes (fallback)
    private var defaultQuotes: [Quote] {
        [
            Quote(text: "Until you make the unconscious conscious, it will direct your life and you will call it fate.", author: "Carl Jung", category: "Self-Discovery"),
            Quote(text: "The privilege of a lifetime is to become who you truly are.", author: "Carl Jung", category: "Purpose"),
            Quote(text: "Realize deeply that the present moment is all you have.", author: "Eckhart Tolle", category: "Presence"),
            Quote(text: "The primary cause of unhappiness is never the situation but your thoughts about it.", author: "Eckhart Tolle", category: "Mental Health"),
            Quote(text: "What you seek is seeking you.", author: "Rumi", category: "Purpose"),
            Quote(text: "Your wound is where the light enters you.", author: "Rumi", category: "Healing"),
            Quote(text: "The meaning of life is just to be alive.", author: "Alan Watts", category: "Wisdom"),
            Quote(text: "We suffer more often in imagination than in reality.", author: "Seneca", category: "Anxiety"),
            Quote(text: "The happiness of your life depends upon the quality of your thoughts.", author: "Marcus Aurelius", category: "Mental Health"),
            Quote(text: "Peace comes from within. Do not seek it without.", author: "Buddha", category: "Inner Peace"),
        ]
    }
    
    // MARK: - Default Affirmations (fallback)
    private var defaultAffirmations: [Affirmation] {
        [
            Affirmation(text: "I am capable of achieving my goals", category: "Confidence"),
            Affirmation(text: "I choose to focus on what I can control", category: "Peace"),
            Affirmation(text: "I am worthy of success and happiness", category: "Self-Worth"),
            Affirmation(text: "I trust in my ability to overcome challenges", category: "Strength"),
            Affirmation(text: "I am grateful for the opportunities in my life", category: "Gratitude"),
            Affirmation(text: "I am becoming the person I want to be", category: "Growth"),
            Affirmation(text: "I deserve to take care of myself", category: "Self-Care"),
            Affirmation(text: "I am confident and ready for new opportunities", category: "Confidence"),
            Affirmation(text: "I am worthy of love and respect", category: "Self-Love"),
            Affirmation(text: "I release anxiety and embrace peace", category: "Anxiety"),
        ]
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

