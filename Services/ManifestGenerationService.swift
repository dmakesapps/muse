import Foundation
import AVFoundation

/// A temporary service to generate joined MP3s with pauses for Manifestation scripts
class ManifestAudioGenerator: ObservableObject {
    static let shared = ManifestAudioGenerator()
    
    @Published var isGenerating = false
    @Published var progress = ""
    private let fileManager = FileManager.default
    
    // Config
    private let apiKey = OpenAIConfig.apiKey
    private let model = "tts-1-hd"
    private let voice = "nova"
    
    /// The script text with pauses
    private let script = """
    Welcome. In these next five minutes, we'll align with your deepest desires.
    (Pause: 2)
    Before we begin, just settle your body wherever you are.
    (Pause: 3)
    Take a slow, deep breath in through your nose, filling your lungs completely.
    (Pause: 4)
    And exhale slowly through your mouth, releasing any tension you might be holding.
    (Pause: 5)
    Feel your body relaxing, becoming present, right here, right now, in this powerful moment.
    (Pause: 6)
    Now, bring to mind one clear, desired outcome.
    (Pause: 2)
    Don’t concern yourself with the 'how' or the 'when' right now.
    (Pause: 3)
    Simply focus on 'what' you truly want to experience.
    (Pause: 4)
    What is that wonderful reality you wish to embody?
    (Pause: 5)
    Allow a clear image or a pure knowing of it to form in your mind.
    (Pause: 5)
    Here is the secret: Begin to feel it as if it is already accomplished.
    (Pause: 4)
    What emotions would flood through you if this desire were a present reality, right now?
    (Pause: 2)
    Is it joy? Freedom? Deep peace? Abundance? Love?
    (Pause: 6)
    Allow those feelings to wash over you.
    (Pause: 2)
    Don't just think about them; truly experience them.
    (Pause: 4)
    Feel them in every cell of your being, from the top of your head to the tips of your toes.
    (Pause: 7)
    Imagine that wonderful feeling is already real, here, now. Live from this end.
    (Pause: 10)
    Breathe into that feeling. Let it expand.
    (Pause: 4)
    You are not waiting for this feeling; you are actively generating it from within your own being.
    (Pause: 8)
    Hold onto this profound sense of the wish fulfilled.
    (Pause: 5)
    See it, not in your future, but as your present experience.
    (Pause: 7)
    Take one last deep breath, fully embodying this feeling of completion and deep gratitude.
    (Pause: 5)
    As you exhale, silently affirm within your heart: "I am grateful this is done."
    (Pause: 5)
    Now, gently bring your awareness back to your surroundings.
    (Pause: 2)
    Carry this feeling of completion and fulfillment with you throughout your day.
    (Pause: 4)
    Trust the invisible intelligence to arrange the 'how'.
    (Pause: 2)
    You are a powerful creator.
    """
    
