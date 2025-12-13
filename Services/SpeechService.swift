import Foundation
import AVFoundation

class SpeechService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var currentDelegate: SpeechDelegate?
    
    @Published var currentWordIndex: Int = -1
    @Published var totalWords: Int = 0
    
    // Default voice - using enhanced/premium quality voice
    private var defaultVoice: AVSpeechSynthesisVoice? {
        // Get all available English voices
        let englishVoices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        
        // Priority order for best-sounding voices:
        // 1. Enhanced voices (most natural)
        // 2. Premium voices
        // 3. Samantha (generally sounds good)
        // 4. Alex (good quality)
        // 5. Any other English voice
        
        // Try enhanced voices first (best quality)
        if let enhanced = englishVoices.first(where: { 
            $0.identifier.lowercased().contains("enhanced") 
        }) {
            return enhanced
        }
        
        // Try premium voices
        if let premium = englishVoices.first(where: { 
            $0.identifier.lowercased().contains("premium") 
        }) {
            return premium
        }
        
        // Try Samantha (usually sounds natural)
        if let samantha = englishVoices.first(where: { 
            $0.name.contains("Samantha") || $0.identifier.contains("Samantha")
        }) {
            return samantha
        }
        
        // Try Alex (good quality)
        if let alex = englishVoices.first(where: { 
            $0.name.contains("Alex") || $0.identifier.contains("Alex")
        }) {
            return alex
        }
        
        // Try any voice that's not the default robotic one
        if let nonDefault = englishVoices.first(where: { 
            !$0.identifier.contains("compact") && 
            !$0.name.contains("Compact")
        }) {
            return nonDefault
        }
        
        // Final fallback: Any English voice
        return englishVoices.first
    }
    
    func speak(_ text: String, wordCallback: ((Int) -> Void)? = nil, completion: (() -> Void)? = nil) {
        // Stop any current speech
        stop()
        
        // Count words for tracking
        let words = text.split(separator: " ").map { String($0) }
        totalWords = words.count
        currentWordIndex = -1
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure voice settings for natural, clear speech
        utterance.voice = defaultVoice
        utterance.rate = 0.48 // Optimal rate for clarity and naturalness (0.0 to 1.0)
        utterance.pitchMultiplier = 0.98 // Slightly lower pitch for more natural sound
        utterance.volume = 1.0 // Full volume
        
        // Set up delegate with word tracking
        let delegate = SpeechDelegate(
            words: words,
            wordCallback: { [weak self] index in
                DispatchQueue.main.async {
                    self?.currentWordIndex = index
                    wordCallback?(index)
                }
            },
            completion: {
                DispatchQueue.main.async {
                    completion?()
                }
            }
        )
        currentDelegate = delegate
        synthesizer.delegate = delegate
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        currentWordIndex = -1
        totalWords = 0
        currentDelegate = nil
    }
    
    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }
}

// Helper class to handle speech completion and word boundaries
private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let words: [String]
    let wordCallback: (Int) -> Void
    let completion: () -> Void
    private var currentWordIndex = 0
    private var utteranceStartTime: Date?
    
    init(words: [String], wordCallback: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        self.words = words
        self.wordCallback = wordCallback
        self.completion = completion
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        utteranceStartTime = Date()
        currentWordIndex = 0
        // Start with first word
        wordCallback(0)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Get the text that will be spoken up to this point
        let fullText = utterance.speechString
        let rangeEnd = characterRange.location + characterRange.length
        let spokenText = (fullText as NSString).substring(to: min(rangeEnd, fullText.count))
        
        // Split into words and count
        let spokenWordsArray = spokenText.trimmingCharacters(in: .whitespaces).split(separator: " ").filter { !$0.isEmpty }
        let spokenWordCount = spokenWordsArray.count
        
        // Update word index if we've moved to a new word
        // Make sure we don't skip any words - highlight every word sequentially
        if spokenWordCount > 0 && spokenWordCount <= words.count {
            let newWordIndex = min(spokenWordCount - 1, words.count - 1)
            
            // Highlight all words from currentWordIndex + 1 up to newWordIndex
            // This ensures we don't skip any words
            if newWordIndex > currentWordIndex {
                for index in (currentWordIndex + 1)...newWordIndex {
                    if index < words.count {
                        currentWordIndex = index
                        wordCallback(index)
                    }
                }
            } else if newWordIndex == currentWordIndex && currentWordIndex < words.count - 1 {
                // Sometimes the same word index is reported multiple times
                // Only update if we haven't reached the end
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Ensure we've highlighted the last word
        if currentWordIndex < words.count - 1 {
            wordCallback(words.count - 1)
        }
        completion()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        completion()
    }
}

