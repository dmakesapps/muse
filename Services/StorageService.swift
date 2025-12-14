import Foundation
import WidgetKit

// MARK: - Shared Data Service for Widget Access
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

class StorageService: ObservableObject {
    static let shared = StorageService()
    
    @Published var savedQuotes: [Quote] = []
    
    @Published var savedAffirmations: [Affirmation] = []
    
    @Published var selectedMusicTrack: BackgroundMusicTrack = .djTaye {
        didSet {
            saveMusicTrackPreference()
        }
    }
    
    private let quotesKey = "savedQuotes"
    private let affirmationsKey = "savedAffirmations"
    private let musicTrackKey = "selectedMusicTrack"
    
    // App Group UserDefaults for widget sharing
    private var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: SharedDataService.appGroupIdentifier)
    }
    
    init() {
        loadSavedItems()
        loadMusicTrackPreference()
    }
    
    // MARK: - Music Track Preference
    private func saveMusicTrackPreference() {
        UserDefaults.standard.set(selectedMusicTrack.rawValue, forKey: musicTrackKey)
    }
    
    private func loadMusicTrackPreference() {
        if let savedValue = UserDefaults.standard.string(forKey: musicTrackKey),
           let track = BackgroundMusicTrack(rawValue: savedValue) {
            selectedMusicTrack = track
            BackgroundMusicManager.shared.selectedTrack = track
        }
    }
    
    // MARK: - Quotes
    func saveQuote(_ quote: Quote) {
        // Check by content (text + author) to prevent duplicates even if UUID differs
        if !savedQuotes.contains(where: { $0.text == quote.text && $0.author == quote.author }) {
            savedQuotes.append(quote)
            saveQuotes()
        }
    }
    
    func removeQuote(_ quote: Quote) {
        // Remove by content (text + author) to handle cases where UUID differs
        savedQuotes.removeAll(where: { $0.text == quote.text && $0.author == quote.author })
        saveQuotes()
    }
    
    func isQuoteSaved(_ quote: Quote) -> Bool {
        // Check by content (text + author) to match how we save
        savedQuotes.contains(where: { $0.text == quote.text && $0.author == quote.author })
    }
    
    private func saveQuotes() {
        if let encoded = try? JSONEncoder().encode(savedQuotes) {
            UserDefaults.standard.set(encoded, forKey: quotesKey)
            // Also save to App Group for widget access
            sharedUserDefaults?.set(encoded, forKey: quotesKey)
            // Force widget refresh by updating timeline
            WidgetCenter.shared.reloadTimelines(ofKind: "QuoteWidget")
            print("✅ Saved \(savedQuotes.count) quotes to App Group and reloaded widget")
        }
    }
    
    private func loadQuotes() {
        // Try to load from App Group first (most up-to-date)
        if let sharedData = sharedUserDefaults?.data(forKey: quotesKey),
           let decoded = try? JSONDecoder().decode([Quote].self, from: sharedData) {
            savedQuotes = decoded
            // Sync back to regular UserDefaults for backward compatibility
            UserDefaults.standard.set(sharedData, forKey: quotesKey)
        } else if let data = UserDefaults.standard.data(forKey: quotesKey),
                  let decoded = try? JSONDecoder().decode([Quote].self, from: data) {
            // Load from regular UserDefaults and sync to App Group
            savedQuotes = decoded
            sharedUserDefaults?.set(data, forKey: quotesKey)
        }
    }
    
    // MARK: - Affirmations
    func saveAffirmation(_ affirmation: Affirmation) {
        // Check by content (text) to prevent duplicates even if UUID differs
        if !savedAffirmations.contains(where: { $0.text == affirmation.text }) {
            savedAffirmations.append(affirmation)
            saveAffirmations()
        }
    }
    
    func removeAffirmation(_ affirmation: Affirmation) {
        // Remove by content (text) to handle cases where UUID differs
        savedAffirmations.removeAll(where: { $0.text == affirmation.text })
        saveAffirmations()
    }
    
    func isAffirmationSaved(_ affirmation: Affirmation) -> Bool {
        // Check by content (text) to match how we save
        savedAffirmations.contains(where: { $0.text == affirmation.text })
    }
    
    private func saveAffirmations() {
        if let encoded = try? JSONEncoder().encode(savedAffirmations) {
            UserDefaults.standard.set(encoded, forKey: affirmationsKey)
            // Also save to App Group for widget access
            sharedUserDefaults?.set(encoded, forKey: affirmationsKey)
            // Force widget refresh by updating timeline
            WidgetCenter.shared.reloadTimelines(ofKind: "AffirmationWidget")
            print("✅ Saved \(savedAffirmations.count) affirmations to App Group and reloaded widget")
        }
    }
    
    private func loadAffirmations() {
        // Try to load from App Group first (most up-to-date)
        if let sharedData = sharedUserDefaults?.data(forKey: affirmationsKey),
           let decoded = try? JSONDecoder().decode([Affirmation].self, from: sharedData) {
            savedAffirmations = decoded
            // Sync back to regular UserDefaults for backward compatibility
            UserDefaults.standard.set(sharedData, forKey: affirmationsKey)
        } else if let data = UserDefaults.standard.data(forKey: affirmationsKey),
                  let decoded = try? JSONDecoder().decode([Affirmation].self, from: data) {
            // Load from regular UserDefaults and sync to App Group
            savedAffirmations = decoded
            sharedUserDefaults?.set(data, forKey: affirmationsKey)
        }
    }
    
    // MARK: - Load All
    private func loadSavedItems() {
        loadQuotes()
        loadAffirmations()
    }
}

