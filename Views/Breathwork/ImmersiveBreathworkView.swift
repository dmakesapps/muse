import SwiftUI

// MARK: - Breathing Pattern
enum BreathingPattern: String, CaseIterable, Identifiable {
    case boxBreathing = "Box Breathing"
    case relaxation478 = "4-7-8 Relaxation"
    case energizing = "Energizing Breath"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .boxBreathing:
            return "4-4-4-4 pattern • Stress relief"
        case .relaxation478:
            return "4-7-8 pattern • Deep relaxation"
        case .energizing:
            return "2-1-4-1 pattern • Energy boost"
        }
    }
    
    var icon: String {
        switch self {
        case .boxBreathing: return "square"
        case .relaxation478: return "moon.fill"
        case .energizing: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .boxBreathing: return .museAccentBlue
        case .relaxation478: return .museTeal
        case .energizing: return .orange
        }
    }
    
    // Phase durations in seconds [inhale, holdAfterInhale, exhale, holdAfterExhale]
    var phases: [BreathPhase] {
        switch self {
        case .boxBreathing:
            return [
                BreathPhase(type: .inhale, duration: 4),
                BreathPhase(type: .holdIn, duration: 4),
                BreathPhase(type: .exhale, duration: 4),
                BreathPhase(type: .holdOut, duration: 4)
            ]
        case .relaxation478:
            return [
                BreathPhase(type: .inhale, duration: 4),
                BreathPhase(type: .holdIn, duration: 7),
                BreathPhase(type: .exhale, duration: 8),
                BreathPhase(type: .holdOut, duration: 0) // No hold after exhale
            ]
        case .energizing:
            return [
                BreathPhase(type: .inhale, duration: 2),
                BreathPhase(type: .holdIn, duration: 1),
                BreathPhase(type: .exhale, duration: 4),
                BreathPhase(type: .holdOut, duration: 1)
            ]
        }
    }
    
    var totalCycleDuration: Double {
        phases.reduce(0) { $0 + $1.duration }
    }
}

// MARK: - Breath Phase
struct BreathPhase {
    enum PhaseType: String {
        case inhale = "Inhale"
        case holdIn = "Hold"
        case exhale = "Exhale"
        case holdOut = "Hold"
    }
    
    let type: PhaseType
    let duration: Double
}

// MARK: - Immersive Breathwork View
struct ImmersiveBreathworkView: View {
    let pattern: BreathingPattern
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    @State private var currentPhaseIndex = 0
    @State private var phaseProgress: Double = 0
    @State private var elapsedTime: TimeInterval = 0
    @State private var isRunning = true
    @State private var isPaused = false
    @State private var circleScale: CGFloat = 0.5
    @State private var hapticEnabled = true
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    private var currentPhase: BreathPhase {
        let phases = pattern.phases.filter { $0.duration > 0 }
        return phases[currentPhaseIndex % phases.count]
    }
    
    private var activePhases: [BreathPhase] {
        pattern.phases.filter { $0.duration > 0 }
    }
    
    private var phaseText: String {
        currentPhase.type.rawValue
    }
    
    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            // Background
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top info bar
                topInfoBar
                    .padding(.top, 60)
                
                Spacer()
                
                // Breathing circle
                breathingCircle
                
                Spacer()
                
