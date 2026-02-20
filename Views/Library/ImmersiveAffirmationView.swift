import SwiftUI
import AVFoundation

struct ImmersiveAffirmationView: View {
    let affirmations: [Affirmation]
    let duration: StartAffirmationsView.AffirmationDuration
    var isAIGenerated: Bool = false
    var isOnboarding: Bool = false // Don't count onboarding sessions towards limit
    let onComplete: () -> Void
    
    @State private var showCountdown = true
    @State private var countdown = 3
    @State private var timer: Timer?
    @State private var bellPlayer: AVAudioPlayer?
    @State private var showSavePrompt = false
    
    @StateObject private var storage = StorageService.shared
    
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
                        handleSessionComplete()
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
            
            // Save Prompt Overlay (for AI-generated affirmations)
            if showSavePrompt {
                savePromptOverlay
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
            // Disable idle timer to prevent screen sleep
            UIApplication.shared.isIdleTimerDisabled = true
            
            // Play bell sound once (it will continue even when countdown ends)
            playBellSound()
            startCountdown()
        }
        .onDisappear {
            // Disable background audio when leaving immersive session
            BackgroundMusicManager.shared.isInImmersiveMode = false
            // Re-enable idle timer
            UIApplication.shared.isIdleTimerDisabled = false
            
            // Stop speech but keep background music playing
            timer?.invalidate()
            SpeechService.shared.stopSpeaking()
        }
    }
    
    // MARK: - Save Prompt Overlay
    private var savePromptOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.museGradientStart, .museGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Title
                Text("Save Your Affirmations?")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.museSoftWhite)
                
                // Subtitle
                Text("These personalized affirmations can be saved for future sessions.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Affirmation count
                Text("\(affirmations.count) affirmations created")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.museAccentBlue)
                
                // Buttons
                VStack(spacing: 12) {
                    // Save button
                    Button(action: saveAffirmations) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("Save to AI Generated")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [.museGradientStart, .museGradientEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    
                    // Don't save button
                    Button(action: skipSave) {
                        Text("Don't Save")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.museLightGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.museDarkGray.opacity(0.6))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.museDarkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 30)
        }
        .transition(.opacity)
    }
    
    // MARK: - Actions
    private func handleSessionComplete() {
        if isAIGenerated {
            // Show save prompt for AI-generated affirmations
            withAnimation(.easeInOut(duration: 0.3)) {
                showSavePrompt = true
            }
        } else {
            // Regular affirmations - just complete
            onComplete()
        }
    }
    
    private func saveAffirmations() {
        storage.saveAIGeneratedAffirmations(affirmations)
        withAnimation(.easeInOut(duration: 0.3)) {
            showSavePrompt = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
    
    private func skipSave() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSavePrompt = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
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

