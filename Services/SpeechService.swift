import Foundation
import AVFoundation

/// Service for text-to-speech using OpenAI's TTS API
/// Provides high-quality, natural-sounding voices for affirmations
class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()
    
    // MARK: - Configuration
    // API key is stored in APIKeys.swift (gitignored for security)
    private var apiKey: String {
        return APIKeys.openAI
    }
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
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var onSpeechComplete: (() -> Void)?
    private var currentSpeechId: UUID? // Track current speech request to handle cancellation
    
    // MARK: - Cache
    private let cacheDirectory: URL
    private var cachedAudioURLs: [String: URL] = [:]
    
    // MARK: - Initialization
    private override init() {
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachePath.appendingPathComponent("OpenAITTSCache", isDirectory: true)
        
        super.init()
        
        // Ensure cache directory exists (don't clear it - we want persistent caching!)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Load previously cached audio references from disk
        loadCachedReferences()
    }
    
    // MARK: - Audio Session
    private func ensureAudioSessionActive() {
        do {
            // Use .playback category with .mixWithOthers to blend with background music
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ SpeechService: Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Speaking
    
    /// Speak the given text using OpenAI TTS
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        print("🎙️ SpeechService: speak() called with text: \(text.prefix(50))...")
        
        // Normalize text for TTS - add period if no ending punctuation
        let normalizedText = normalizeForSpeech(text)
        print("🎙️ SpeechService: Normalized text for TTS: \(normalizedText)")
        
        // Generate unique ID for this speech request
        let speechId = UUID()
        currentSpeechId = speechId
        
        // Stop any current playback
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Reset state
        isSpeaking = false
        isGenerating = false
        error = nil
        
        onSpeechComplete = completion
        currentlyPlayingText = text // Keep original text for display
        
        // Check cache first
        let cacheKey = generateCacheKey(for: normalizedText)
        if let cachedURL = cachedAudioURLs[cacheKey], FileManager.default.fileExists(atPath: cachedURL.path) {
            print("✅ SpeechService: Using cached audio for: \(text.prefix(30))...")
            playAudio(from: cachedURL, speechId: speechId)
            return
        }
        
        print("🌐 SpeechService: No cache found, calling OpenAI API...")
        
        // Generate new audio
        Task { @MainActor in
            await generateAndPlay(text: normalizedText, cacheKey: cacheKey, speechId: speechId)
        }
    }
    
    /// Prefetch audio for upcoming affirmations
    func prefetch(_ text: String) {
        let normalizedText = normalizeForSpeech(text)
        let cacheKey = generateCacheKey(for: normalizedText)
        
        // Only generate if not already cached
        guard cachedAudioURLs[cacheKey] == nil || !FileManager.default.fileExists(atPath: cachedAudioURLs[cacheKey]!.path) else {
            return
        }
        
        Task {
            try? await generateSpeech(for: normalizedText, cacheKey: cacheKey)
        }
    }
    
    /// Normalize text for speech - ensures proper sentence intonation
    private func normalizeForSpeech(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if text already ends with sentence-ending punctuation
        let sentenceEndings: [Character] = [".", "!", "?", "…"]
        if let lastChar = trimmed.last, sentenceEndings.contains(lastChar) {
            return trimmed
        }
        
        // Add period for proper sentence intonation
        return trimmed + "."
    }
    
    /// Generate audio from OpenAI and play it
    @MainActor
    private func generateAndPlay(text: String, cacheKey: String, speechId: UUID) async {
        // Check if this request is still current
        guard currentSpeechId == speechId else {
            print("🛑 SpeechService: Request \(speechId) cancelled (new request started)")
            return
        }
        
        isGenerating = true
        
        do {
            let audioURL = try await generateSpeech(for: text, cacheKey: cacheKey)
            
            // Check again if this request is still current
            guard currentSpeechId == speechId else {
                print("🛑 SpeechService: Request \(speechId) cancelled after generation")
                isGenerating = false
                return
            }
            
            print("✅ SpeechService: Audio generated successfully, playing...")
            isGenerating = false
            playAudio(from: audioURL, speechId: speechId)
            
        } catch {
            print("❌ SpeechService: Failed to generate speech: \(error)")
            
            // Only update state if this is still the current request
            guard currentSpeechId == speechId else { return }
            
            isGenerating = false
            self.error = error.localizedDescription
            
            // FALLBACK: Use iOS native speech synthesis
            print("🔄 SpeechService: Falling back to iOS native speech...")
            speakWithNativeSynthesis(text, speechId: speechId)
        }
    }
    
    /// Fallback: Use iOS native speech synthesis when OpenAI fails
    private func speakWithNativeSynthesis(_ text: String, speechId: UUID) {
        speechSynthesizer?.stopSpeaking(at: .immediate)

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        speechSynthesizer = synthesizer

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slower for affirmations
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    /// Generate speech using OpenAI TTS API
    private func generateSpeech(for text: String, cacheKey: String) async throws -> URL {
        print("📡 SpeechService: Calling OpenAI API...")
        
        guard !apiKey.isEmpty && apiKey != "your-api-key-here" else {
            throw SpeechError.apiError(statusCode: 0, message: "OpenAI API key not configured")
        }
        
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
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
    private func playAudio(from url: URL, speechId: UUID) {
        print("🔊 SpeechService: playAudio() called with URL: \(url.lastPathComponent)")
        
        // Check if this request is still current
        guard currentSpeechId == speechId else {
            print("🛑 SpeechService: Request \(speechId) cancelled, not playing")
            return
        }
        
        // Ensure audio session is active before playing
        ensureAudioSessionActive()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            
            // Final check before playing
            guard currentSpeechId == speechId else {
                print("🛑 SpeechService: Request \(speechId) cancelled right before play")
                audioPlayer = nil
                return
            }
            
            let success = audioPlayer?.play() ?? false
            print("🔊 SpeechService: play() returned: \(success), duration: \(audioPlayer?.duration ?? 0) seconds")
            
            if success {
                isSpeaking = true
            } else {
                // Retry once after a short delay
                print("⚠️ SpeechService: play() returned false, retrying...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    guard let self = self, self.currentSpeechId == speechId else { return }
                    
                    let retrySuccess = self.audioPlayer?.play() ?? false
                    print("🔊 SpeechService: Retry play() returned: \(retrySuccess)")
                    
                    if retrySuccess {
                        self.isSpeaking = true
                    } else {
                        // Give up and call completion
                        self.finishSpeech()
                    }
                }
            }
            
        } catch {
            print("❌ SpeechService: Audio playback failed: \(error)")
            self.error = "Playback failed: \(error.localizedDescription)"
            finishSpeech()
        }
    }
    
    /// Clean up after speech finishes
    private func finishSpeech() {
        isSpeaking = false
        currentlyPlayingText = nil
        speechSynthesizer = nil
        
        let callback = onSpeechComplete
        onSpeechComplete = nil
        callback?()
    }
    
    /// Stop current speech and cancel any pending operations
    func stopSpeaking() {
        print("🛑 SpeechService: stopSpeaking() called")
        
        // Invalidate current speech request
        currentSpeechId = nil
        
        // Stop audio player
        audioPlayer?.stop()
        audioPlayer = nil
        speechSynthesizer?.stopSpeaking(at: .immediate)
        speechSynthesizer = nil
        
        // Reset state
        isSpeaking = false
        isGenerating = false
        currentlyPlayingText = nil
        onSpeechComplete = nil
    }
    
    // MARK: - Cache Management
    
    private func generateCacheKey(for text: String) -> String {
        let settingsHash = "\(voice)_\(speed)_\(model)"
        let combined = text + settingsHash
        
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
        print("🔊 SpeechService: audioPlayerDidFinishPlaying, success: \(flag)")
        DispatchQueue.main.async {
            self.finishSpeech()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ SpeechService: audioPlayerDecodeErrorDidOccur: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async {
            if let error = error {
                self.error = "Decode error: \(error.localizedDescription)"
            }
            self.finishSpeech()
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("🔊 SpeechService: speechSynthesizer didFinish")
        DispatchQueue.main.async {
            self.finishSpeech()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("🔊 SpeechService: speechSynthesizer didCancel")
    }
}
