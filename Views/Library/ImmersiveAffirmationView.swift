import SwiftUI

struct ImmersiveAffirmationView: View {
    let affirmations: [Affirmation]
    let duration: StartAffirmationsView.AffirmationDuration
    let onComplete: () -> Void
    
    @State private var showCountdown = true
    @State private var countdown = 5
    @State private var timer: Timer?
    
    var body: some View {
        Group {
            if showCountdown {
                CountdownView(countdown: $countdown, onComplete: {
                    showCountdown = false
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
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startCountdown() {
        countdown = 5
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}


