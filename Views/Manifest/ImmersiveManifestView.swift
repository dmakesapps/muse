import SwiftUI
import AVFoundation
import Combine

struct ImmersiveManifestView: View {
    @Environment(\.dismiss) var dismiss
    
    // Config
    let sessionName: String = "5 Minute Manifestation"
    let audioFileName: String = "manifest_5min"
    
    // State properties located below with `showVolumeSettings`
    
    // Script Content
    let scriptSegments: [String] = [
        "Welcome. In these next five minutes, we'll align with your deepest desires.",
        "Before we begin, just settle your body wherever you are.",
        "Take a slow, deep breath in through your nose, filling your lungs completely.",
        "And exhale slowly through your mouth, releasing any tension you might be holding.",
        "Feel your body relaxing, becoming present, right here, right now, in this powerful moment.",
        "Now, bring to mind one clear, desired outcome.",
        "Don’t concern yourself with the 'how' or the 'when' right now.",
        "Simply focus on 'what' you truly want to experience.",
        "What is that wonderful reality you wish to embody?",
        "Allow a clear image or a pure knowing of it to form in your mind.",
        "Here is the secret: Begin to feel it as if it is already accomplished.",
        "What emotions would flood through you if this desire were a present reality, right now?",
        "Is it joy? Freedom? Deep peace? Abundance? Love?",
        "Allow those feelings to wash over you.",
        "Don't just think about them; truly experience them.",
        "Feel them in every cell of your being, from the top of your head to the tips of your toes.",
        "Imagine that wonderful feeling is already real, here, now. Live from this end.",
        "Breathe into that feeling. Let it expand.",
        "You are not waiting for this feeling; you are actively generating it from within your own being.",
        "Hold onto this profound sense of the wish fulfilled.",
        "See it, not in your future, but as your present experience.",
        "Take one last deep breath, fully embodying this feeling of completion and deep gratitude.",
        "As you exhale, silently affirm within your heart: 'I am grateful this is done.'",
        "Now, gently bring your awareness back to your surroundings.",
        "Carry this feeling of completion and fulfillment with you throughout your day.",
        "Trust the invisible intelligence to arrange the 'how'.",
        "You are a powerful creator."
    ]
    
    // Pauses (in seconds) corresponding to each segment above.
    // Extracted from ManifestGenerationService.swift source script.
    let segmentPauses: [Double] = [
        2, // Welcome...
        3, // Before we begin...
        4, // Take a slow...
        5, // And exhale...
        6, // Feel your body...
        2, // Now, bring...
        3, // Don't concern...
        4, // Simply focus...
        5, // What is that...
        5, // Allow a clear...
        4, // Here is the secret...
        2, // What emotions...
        6, // Is it joy...
        2, // Allow those...
        4, // Don't just think...
        7, // Feel them...
        10, // Imagine that...
        4, // Breathe into...
        8, // You are not...
        5, // Hold onto...
        7, // See it...
        5, // Take one last...
        5, // As you exhale...
        2, // Now, gently...
        4, // Carry this feeling...
        2, // Trust the invisible...
        0  // You are a powerful creator (End)
    ]
    
