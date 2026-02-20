import SwiftUI
import AVFoundation

// MARK: - Immersive Frequencies View
/// An immersive view that plays healing frequencies with visual animations
/// Initially based on the affirmation immersive view structure
struct ImmersiveFrequenciesView: View {
    let frequency: FrequencyItem
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    // Audio
    @State private var frequencyPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    // Volume Controls
    @State private var frequencyVolume: Float = 1.0
    @State private var musicVolume: Float = 0.5
    @State private var showVolumeSettings = false
    
    // UI State
    @State private var showControls = true
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    // Visualization
    @State private var wavePhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Background
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            // Dark Overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Main Content
            VStack {
                // Header (Close Button)
                if showControls {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Log the frequency session before stopping
                            ProgressService.shared.logFrequencySession(duration: elapsedTime)
                            stop()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 64)
                    .padding(.trailing, 60)
                    .transition(.opacity)
                }
                
                Spacer()
                
                // Frequency Visualization
                frequencyVisualization
                
                Spacer()
                
                // Bottom Controls
                if showControls {
                    bottomControls
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            setupAudio()
            startVisualization()
            UIApplication.shared.isIdleTimerDisabled = true
            BackgroundMusicManager.shared.isInImmersiveMode = true
        }
        .onDisappear {
            stop()
            UIApplication.shared.isIdleTimerDisabled = false
            BackgroundMusicManager.shared.isInImmersiveMode = false
        }
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
        .statusBar(hidden: !showControls)
    }
    
    // MARK: - Frequency Visualization
    private var frequencyVisualization: some View {
        VStack(spacing: 24) {
            // Animated Frequency Circle
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            frequency.color.opacity(0.2 - Double(index) * 0.05),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(200 + index * 40), height: CGFloat(200 + index * 40))
                        .scaleEffect(pulseScale + CGFloat(index) * 0.1)
                }
                
                // Main circle with gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                frequency.color.opacity(0.8),
                                frequency.color.opacity(0.4),
                                frequency.color.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseScale)
                    .shadow(color: frequency.color.opacity(glowOpacity), radius: 30)
                
                // Icon
                Image(systemName: frequency.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
            }
            
            // Frequency Info
            VStack(spacing: 12) {
                Text(frequency.name)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(frequency.subtitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text(frequency.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 24) {
            // Volume Settings OR Time Display
            Group {
                if showVolumeSettings {
                    // Volume Sliders
                    VStack(spacing: 16) {
                        // Frequency Volume
                        HStack(spacing: 12) {
                            Image(systemName: "waveform")
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 24)
                            
                            Text("Frequency")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 70, alignment: .leading)
                            
                            Slider(value: $frequencyVolume, in: 0...1)
                                .accentColor(frequency.color)
                                .onChange(of: frequencyVolume) { _, newValue in
                                    frequencyPlayer?.volume = newValue
                                }
                        }
                        
                        // Background Music Volume
                        HStack(spacing: 12) {
                            Image(systemName: "music.note")
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 24)
                            
                            Text("Music")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 70, alignment: .leading)
                            
                            Slider(value: $musicVolume, in: 0...1)
                                .accentColor(.white)
                                .onChange(of: musicVolume) { _, newValue in
                                    // Scale to 50% max for background music
                                    BackgroundMusicManager.shared.setVolume(newValue * 0.5)
                                }
                        }
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    // Time display
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(height: 80) // Fixed height to prevent layout jumping
            
            // Play/Pause Row + Settings Button
            ZStack {
                // Center: Play/Pause Button
                Button(action: {
                    togglePlayPause()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
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
                    .padding(.trailing, 60)
                }
            }
        }
        .padding(.bottom, 60)
    }
    
    // MARK: - Audio Setup
    private func setupAudio() {
        // Try to load the frequency audio file
        let extensions = ["mp3", "m4a", "wav"]
        var url: URL? = nil
        
        for ext in extensions {
            if let foundUrl = Bundle.main.url(forResource: frequency.audioFileName, withExtension: ext) {
                url = foundUrl
                break
            }
        }
        
        guard let audioUrl = url else {
            print("❌ Frequency audio file not found: \(frequency.audioFileName)")
            // Still allow the view to work without audio for now
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            frequencyPlayer = try AVAudioPlayer(contentsOf: audioUrl)
            frequencyPlayer?.numberOfLoops = -1 // Loop indefinitely
            frequencyPlayer?.volume = frequencyVolume
            frequencyPlayer?.prepareToPlay()
            
            // Set initial background music volume
            BackgroundMusicManager.shared.setVolume(musicVolume * 0.5)
            
            // Auto-play
            play()
        } catch {
            print("❌ Error setting up frequency audio: \(error)")
        }
    }
    
    private func play() {
        frequencyPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    private func pause() {
        frequencyPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    private func stop() {
        frequencyPlayer?.stop()
        isPlaying = false
        stopTimer()
    }
    
    private func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // MARK: - Timer
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Visualization
    private func startVisualization() {
        // Pulse animation
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.1
            glowOpacity = 0.6
        }
    }
    
    // MARK: - Helpers
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview
#Preview {
    ImmersiveFrequenciesView(
        frequency: FrequencyItem.allFrequencies[5], // 528 Hz
        onComplete: {}
    )
}
