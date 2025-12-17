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
    
    var body: some View {
        Group {
            if showCountdown {
                CountdownView(countdown: $countdown, tipIndex: tipIndex, onComplete: {
                    showCountdown = false
                    // Increment tip index for next session (cycle through 0-3)
                    tipIndex = (tipIndex + 1) % 4
                })
            } else {
                AffirmationDisplayView(
                    affirmations: affirmations,
                    duration: duration,
                    onComplete: {
                        onComplete()
                    }
                )
            }
        }
        .onAppear {
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
