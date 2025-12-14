import Foundation
import AVFoundation

/// Service for text-to-speech using OpenAI's TTS API
/// Provides high-quality, natural-sounding voices for affirmations
class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()
    
    // MARK: - Configuration
    // Add your OpenAI API key here or load from environment/config
    // Get your key at: https://platform.openai.com/api-keys
    private let apiKey = OpenAIConfig.apiKey
    private let apiEndpoint = "https://api.openai.com/v1/audio/speech"
    
    /// Available voices: alloy, echo, fable, onyx, nova, shimmer
    /// - nova: Warm, expressive female voice (great for affirmations)
    /// - shimmer: Soft, gentle female voice (also great for affirmations)
    private let voice = "nova"
    
    /// Model: tts-1 (faster) or tts-1-hd (higher quality)
    private let model = "tts-1-hd"
    
    /// Speed: 0.25 to 4.0 (1.0 is normal)
    /// Slower is better for affirmations - gives time to absorb
    private let speed: Double = 0.9
    
    // MARK: - Published State
    @Published var isSpeaking = false
    @Published var isGenerating = false
    @Published var currentlyPlayingText: String?
    @Published var error: String?
    
    // MARK: - Audio Player
    private var audioPlayer: AVAudioPlayer?
    private var onSpeechComplete: (() -> Void)?
    private var isCancelled = false  // Flag to cancel pending operations
    
    // MARK: - Cache
    private let cacheDirectory: URL
    private var cachedAudioURLs: [String: URL] = [:]
    
    // MARK: - Initialization
    private override init() {
        // Create cache directory for audio files
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachePath.appendingPathComponent("OpenAITTSCache", isDirectory: true)
        
        super.init()
        
        // Ensure cache directory exists
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Load cached file references
        loadCachedReferences()
        
        // Setup audio session
        setupAudioSession()
    }
    
    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        } catch {
            print("⚠️ SpeechService: Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Speaking
    
    /// Speak the given text using OpenAI TTS
    /// - Parameters:
    ///   - text: The text to speak
    ///   - completion: Called when speech finishes
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        print("🎙️ SpeechService: speak() called with text: \(text.prefix(50))...")
        
        // Reset cancel flag for new speech
        isCancelled = false
        
        // Stop any current playback (but don't set isCancelled since we're starting new speech)
        if let player = audioPlayer {
            player.stop()
        }
        audioPlayer = nil
        
        onSpeechComplete = completion
        currentlyPlayingText = text
        
        // Check cache first
        let cacheKey = generateCacheKey(for: text)
        if let cachedURL = cachedAudioURLs[cacheKey], FileManager.default.fileExists(atPath: cachedURL.path) {
            print("✅ SpeechService: Using cached audio for: \(text.prefix(30))...")
            playAudio(from: cachedURL)
            return
        }
        
        print("🌐 SpeechService: No cache found, calling OpenAI API...")
        
        // Generate new audio
        Task {
            await generateAndPlay(text: text, cacheKey: cacheKey)
        }
    }
    
    /// Generate audio from OpenAI and play it
    private func generateAndPlay(text: String, cacheKey: String) async {
        print("🔄 SpeechService: generateAndPlay() starting...")
        
        // Check if cancelled before starting
        guard !isCancelled else {
            print("🛑 SpeechService: Cancelled before generation started")
            return
        }
        
        await MainActor.run {
            isGenerating = true
            error = nil
        }
        
        do {
            let audioURL = try await generateSpeech(for: text, cacheKey: cacheKey)
            
            // Check if cancelled after generation (before playing)
            guard !isCancelled else {
                print("🛑 SpeechService: Cancelled after generation, not playing")
                await MainActor.run {
                    isGenerating = false
                }
                return
            }
            
            print("✅ SpeechService: Audio generated successfully, playing...")
            
            await MainActor.run {
                isGenerating = false
                playAudio(from: audioURL)
            }
        } catch {
            print("❌ SpeechService: Failed to generate speech: \(error)")
            print("❌ SpeechService: Error details: \(error.localizedDescription)")
            await MainActor.run {
                isGenerating = false
                self.error = error.localizedDescription
                isSpeaking = false
                currentlyPlayingText = nil
                onSpeechComplete?()
                onSpeechComplete = nil
            }
        }
    }
    
    /// Generate speech using OpenAI TTS API
    private func generateSpeech(for text: String, cacheKey: String) async throws -> URL {
        print("📡 SpeechService: Calling OpenAI API...")
        
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 second timeout
        
        let body: [String: Any] = [
            "model": model,
            "input": text,
            "voice": voice,
            "speed": speed,
            "response_format": "mp3"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📡 SpeechService: Request body: model=\(model), voice=\(voice), speed=\(speed)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📡 SpeechService: Received response, data size: \(data.count) bytes")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ SpeechService: Invalid response type")
            throw SpeechError.invalidResponse
        }
        
        print("📡 SpeechService: HTTP status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ SpeechService: API error: \(errorMessage)")
            throw SpeechError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Save to cache
        let audioURL = cacheDirectory.appendingPathComponent("\(cacheKey).mp3")
        try data.write(to: audioURL)
        
        // Update cache reference
        cachedAudioURLs[cacheKey] = audioURL
        saveCachedReferences()
        
        print("✅ SpeechService: Generated and cached audio for: \(text.prefix(30))...")
        return audioURL
    }
    
    /// Play audio from URL
    private func playAudio(from url: URL) {
        print("🔊 SpeechService: playAudio() called with URL: \(url.lastPathComponent)")
        
        // Check if cancelled
        guard !isCancelled else {
            print("🛑 SpeechService: Cancelled, not playing audio")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 SpeechService: Audio session activated")
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            // Double-check cancellation right before playing
            guard !isCancelled else {
                print("🛑 SpeechService: Cancelled right before play")
                audioPlayer = nil
                return
            }
            
            let success = audioPlayer?.play() ?? false
            print("🔊 SpeechService: play() returned: \(success), duration: \(audioPlayer?.duration ?? 0) seconds")
            
            isSpeaking = true
            
        } catch {
            print("❌ SpeechService: Audio playback failed: \(error)")
            self.error = "Playback failed: \(error.localizedDescription)"
            isSpeaking = false
            currentlyPlayingText = nil
            onSpeechComplete?()
            onSpeechComplete = nil
        }
    }
    
    /// Stop current speech and cancel any pending operations
    func stopSpeaking() {
        print("🛑 SpeechService: stopSpeaking() called")
        
        // Set cancel flag to prevent pending async operations from playing
        isCancelled = true
        
        // Stop audio player
        if let player = audioPlayer {
            player.stop()
            print("🛑 SpeechService: Audio player stopped")
        }
        audioPlayer = nil
        
        // Reset state
        isSpeaking = false
        isGenerating = false
        currentlyPlayingText = nil
        onSpeechComplete = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Cache Management
    
    private func generateCacheKey(for text: String) -> String {
        // Include voice and speed in cache key so regeneration happens if settings change
        let settingsHash = "\(voice)_\(speed)"
        let combined = text + settingsHash
        
        // Create a simple hash for the filename
        var hash: UInt64 = 5381
        for char in combined.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }
        return String(hash)
    }
    
    private func saveCachedReferences() {
        let references = cachedAudioURLs.mapValues { $0.lastPathComponent }
        if let data = try? JSONEncoder().encode(references) {
            let refURL = cacheDirectory.appendingPathComponent("cache_references.json")
            try? data.write(to: refURL)
        }
    }
    
    private func loadCachedReferences() {
        let refURL = cacheDirectory.appendingPathComponent("cache_references.json")
        guard let data = try? Data(contentsOf: refURL),
              let references = try? JSONDecoder().decode([String: String].self, from: data) else {
            return
        }
        
        cachedAudioURLs = references.compactMapValues { filename in
            let url = cacheDirectory.appendingPathComponent(filename)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        
        print("✅ SpeechService: Loaded \(cachedAudioURLs.count) cached audio files")
    }
    
    /// Clear all cached audio files
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        cachedAudioURLs.removeAll()
        print("✅ SpeechService: Cache cleared")
    }
    
    /// Check if audio is cached for the given text
    func isCached(_ text: String) -> Bool {
        let cacheKey = generateCacheKey(for: text)
        guard let url = cachedAudioURLs[cacheKey] else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // MARK: - Errors
    enum SpeechError: LocalizedError {
        case invalidResponse
        case apiError(statusCode: Int, message: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from OpenAI"
            case .apiError(let statusCode, let message):
                return "API error (\(statusCode)): \(message)"
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension SpeechService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentlyPlayingText = nil
            self.onSpeechComplete?()
            self.onSpeechComplete = nil
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentlyPlayingText = nil
            if let error = error {
                self.error = "Decode error: \(error.localizedDescription)"
            }
            self.onSpeechComplete?()
            self.onSpeechComplete = nil
        }
    }
}