                // Bottom controls
                bottomControls
                    .padding(.bottom, 40)
            }
        }
        .onReceive(timer) { _ in
            guard isRunning && !isPaused else { return }
            updateBreathing()
        }
        .onAppear {
            startBreathing()
        }
    }
    
    // MARK: - Top Info Bar
    private var topInfoBar: some View {
        HStack(spacing: 24) {
            // Inhale indicator
            VStack(spacing: 4) {
                Image(systemName: "nose")
                    .font(.system(size: 24))
                    .foregroundColor(.museSoftWhite.opacity(0.8))
                
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10))
                    Text("\(Int(pattern.phases.first { $0.type == .inhale }?.duration ?? 4))")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.museSuccessGreen)
            }
            
            // Exhale indicator
            VStack(spacing: 4) {
                Image(systemName: "mouth")
                    .font(.system(size: 24))
                    .foregroundColor(.museSoftWhite.opacity(0.8))
                
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10))
                    Text("\(Int(pattern.phases.first { $0.type == .exhale }?.duration ?? 4))")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.museSuccessGreen)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.museDarkGray.opacity(0.6))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
        )
    }
    
    // MARK: - Breathing Circle
    private var breathingCircle: some View {
        ZStack {
            // Outer static circle (reference ring)
            Circle()
                .stroke(Color.museSoftWhite.opacity(0.15), lineWidth: 2)
                .frame(width: 280, height: 280)
            
            // Middle reference circle
            Circle()
                .fill(Color.museSoftWhite.opacity(0.08))
                .frame(width: 260, height: 260)
            
            // Animated inner circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.museSoftWhite.opacity(0.4),
                            Color.museSoftWhite.opacity(0.2)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(circleScale)
            
            // Center text
            VStack(spacing: 8) {
                Text(phaseText)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.museSoftWhite)
                
                // Countdown for current phase
                Text("\(Int(ceil(currentPhase.duration - (phaseProgress * currentPhase.duration))))")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.museLightGray)
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Control buttons
            HStack(spacing: 40) {
                // Haptic toggle
                Button(action: {
                    hapticEnabled.toggle()
                    if hapticEnabled {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }) {
                    Image(systemName: hapticEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                        .font(.system(size: 20))
                        .foregroundColor(.museSoftWhite)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.museDarkGray.opacity(0.8))
                        )
                }
                
                // Pause/Play button
                Button(action: {
                    isPaused.toggle()
                    if !isPaused && hapticEnabled {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    }
                }) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.museSoftWhite)
                        .frame(width: 70, height: 70)
                        .background(
                            Circle()
                                .fill(Color.museDarkGray.opacity(0.8))
                        )
                }
                
                // Close button
                Button(action: {
                    isRunning = false
                    onComplete()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(.museSoftWhite)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.museDarkGray.opacity(0.8))
                        )
                }
            }
            
            // Timer display
            Text(formattedTime)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.museSoftWhite)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.museDarkGray.opacity(0.8))
                )
        }
    }
    
    // MARK: - Breathing Logic
    private func startBreathing() {
        currentPhaseIndex = 0
        phaseProgress = 0
        updateCircleScale(animated: true)
    }
    
    private func updateBreathing() {
        elapsedTime += 0.05
        
        let phaseDuration = currentPhase.duration
        phaseProgress += 0.05 / phaseDuration
        
        if phaseProgress >= 1.0 {
            // Move to next phase
            phaseProgress = 0
            currentPhaseIndex = (currentPhaseIndex + 1) % activePhases.count
            
            // Haptic feedback on phase change
            if hapticEnabled {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
            
            updateCircleScale(animated: true)
        } else {
            // Continuous scale update during inhale/exhale
            updateCircleScaleContinuous()
        }
    }
    
    private func updateCircleScale(animated: Bool) {
        let targetScale: CGFloat
        
        switch currentPhase.type {
        case .inhale:
            targetScale = 0.5 // Start small, will expand
        case .holdIn:
            targetScale = 1.0 // Stay expanded
        case .exhale:
            targetScale = 1.0 // Start expanded, will contract
        case .holdOut:
            targetScale = 0.5 // Stay contracted
        }
        
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                circleScale = targetScale
            }
        } else {
            circleScale = targetScale
        }
    }
    
    private func updateCircleScaleContinuous() {
        switch currentPhase.type {
        case .inhale:
            // Expand from 0.5 to 1.0
            withAnimation(.linear(duration: 0.05)) {
                circleScale = 0.5 + (0.5 * phaseProgress)
            }
        case .exhale:
            // Contract from 1.0 to 0.5
            withAnimation(.linear(duration: 0.05)) {
                circleScale = 1.0 - (0.5 * phaseProgress)
            }
        case .holdIn, .holdOut:
            // Keep current scale
            break
        }
    }
}

#Preview {
    ImmersiveBreathworkView(
        pattern: .boxBreathing,
        onComplete: {}
    )
}
