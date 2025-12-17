import SwiftUI
import AVFoundation

struct ImmersiveAffirmationView: View {
    let affirmations: [Affirmation]
    let duration: StartAffirmationsView.AffirmationDuration
    let onComplete: () -> Void
    
    @State private var showCountdown = true
    @State private var countdown = 3
    @State private var timer: Timer?
    @State private var bellPlayer: AVAudioPlayer?
    
    // Track which tip to show (persisted across sessions)
    @AppStorage("affirmationTipIndex") private var tipIndex: Int = 0
    
    @State private var sessionAffirmations: [Affirmation] = []
    
    var body: some View {
        ZStack {
            // Affirmation View (Bottom Layer)
            // Initialize early (at 1) to allow fade in
            if !showCountdown || countdown <= 1 {
                AffirmationDisplayView(
                    affirmations: sessionAffirmations,
                    duration: duration,
                    onComplete: {
                        onComplete()
                    }
                )
                // Fade in when countdown reaches 1
                .opacity(countdown <= 1 ? 1 : 0) 
                .animation(.easeInOut(duration: 1.0), value: countdown)
            }
            
            // Countdown View (Top Layer)
            if showCountdown {
                CountdownView(countdown: $countdown, tipIndex: tipIndex, onComplete: {
                    // This callback happens at 0
                    // Give it a moment to finish fading out before removing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showCountdown = false
                    }
                    // Increment tip index for next session
                    tipIndex = (tipIndex + 1) % 4
                })
                // Fade out when countdown reaches 1
                .opacity(countdown <= 1 ? 0 : 1)
                .animation(.easeInOut(duration: 1.0), value: countdown)
            }
        }
        .onAppear {
            // Prepare affirmations (shuffle)
            sessionAffirmations = affirmations.shuffled()
            
            // PREFETCH THE FIRST ONE IMMEDIATELY
            if let first = sessionAffirmations.first {
                print("🚀 ImmersiveAffirmationView: Prefetching first affirmation: \(first.text)")
                SpeechService.shared.prefetch(first.text)
            }
            
            // Enable background audio for immersive session
            BackgroundMusicManager.shared.isInImmersiveMode = true
            // Play bell sound once (it will continue even when countdown ends)
            playBellSound()
            startCountdown()
        }
        .onDisappear {
            // Disable background audio when leaving immersive session
            BackgroundMusicManager.shared.isInImmersiveMode = false
            // Stop speech but keep background music playing
            timer?.invalidate()
            SpeechService.shared.stopSpeaking()
        }
    }
    
    private func startCountdown() {
        countdown = 3
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func playBellSound() {
        guard let url = Bundle.main.url(forResource: "bell321", withExtension: "mp3") else {
            print("Bell sound not found: bell321.mp3")
            return
        }
        
        do {
            bellPlayer = try AVAudioPlayer(contentsOf: url)
            bellPlayer?.volume = 0.8
            bellPlayer?.play()
        } catch {
            print("Error playing bell sound: \(error.localizedDescription)")
        }
    }
}
