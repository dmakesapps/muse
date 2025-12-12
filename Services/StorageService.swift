import Foundation

class StorageService: ObservableObject {
    static let shared = StorageService()
    
    @Published var savedQuotes: [Quote] = []
    @Published var savedAffirmations: [Affirmation] = []
    
    private let quotesKey = "savedQuotes"
    private let affirmationsKey = "savedAffirmations"
    
    init() {
        loadSavedItems()
    }
    
    // MARK: - Quotes
    func saveQuote(_ quote: Quote) {
        if !savedQuotes.contains(where: { $0.id == quote.id }) {
            savedQuotes.append(quote)
            saveQuotes()
        }
    }
    
    func removeQuote(_ quote: Quote) {
        savedQuotes.removeAll(where: { $0.id == quote.id })
        saveQuotes()
    }
    
    func isQuoteSaved(_ quote: Quote) -> Bool {
        savedQuotes.contains(where: { $0.id == quote.id })
    }
    
    private func saveQuotes() {
        if let encoded = try? JSONEncoder().encode(savedQuotes) {
            UserDefaults.standard.set(encoded, forKey: quotesKey)
        }
    }
    
    private func loadQuotes() {
        if let data = UserDefaults.standard.data(forKey: quotesKey),
           let decoded = try? JSONDecoder().decode([Quote].self, from: data) {
            savedQuotes = decoded
        }
    }
    
    // MARK: - Affirmations
    func saveAffirmation(_ affirmation: Affirmation) {
        if !savedAffirmations.contains(where: { $0.id == affirmation.id }) {
            savedAffirmations.append(affirmation)
            saveAffirmations()
        }
    }
    
    func removeAffirmation(_ affirmation: Affirmation) {
        savedAffirmations.removeAll(where: { $0.id == affirmation.id })
        saveAffirmations()
    }
    
    func isAffirmationSaved(_ affirmation: Affirmation) -> Bool {
        savedAffirmations.contains(where: { $0.id == affirmation.id })
    }
    
    private func saveAffirmations() {
        if let encoded = try? JSONEncoder().encode(savedAffirmations) {
            UserDefaults.standard.set(encoded, forKey: affirmationsKey)
        }
    }
    
    private func loadAffirmations() {
        if let data = UserDefaults.standard.data(forKey: affirmationsKey),
           let decoded = try? JSONDecoder().decode([Affirmation].self, from: data) {
            savedAffirmations = decoded
        }
    }
    
    // MARK: - Load All
    private func loadSavedItems() {
        loadQuotes()
        loadAffirmations()
    }
}