    func generate() {
        debugLog("⚡️ ADMIN GENERATOR: Generate button pressed!")
        
        guard !apiKey.isEmpty else {
            debugLog("❌ ADMIN GENERATOR: No API Key found!")
            progress = "Error: API Key missing"
            return
        }
        
        isGenerating = true
        progress = "Starting generation..."
        debugLog("⚡️ ADMIN GENERATOR: Starting generation loop...")
        
        Task {
            do {
                // 1. Parse Script
                let segments = parseScript(script)
                debugLog("⚡️ ADMIN GENERATOR: Parsed \(segments.count) segments.")
                var audioFiles: [URL] = []
                
                // 2. Process each segment
                for (index, segment) in segments.enumerated() {
                    let tempURL = fileManager.temporaryDirectory.appendingPathComponent("segment_\(index).mp3")
                    
                    if let text = segment.text {
                        progress = "Generating segment \(index + 1)/\(segments.count)..."
                        // Call OpenAI
                        try await downloadTTS(text: text, to: tempURL)
                        audioFiles.append(tempURL)
                    } else if let pauseDuration = segment.pause {
                        progress = "Adding silence: \(pauseDuration)s..."
                        // Create silent MP3
                        // NOTE: For simplicity in this swift implementation, we will perform silence stitching
                        // via AVComposition later. For now, we just track the duration.
                        // However, to keep it simple: We will just download everything, then we need to stitch.
                    }
                }
                
                // 3. Stitch Files (This is the tricky part in pure Swift without ffmpeg)
                // Actually, the easiest way to add 'silence' in a composition involves just inserting the next clip later.
                
                progress = "Stitching audio..."
                let finalURL = try await stitchAudio(segments: segments)
                
                progress = "✅ DONE! Saved to: \(finalURL.path)"
                debugLog("✅ MANIFEST AUDIO SAVED TO: \(finalURL.path)")
                isGenerating = false
                
            } catch {
                progress = "Error: \(error.localizedDescription)"
                isGenerating = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private struct Segment {
        var text: String?
        var pause: Double?
    }
    
    private func parseScript(_ raw: String) -> [Segment] {
        // Simple line parser
        let lines = raw.components(separatedBy: .newlines)
        var parsed: [Segment] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if trimmed.starts(with: "(Pause:"), let endIdx = trimmed.firstIndex(of: ")") {
                // Extract number
                let numStr = trimmed.dropFirst(7).prefix(upTo: endIdx).trimmingCharacters(in: .whitespaces)
                if let secs = Double(numStr) {
                    parsed.append(Segment(pause: secs))
                }
            } else {
                parsed.append(Segment(text: trimmed))
            }
        }
        return parsed
    }
    
    private func downloadTTS(text: String, to url: URL) async throws {
        let endpoint = "https://api.openai.com/v1/audio/speech"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "input": text.replacingOccurrences(of: "\n", with: " "), // Sanitize newlines
            "voice": voice,
            "speed": 0.85, // Slower for better clarity
            "response_format": "mp3"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "OpenAI", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error"])
        }
        
        try data.write(to: url)
    }
    
    private func stitchAudio(segments: [Segment]) async throws -> URL {
        let composition = AVMutableComposition()
        guard let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "Audio", code: 2, userInfo: nil)
        }
        
        var cursor = CMTime.zero
        
        for (i, segment) in segments.enumerated() {
            if let text = segment.text {
                // We need to download this segment first
                let tempURL = fileManager.temporaryDirectory.appendingPathComponent("seg_\(i).mp3")
                try await downloadTTS(text: text, to: tempURL)
                
                let asset = AVURLAsset(url: tempURL)
                if let assetTrack = try? await asset.loadTracks(withMediaType: .audio).first {
                    
                    // PRE-PAD: 0.1s silence before to prevent attack clipping
                    let prePad = CMTime(seconds: 0.1, preferredTimescale: 600)
                    track.insertEmptyTimeRange(CMTimeRange(start: cursor, duration: prePad))
                    cursor = CMTimeAdd(cursor, prePad)
                    
                    let duration = try await asset.load(.duration)
                    try track.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: assetTrack, at: cursor)
                    cursor = CMTimeAdd(cursor, duration)
                    
                    // POST-PAD: 0.25s silence after to prevent decay clipping
                    let postPad = CMTime(seconds: 0.25, preferredTimescale: 600)
                    track.insertEmptyTimeRange(CMTimeRange(start: cursor, duration: postPad))
                    cursor = CMTimeAdd(cursor, postPad)
                }
                
            } else if let pause = segment.pause {
                // Add silence by simply moving the cursor
                let duration = CMTime(seconds: pause, preferredTimescale: 600)
                track.insertEmptyTimeRange(CMTimeRange(start: cursor, duration: duration))
                cursor = CMTimeAdd(cursor, duration)
            }
        }
        
        // Export
        let exportURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("manifest_5min.m4a") // Save as m4a/mp4 container
        
        // Delete if exists
        try? fileManager.removeItem(at: exportURL)
        
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "Export", code: 3, userInfo: nil)
        }
        
        exporter.outputURL = exportURL
        exporter.outputFileType = .m4a
        
        await exporter.export()
        
        if exporter.status == .completed {
            return exportURL
        } else {
            throw exporter.error ?? NSError(domain: "Export", code: 4, userInfo: nil)
        }
    }
}
