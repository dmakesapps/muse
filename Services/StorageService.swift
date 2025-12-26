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
    
    // MARK: - Streak Tracking
    @Published var streakDays: Int = 1 // Default to 1 for new users
    @Published var lastActiveDate: Date = Date()
    
    /// AI-Generated affirmations from guided chat sessions
    @Published var aiGeneratedAffirmations: [Affirmation] = []
    
    @Published var selectedMusicTrack: BackgroundMusicTrack = .forest {
        didSet {
            saveMusicTrackPreference()
        }
    }
    
    private let quotesKey = "savedQuotes"
    private let affirmationsKey = "savedAffirmations"
    private let aiAffirmationsKey = "aiGeneratedAffirmations"
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
        // Normalize text to ensure proper punctuation for TTS
        let normalizedAffirmation = normalizeAffirmation(affirmation)
        
        // Check by content (text) to prevent duplicates even if UUID differs
        if !savedAffirmations.contains(where: { $0.text == normalizedAffirmation.text }) {
            savedAffirmations.append(normalizedAffirmation)
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
    
    // MARK: - AI Generated Affirmations
    
    /// Save multiple AI-generated affirmations at once
    func saveAIGeneratedAffirmations(_ affirmations: [Affirmation]) {
        for affirmation in affirmations {
            // Normalize text to ensure proper punctuation for TTS
            let normalizedAffirmation = normalizeAffirmation(affirmation)
            
            // Check by content (text) to prevent duplicates
            if !aiGeneratedAffirmations.contains(where: { $0.text == normalizedAffirmation.text }) {
                aiGeneratedAffirmations.append(normalizedAffirmation)
            }
        }
        persistAIAffirmations()
    }
    
    /// Normalize affirmation text to ensure proper punctuation for TTS
    private func normalizeAffirmation(_ affirmation: Affirmation) -> Affirmation {
        let trimmedText = affirmation.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if already ends with sentence-ending punctuation
        let sentenceEndings: Set<Character> = [".", "!", "?", "…"]
        if let lastChar = trimmedText.last, sentenceEndings.contains(lastChar) {
            return Affirmation(id: affirmation.id, text: trimmedText, category: affirmation.category)
        }
        
        // Add period for proper TTS intonation
        return Affirmation(id: affirmation.id, text: trimmedText + ".", category: affirmation.category)
    }
    
    /// Remove an AI-generated affirmation
    func removeAIAffirmation(_ affirmation: Affirmation) {
        aiGeneratedAffirmations.removeAll(where: { $0.text == affirmation.text })
        persistAIAffirmations()
    }
    
    /// Clear all AI-generated affirmations
    func clearAIAffirmations() {
        aiGeneratedAffirmations.removeAll()
        persistAIAffirmations()
    }
    
    private func persistAIAffirmations() {
        if let encoded = try? JSONEncoder().encode(aiGeneratedAffirmations) {
            UserDefaults.standard.set(encoded, forKey: aiAffirmationsKey)
            print("✅ Saved \(aiGeneratedAffirmations.count) AI-generated affirmations")
        }
    }
    
    private func loadAIAffirmations() {
        if let data = UserDefaults.standard.data(forKey: aiAffirmationsKey),
           let decoded = try? JSONDecoder().decode([Affirmation].self, from: data) {
            aiGeneratedAffirmations = decoded
        }
    }
    
    // MARK: - Load All
    private func loadSavedItems() {
        loadQuotes()
        loadAffirmations()
        loadAIAffirmations()
    }
}


// MARK: - Background Music Manager
import AVFoundation
import SwiftUI

class BackgroundMusicManager: ObservableObject {
    static let shared = BackgroundMusicManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    @AppStorage("selectedMusicTrack") var selectedTrack: BackgroundMusicTrack = .none {
        didSet {
            playTrack()
        }
    }
    
    @AppStorage("musicVolume") var volume: Double = 0.5 {
        didSet {
            // Only update player if not currently fading
            audioPlayer?.volume = Float(volume)
        }
    }
    
    // Helper to set volume from float (compatibility)
    func setVolume(_ newVolume: Float) {
        volume = Double(newVolume)
    }
    
