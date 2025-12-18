import SwiftUI
import AVFoundation
import Combine

struct ImmersiveManifestView: View {
    @Environment(\.dismiss) var dismiss
    
    // Config
    let sessionName: String = "5 Minute Manifestation"
    let audioFileName: String = "manifest_5min"
    
    // State
    @StateObject private var audioPlayer = ManifestPlayer()
    @State private var showControls = true
    @State private var contentOffset: CGFloat = 0
    
    // Script Content
    // We break this into identifiable segments for scrolling/highlighting
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
                        Button(action: {
                            audioPlayer.stop()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding()
                    .transition(.opacity)
                }
                
                Spacer()
                
                // 4. Scrolling Script (Teleprompter)
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 32) {
                            ForEach(0..<scriptSegments.count, id: \.self) { index in
                                Text(scriptSegments[index])
                                    .font(.system(size: 28, weight: .regular, design: .serif))
                                    .foregroundColor(isSegmentActive(index) ? .white : .white.opacity(0.4))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .id(index)
                                    .shadow(color: isSegmentActive(index) ? .purple.opacity(0.5) : .clear, radius: 10)
                                    .scaleEffect(isSegmentActive(index) ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.5), value: audioPlayer.progress)
                            }
                            
                            // Padding at bottom to scroll last item up
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
                    VStack(spacing: 20) {
                        // Slider
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
                        .padding(.horizontal)
                        
                        // Play/Pause
                        Button(action: {
                            audioPlayer.togglePlayPause()
                        }) {
                            Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                        }
                    }
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            audioPlayer.loadAudio(filename: audioFileName)
        }
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
        .statusBar(hidden: !showControls)
    }
    
    // MARK: - Helpers
    
    /// Determine which segment should be highlighted based on progress
    /// Since we don't have timestamp data, we map 0-100% progress to 0-N segments linearly
    /// This is an ESTIMATE. We will refine this later.
    private var activeSegmentIndex: Int? {
        // Adjust these heuristics as we tune the audio
        let totalSegments = Double(scriptSegments.count)
        let rawIndex = Int(audioPlayer.progress * totalSegments)
        return min(max(0, rawIndex), scriptSegments.count - 1)
    }
    
    private func isSegmentActive(_ index: Int) -> Bool {
        return activeSegmentIndex == index
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Player Logic

class ManifestPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 1 // Prevent div by zero
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    func loadAudio(filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "m4a") else {
            print("❌ File not found: \(filename).m4a")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 1
            
            // Auto start
            play()
            
        } catch {
            print("❌ Playback error: \(error)")
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        stopTimer()
    }
    
    func seek(to value: Double) {
        let newTime = value * duration
        audioPlayer?.currentTime = newTime
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
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        progress = player.currentTime / duration
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTimer()
        progress = 1.0
    }
}