    // State
    @StateObject private var audioPlayer = ManifestPlayer()
    @State private var showControls = true
    @State private var showVolumeSettings = false
    @State private var contentOffset: CGFloat = 0

   
    var body: some View {
        ZStack {
            // 1. Static Background
            Image("backgroundjungle2")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // 2. Dark Overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // 3. Main Content
            VStack {
                // Header (Close Button)
                if showControls {
                    HStack {
                        Spacer()
                        Button(action: {
                            audioPlayer.stop()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 64) // Increased safe area padding
                    .padding(.trailing, 60) // Push heavily left to ensure visibility
                    .transition(.opacity)
                }
                
                Spacer()
                
                // 4. Scrolling Script (Teleprompter)
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 32) {
                            ForEach(0..<scriptSegments.count, id: \.self) { index in
                                Text(scriptSegments[index])
                                    .font(.system(size: 24, weight: .regular, design: .serif))
                                    .foregroundColor(isSegmentActive(index) ? .white : .white.opacity(0.4))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 40)
                                    .frame(maxWidth: UIScreen.main.bounds.width - 40)
                                    .id(index)
                                    .shadow(color: isSegmentActive(index) ? .purple.opacity(0.5) : .clear, radius: 10)
                                    .scaleEffect(isSegmentActive(index) ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.5), value: audioPlayer.progress)
                            }
                            Spacer().frame(height: 300)
                        }
                        .padding(.top, 100)
                    }
                    .onChange(of: audioPlayer.progress) { _, _ in
                        withAnimation {
                            if let activeIndex = activeSegmentIndex {
                                proxy.scrollTo(activeIndex, anchor: .center)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 5. Bottom Controls
                if showControls {
                    VStack(spacing: 24) {
                        
                        // AREA: Either Volume Sliders OR Time Scrubber
                        Group {
                            if showVolumeSettings {
                                // Volume Sliders
                                VStack(spacing: 16) {
                                    // Voice Volume
                                    HStack {
                                        Image(systemName: "waveform")
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 24)
                                        Slider(value: $audioPlayer.voiceVolume, in: 0...1)
                                            .accentColor(.white)
                                    }
                                    
                                    // Music Volume
                                    HStack {
                                        Image(systemName: "music.note")
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 24)
                                        Slider(value: $audioPlayer.musicVolume, in: 0...1)
                                            .accentColor(.white.opacity(0.7))
                                    }
                                }
                                .padding(.horizontal, 60) // Increased safe padding
                                .frame(maxWidth: UIScreen.main.bounds.width - 80) // Explicit width constraint
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            } else {
                                // Timeline Slider
                                HStack {
                                    Text(formatTime(audioPlayer.currentTime))
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                    
                                    Slider(value: Binding(
                                        get: { audioPlayer.progress },
                                        set: { newValue in audioPlayer.seek(to: newValue) }
                                    ))
                                    .accentColor(.white)
                                    
                                    Text(formatTime(audioPlayer.duration))
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .monospacedDigit()
                                }
                                .padding(.horizontal, 30)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .frame(height: 80) // Fixed height to prevent jumpiness
                        
                        // Play/Pause Row + Settings Button
                        ZStack {
                            // Center: Play Button
                            Button(action: {
                                audioPlayer.togglePlayPause()
                            }) {
                                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.white)
                                    .shadow(radius: 10)
                            }
                            
                            // Right: Settings Toggle
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring()) {
                                        showVolumeSettings.toggle()
                                    }
                                }) {
                                    Image(systemName: showVolumeSettings ? "checkmark.circle.fill" : "slider.horizontal.3")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(12)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 60) // Push heavily left to align with top button
                            }
                        }
                    }
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            audioPlayer.loadAudio(
                voiceFile: audioFileName,
                musicFile: "soul-of-the-earth_10min"
            )
        }
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
        .statusBar(hidden: !showControls)
    }
    
    // MARK: - Helpers
    // ... (Helpers remain the same)
    
    // ... (segmentBoundaries and others remain same, skipping to keep context short in replacement if possible, but I need to replace the struct end or just use range)
    // I will use exact ranges to avoid touching helpers.
    
    private var segmentBoundaries: [TimeInterval] {
        // ... (Keep existing implementation logic)
        // Re-implementing essentially to ensure compile safety if I replace larger blocks.
        // Copying existing logic exactly.
        
        let wordCounts = scriptSegments.map { $0.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count }
        let totalWords = wordCounts.reduce(0, +)
        let totalDuration = audioPlayer.duration
        let techPaddingPerSegment = 0.35
        var totalExplicitSilence = 0.0
        for pause in segmentPauses { totalExplicitSilence += (pause + techPaddingPerSegment) }
        let speakingTime = max(0, totalDuration - totalExplicitSilence)
        var boundaries: [TimeInterval] = [0]
        var currentTime = 0.0
        for (index, count) in wordCounts.enumerated() {
            let pauseDuration = index < segmentPauses.count ? segmentPauses[index] : 0
            let wordFraction = Double(count) / Double(totalWords)
            let segmentSpeakingDuration = wordFraction * speakingTime
            let segmentTotalDuration = segmentSpeakingDuration + techPaddingPerSegment + pauseDuration
            currentTime += segmentTotalDuration
            boundaries.append(currentTime)
        }
        return boundaries
    }
    
    private var activeSegmentIndex: Int? {
        let currentTime = audioPlayer.currentTime
        let boundaries = segmentBoundaries
        for i in 0..<(boundaries.count - 1) {
            if currentTime >= boundaries[i] && currentTime < boundaries[i+1] { return i }
        }
        return scriptSegments.indices.last
    }
    
    private func isSegmentActive(_ index: Int) -> Bool { return activeSegmentIndex == index }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

class ManifestPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 1
    
    // Volume Control
    @Published var voiceVolume: Float = 1.0 {
        didSet { voicePlayer?.volume = voiceVolume }
    }
    @Published var musicVolume: Float = 0.8 {
        didSet { musicPlayer?.volume = musicVolume * 0.5 }
    }
    
    private var voicePlayer: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    func loadAudio(voiceFile: String, musicFile: String) {
        // Setup Session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("❌ Session error: \(error)") }
        
        // Load Voice
        if let url = Bundle.main.url(forResource: voiceFile, withExtension: "m4a") {
            do {
                voicePlayer = try AVAudioPlayer(contentsOf: url)
                voicePlayer?.delegate = self
                voicePlayer?.prepareToPlay()
                voicePlayer?.volume = voiceVolume
                duration = voicePlayer?.duration ?? 1
            } catch { print("❌ Voice error: \(error)") }
        } else { print("❌ Voice file not found: \(voiceFile)") }
        
        // Load Music
        // Try mp3 first, then m4a
        var musicUrl = Bundle.main.url(forResource: musicFile, withExtension: "mp3")
        if musicUrl == nil { musicUrl = Bundle.main.url(forResource: musicFile, withExtension: "m4a") }
        
        if let url = musicUrl {
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.prepareToPlay()
                musicPlayer?.numberOfLoops = -1 // Loop music
                musicPlayer?.volume = musicVolume * 0.5 // Scale to 50% max
            } catch { print("❌ Music error: \(error)") }
        } else { print("❌ Music file not found: \(musicFile)") }
        
        play()
    }
    
    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }
    
    func play() {
        voicePlayer?.play()
        musicPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        voicePlayer?.pause()
        musicPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        voicePlayer?.stop()
        musicPlayer?.stop()
        voicePlayer?.currentTime = 0
        musicPlayer?.currentTime = 0
        isPlaying = false
        stopTimer()
        updateProgress()
    }
    
    func seek(to value: Double) {
        let newTime = value * duration
        voicePlayer?.currentTime = newTime
        // Sync music loosely or let it loop? 
        // Let's sync it to keep the "vibe" consistent (e.g. 2 mins in = 2 mins of song)
        // modulo duration of music to handle longer/shorter tracks safely
        if let musicDur = musicPlayer?.duration, musicDur > 0 {
             musicPlayer?.currentTime = newTime.truncatingRemainder(dividingBy: musicDur)
        }
        
        currentTime = newTime
        progress = value
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress() {
        guard let player = voicePlayer else { return }
        currentTime = player.currentTime
        progress = player.currentTime / duration
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player == voicePlayer {
            // End of session
            pause() // Stop music too
            isPlaying = false
            stopTimer()
            progress = 1.0
        }
    }
}