    // Track if user is in an immersive session (breathwork or affirmations)
    var isInImmersiveMode = false
    
    // Track if music was playing before going to background
    private var wasPlayingBeforeBackground = false
    
    private init() {
        // Configure audio session for background playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
        
        // Add observers for app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appWillResignActive() {
        // Only pause audio if NOT in immersive mode
        if !isInImmersiveMode {
            wasPlayingBeforeBackground = audioPlayer?.isPlaying ?? false
            audioPlayer?.pause()
        }
    }
    
    @objc private func appDidBecomeActive() {
        // Resume music if it was playing before (and we're not in immersive mode)
        if !isInImmersiveMode && wasPlayingBeforeBackground && selectedTrack != .none {
            audioPlayer?.play()
        }
    }
    
    func playTrack() {
        play(fadeInDuration: 0)
    }
    
    func play(fadeInDuration: TimeInterval = 0) {
        // Stop current player if track changed, otherwise just ensure playing
        if let player = audioPlayer, player.isPlaying {
             if let currentUrl = player.url, 
                let selectedName = selectedTrack.fileName,
                currentUrl.lastPathComponent.contains(selectedName) {
                 return // Already playing correct track
             }
             stop()
        }
        
        guard selectedTrack != .none, let fileName = selectedTrack.fileName else {
            return
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Could not find sound file: \(fileName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            
            if fadeInDuration > 0 {
                audioPlayer?.volume = 0
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                audioPlayer?.setVolume(Float(volume), fadeDuration: fadeInDuration)
            } else {
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            }
        } catch {
            print("Could not create audio player: \(error)")
        }
    }
    
    func stop(fadeOutDuration: TimeInterval = 0) {
        if fadeOutDuration > 0, let player = audioPlayer, player.isPlaying {
            player.setVolume(0, fadeDuration: fadeOutDuration)
            // We can't easily detect when fade finishes with just setVolume, 
            // so we schedule the stop.
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) { [weak self] in
                self?.audioPlayer?.stop()
                self?.audioPlayer = nil
            }
        } else {
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }
    
    func preview(track: BackgroundMusicTrack) {
        // Stop current playback first
        audioPlayer?.stop()
        audioPlayer = nil
        
        guard let fileName = track.fileName else { return }
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = 0 // Don't loop for preview
            
            // Apply volume with track's multiplier for accurate preview
            // Use the current volume setting
            let volumeMultiplier = track.volumeMultiplier
            audioPlayer?.volume = Float(volume) * volumeMultiplier
            
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            // Stop after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                // Only stop if we are still playing the preview (simple check)
                 if self?.audioPlayer?.numberOfLoops == 0 {
                    self?.audioPlayer?.stop()
                    // Revert to selected track if needed, but for now just stop
                }
            }
        } catch {
            print("Failed to preview audio: \(error)")
        }
    }
    
    // Call this when the app starts or view appears to resume music
    func startIfNeeded() {
        if audioPlayer == nil && selectedTrack != .none {
            playTrack()
        } else if let player = audioPlayer, !player.isPlaying {
            player.play()
        }
    }
    
    // Stop temporary preview
    func stopPreview() {
        // If we were previewing, we revert to main track. 
        // For simplicity now, we just play whatever is selected.
    }
}

enum BackgroundMusicTrack: String, CaseIterable, Identifiable {
    case none = "None"
    case forest = "Forest Birds"
    case river = "River"
    case rain = "Rain"
    
    var id: String { self.rawValue }
    
    var fileName: String? {
        switch self {
        case .none: return nil
        case .forest: return "forestbirds"
        case .river: return "river"
        case .rain: return "rain"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .forest: return "leaf.fill"
        case .river: return "water.waves"
        case .rain: return "cloud.rain.fill"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "No background music"
        case .forest: return "Peaceful forest sounds"
        case .river: return "Flowing river water"
        case .rain: return "Gentle rain ambiance"
        }
    }
    
    /// Volume multiplier to normalize loudness across tracks
    var volumeMultiplier: Float {
        switch self {
        case .none: return 0.0
        default: return 0.8 // Default for others
        }
    }
}
