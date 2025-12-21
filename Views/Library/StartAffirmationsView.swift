import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Breathing Pattern
enum BreathingPattern: String, CaseIterable, Identifiable {
    case boxBreathing = "Box Breathing"
    case relaxation478 = "4-7-8 Relaxation"
    case calming46 = "4-6 Calming"
    case energizing = "Energizing Breath"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .boxBreathing:
            return "4-4-4-4 pattern • Stress relief"
        case .relaxation478:
            return "4-7-8 pattern • Deep relaxation"
        case .calming46:
            return "4-6 pattern • Simple calm"
        case .energizing:
            return "2-1-4-1 pattern • Energy boost"
        }
    }
    
    var icon: String {
        switch self {
        case .boxBreathing: return "square"
        case .relaxation478: return "moon.fill"
        case .calming46: return "leaf.fill"
        case .energizing: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .boxBreathing: return .museAccentBlue
        case .relaxation478: return .museTeal
        case .calming46: return .green
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
        case .calming46:
            return [
                BreathPhase(type: .inhale, duration: 4),
                BreathPhase(type: .holdIn, duration: 0),
                BreathPhase(type: .exhale, duration: 6),
                BreathPhase(type: .holdOut, duration: 0)
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
        case holdIn = "Hold In"
        case exhale = "Exhale"
        case holdOut = "Hold Out"
        
        var localizedName: String {
            switch self {
            case .inhale: return "Inhale"
            case .exhale: return "Exhale"
            case .holdIn, .holdOut: return "Hold"
            }
        }
    }
    
    let type: PhaseType
    let duration: Double
}

// MARK: - Immersive Breathwork View
struct ImmersiveBreathworkView: View {
    let pattern: BreathingPattern
    let totalDuration: TimeInterval
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
    @State private var countdown = 3
    @State private var isCountingDown = true
    @State private var timer: Timer?
    @State private var lastUpdateTime: Date = Date()
    @State private var showControls = true
    @State private var soundEnabled = true
    @State private var audioPlayer: AVAudioPlayer?
    
    @State private var phasePlayers: [BreathPhase.PhaseType: AVAudioPlayer] = [:]
    
    private var currentPhase: BreathPhase {
        let phases = pattern.phases.filter { $0.duration > 0 }
        return phases[currentPhaseIndex % phases.count]
    }
    
    private var activePhases: [BreathPhase] {
        pattern.phases.filter { $0.duration > 0 }
    }
    
    private var phaseText: String {
        currentPhase.type.localizedName
    }
    
    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func preloadSounds() {
        let mappings: [BreathPhase.PhaseType: String] = [
            .inhale: "gonginhale",
            .exhale: "gongexhale",
            .holdIn: "gonghold",
            .holdOut: "gonghold"
        ]
        
        for (phase, filename) in mappings {
            if let url = Bundle.main.url(forResource: filename, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = 1.0 // adjusted volume
                    phasePlayers[phase] = player
                } catch {
                    print("Could not load sound \(filename): \(error)")
                }
            }
        }
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
                    .opacity(showControls ? 1 : 0)
                
                Spacer()
                
                // Breathing circle
                breathingCircle
                
                Spacer()
                
                // Bottom controls
                bottomControls
                    .padding(.bottom, 40)
                    .opacity(showControls ? 1 : 0)
            }
        }
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
        }

        .onAppear {
            print("💨 ImmersiveBreathworkView appeared with pattern: \(pattern.rawValue)")
            BackgroundMusicManager.shared.isInImmersiveMode = true
            UIApplication.shared.isIdleTimerDisabled = true
            preloadSounds()
            startCountdown()
        }
        .onDisappear {
            BackgroundMusicManager.shared.isInImmersiveMode = false
            UIApplication.shared.isIdleTimerDisabled = false
            // Stop all sounds
            phasePlayers.values.forEach { $0.stop() }
            timer?.invalidate()
            timer = nil
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
                if isCountingDown {
                    Text("\(countdown)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.museSoftWhite)
                        .transition(.opacity)
                } else {
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
    private func startCountdown() {
        countdown = 3
        isCountingDown = true
        
        // Simple one-off timer for countdown
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                
                withAnimation(.easeInOut(duration: 1.0)) {
                    isCountingDown = false
                }
                
                // Start breathing shortly after visual transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startBreathing()
                    startTimer()
                    // Play initial inhale sound
                    playPhaseSound(for: .inhale)
                }
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        lastUpdateTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard isRunning && !isPaused && !isCountingDown else { 
                lastUpdateTime = Date() // Keep updating time to avoid jumps on resume
                return 
            }
            
            let now = Date()
            let delta = now.timeIntervalSince(lastUpdateTime)
            lastUpdateTime = now
            
            updateBreathing(deltaTime: delta)
        }
    }
    
    private func startBreathing() {
        currentPhaseIndex = 0
        phaseProgress = 0
        withAnimation(.easeOut(duration: 0.5)) {
            circleScale = 0.5 // start small
        }
    }
    
    private func playPhaseSound(for phaseType: BreathPhase.PhaseType) {
        guard soundEnabled else { return }
        
        if let player = phasePlayers[phaseType] {
            player.currentTime = 0
            player.play()
        }
    }
    
    private func updateBreathing(deltaTime: TimeInterval) {
        elapsedTime += deltaTime
        
        // check for completion
        if elapsedTime >= totalDuration {
            isRunning = false
            endBreathworkSessionWithPadding()
            return
        }
        
        let phaseDuration = currentPhase.duration
        // Use deltaTime to advance progress
        phaseProgress += deltaTime / phaseDuration
        
        if phaseProgress >= 1.0 {
            // Move to next phase
            phaseProgress -= 1.0 // Keep overflow for smoother timing
            currentPhaseIndex = (currentPhaseIndex + 1) % activePhases.count
            
            // Haptic feedback on phase change
            if hapticEnabled {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
            
            // Play sound for new phase
            playPhaseSound(for: currentPhase.type)
            
            updateCircleScale(animated: true)
        } else {
            // Continuous scale update during inhale/exhale
            updateCircleScaleContinuous()
        }
    }
    
    private func endBreathworkSessionWithPadding() {
        // Stop sounds immediately
        phasePlayers.values.forEach { $0.stop() }
        BackgroundMusicManager.shared.stop(fadeOutDuration: 1.0)
        
        // Wait 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
             // If in background, ensure music stays off
            if UIApplication.shared.applicationState != .active {
                BackgroundMusicManager.shared.stop()
            }
            onComplete()
        }
    }
    
    private func updateCircleScale(animated: Bool) {
        let targetScale: CGFloat
        
        switch currentPhase.type {
        case .inhale:
            targetScale = 0.5 
        case .holdIn:
            targetScale = 1.4 
        case .exhale:
            targetScale = 1.4 
        case .holdOut:
            targetScale = 0.5 
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
            // Expand from 0.5 to 1.4
            withAnimation(.linear(duration: 0.05)) {
                circleScale = 0.5 + (0.9 * phaseProgress)
            }
        case .exhale:
            // Contract from 1.4 to 0.5
            withAnimation(.linear(duration: 0.05)) {
                circleScale = 1.4 - (0.9 * phaseProgress)
            }
        case .holdIn:
             withAnimation(.linear(duration: 0.05)) {
                circleScale = 1.4
             }
        case .holdOut:
             withAnimation(.linear(duration: 0.05)) {
                circleScale = 0.5
             }
        }
    }
}
// MARK: - Start Affirmations View
struct StartAffirmationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @State private var selectedMode: PracticeMode? = nil
    @State private var selectedSource: AffirmationSource? = nil
    @State private var selectedAffirmations: Set<UUID> = []
    @State private var useRandom: Bool = false
    @State private var selectedCategory: String? = nil
    @State private var duration: AffirmationDuration = .oneMinute
    @State private var isActive = false
    @State private var activeBreathworkPattern: BreathingPattern? // Use item for sheet logic
    @State private var allAffirmations: [Affirmation] = []
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    @State private var showManifestView = false
    @State private var activeFrequency: FrequencyItem? = nil // For frequencies immersive view
    
    enum PracticeMode: String, CaseIterable {
        case affirmations = "Affirmations"
        case breathwork = "Breathwork"
        case frequencies = "Frequencies"
    }

    
    enum AffirmationSource: String, CaseIterable {
        case favorites = "Favorites"
        case aiGenerated = "AI Generated"
        case library = "Library"
    }
    
    enum AffirmationDuration: String, CaseIterable {
        case oneMinute = "1 min"
        case threeMinutes = "3 min"
        case fiveMinutes = "5 min"
        case tenMinutes = "10 min"
        
        var seconds: Int {
            switch self {
            case .oneMinute: return 60
            case .threeMinutes: return 180
            case .fiveMinutes: return 300
            case .tenMinutes: return 600
            }
        }
    }
    
    // Get the current affirmation pool based on selected source
    private var currentAffirmationPool: [Affirmation] {
        if selectedSource == .library {
            return allAffirmations
        }
        return storage.savedAffirmations
    }
    
    // Get unique categories from current affirmation pool
    private var availableCategories: [String] {
        let categories = currentAffirmationPool.map { $0.category }
        return Array(Set(categories)).sorted()
    }
    
    // Filter affirmations by selected category
    private var filteredAffirmations: [Affirmation] {
        if let category = selectedCategory {
            return currentAffirmationPool.filter { $0.category == category }
        }
        return currentAffirmationPool
    }
    
    // Get the affirmations to use for the session
    var selectedAffirmationsList: [Affirmation] {
        if useRandom {
            // Use all affirmations from current pool (or filtered by category)
            return filteredAffirmations
        } else {
            return currentAffirmationPool.filter { selectedAffirmations.contains($0.id) }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.museSoftWhite)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.museDarkGray))
                    }
                    
                    Spacer()
                    
                    Text(headerTitle)
                        .font(.museDisplaySmall())
                        .foregroundColor(.museSoftWhite)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Mode Selection (Affirmations or Breathwork)
                        if selectedMode == nil {
                            modeSelectionView
                        }
                        // Affirmations Flow
                        else if selectedMode == .affirmations {
                            if selectedSource == nil {
                                sourceSelectionView
                            } else if selectedSource == .favorites {
                                favoritesSelectionView
                            } else if selectedSource == .aiGenerated {
                                aiGeneratedView
                            } else if selectedSource == .library {
                                libraryView
                            }
                        }
                        // Breathwork Flow
                        else if selectedMode == .breathwork {
                            breathworkSelectionView
                        }
                        // Frequencies Flow
                        else if selectedMode == .frequencies {
                            frequenciesSelectionView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                
                Spacer()
            }
            
            // Bottom Start Button
            VStack {
                Spacer()
                
                if selectedMode == .affirmations && selectedSource != nil && canStart {
                    Button(action: { isActive = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Start Session")
                                .font(.museButtonLarge())
                        }
                        .foregroundColor(.museSoftWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.museDarkGray.opacity(0.6))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    )
                                    .pulsingRainbowBorder()
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                

            }
        }
        .fullScreenCover(isPresented: $isActive) {
            ImmersiveAffirmationView(
                affirmations: selectedAffirmationsList,
                duration: duration,
                onComplete: {
                    isActive = false
                }
            )
        }
        .fullScreenCover(item: $activeBreathworkPattern) { pattern in
            ImmersiveBreathworkView(
                pattern: pattern,
                totalDuration: TimeInterval(duration.seconds),
                onComplete: { activeBreathworkPattern = nil }
            )
        }
        .fullScreenCover(isPresented: $showManifestView) {
            ImmersiveManifestView()
        }
        .fullScreenCover(item: $activeFrequency) { frequency in
            ImmersiveFrequenciesView(
                frequency: frequency,
                onComplete: { activeFrequency = nil }
            )
        }
    }
    
    private var headerTitle: String {
        if selectedMode == nil {
            return "Practice"
        } else if selectedMode == .affirmations {
            return "Affirmations"
        } else if selectedMode == .frequencies {
            return "Frequencies"
        } else {
            return "Breathwork"
        }
    }
    
    private var canStart: Bool {
        if selectedSource == .favorites || selectedSource == .library {
            return useRandom ? !filteredAffirmations.isEmpty : !selectedAffirmations.isEmpty
        }
        return false
    }
    
    // MARK: - Mode Selection View
    private var modeSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Practice")
                .font(.museHeadline())
                .foregroundColor(.museSoftWhite)
            
            VStack(spacing: 12) {
                // Affirmations Button
                PracticeModeButton(
                    title: "Affirmations",
                    subtitle: "Repeat positive statements",
                    icon: "text.quote",
                    color: .museGradientStart,
                    isDisabled: false
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMode = .affirmations
                    }
                }
                
                // Breathwork Button
                PracticeModeButton(
                    title: "Breathwork",
                    subtitle: "Guided breathing exercises",
                    icon: "wind",
                    color: .museTeal,
                    isDisabled: false
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMode = .breathwork
                    }
                }
                
                // Frequencies Button
                PracticeModeButton(
                    title: "Frequencies",
                    subtitle: "Healing sound vibrations",
                    icon: "waveform.path",
                    color: Color(red: 0.6, green: 0.4, blue: 0.8),
                    isDisabled: false
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMode = .frequencies
                    }
                }
                
                // Manifest Button
                PracticeModeButton(
                    title: "Manifest",
                    subtitle: "Visualize and attract your goals",
                    icon: "sparkles",
                    color: .purple,
                    isDisabled: false
                ) {
                    showManifestView = true
                }
                
                // Meditation Button
                PracticeModeButton(
                    title: "Meditation",
                    subtitle: "Find clarity and inner peace",
                    icon: "brain.head.profile",
                    color: .blue,
                    isDisabled: true
                ) {
                    // Coming soon
                }
            }
        }
    }
    
    // MARK: - Breathwork Selection View
    private var breathworkSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Back button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedMode = nil
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.museBodyMedium())
                }
                .foregroundColor(.museAccentBlue)
            }
            
            VStack(spacing: 16) {
                Image(systemName: "wind")
                    .font(.system(size: 48))
                    .foregroundColor(.museTeal)
                
                Text("Breathwork")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Text("Calm your mind with guided breathing exercises. Choose a pattern and duration to begin.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                
                // Duration Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Duration")
                        .font(.museBodyMedium())
                        .foregroundColor(.museLightGray)
                    
                    HStack(spacing: 8) {
                        ForEach([1, 3, 5, 10], id: \.self) { minutes in
                            let isSelected = duration.seconds == minutes * 60
                            Button(action: {
                                switch minutes {
                                case 1: duration = .oneMinute
                                case 3: duration = .threeMinutes
                                case 5: duration = .fiveMinutes
                                case 10: duration = .tenMinutes
                                default: duration = .oneMinute
                                }
                            }) {
                                Text("\(minutes) min")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(isSelected ? .white : .museLightGray)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color.museAccentBlue : Color.museDarkGray.opacity(0.5))
                                            .overlay(
                                                Capsule()
                                                    .stroke(isSelected ? Color.museSoftWhite : Color.clear, lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Breathwork options
                VStack(spacing: 12) {
                    BreathworkPatternButton(
                        title: "Box Breathing",
                        subtitle: "4-4-4-4 pattern • Stress relief",
                        icon: "square",
                        color: .museAccentBlue
                    ) {
                        activeBreathworkPattern = .boxBreathing
                    }
                    
                    BreathworkPatternButton(
                        title: "4-7-8 Relaxation",
                        subtitle: "4-7-8 pattern • Sleep aid",
                        icon: "moon.fill",
                        color: .museTeal
                    ) {
                        activeBreathworkPattern = .relaxation478
                    }
                    
                    BreathworkPatternButton(
                        title: "4-6 Calming",
                        subtitle: "4-6 pattern • Simple calm",
                        icon: "leaf.fill",
                        color: .green
                    ) {
                        activeBreathworkPattern = .calming46
                    }
                    
                    BreathworkPatternButton(
                        title: "Energizing Breath",
                        subtitle: "2-1-4-1 pattern • Energy boost",
                        icon: "bolt.fill",
                        color: .orange
                    ) {
                        activeBreathworkPattern = .energizing
                    }
                }
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Frequencies Selection View
    private var frequenciesSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Back button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedMode = nil
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.museBodyMedium())
                }
                .foregroundColor(.museAccentBlue)
            }
            
            VStack(spacing: 16) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.8))
                
                Text("Frequencies")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Text("Healing sound vibrations to balance mind and body. Choose a frequency to begin your session.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                
                // Frequency options
                VStack(spacing: 12) {
                    ForEach(FrequencyItem.allFrequencies) { frequency in
                        FrequencyButton(
                            frequency: frequency,
                            action: {
                                activeFrequency = frequency
                            }
                        )
                    }
                }
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Source Selection View (Affirmations)
    private var sourceSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Back button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedMode = nil
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.museBodyMedium())
                }
                .foregroundColor(.museAccentBlue)
            }
            
            VStack(spacing: 16) {
                Image(systemName: "text.quote")
                    .font(.system(size: 48))
                    .foregroundColor(.museGradientStart)
                
                Text("Affirmations")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Text("Reprogram your mind with positive statements. Choose a source to begin your practice.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                
                // Source options
                VStack(spacing: 12) {
                    // Favorites Button
                    SourceButton(
                        title: "Favorites",
                        subtitle: "\(storage.savedAffirmations.count) saved affirmations",
                        icon: "heart.fill",
                        color: .museGradientStart,
                        isDisabled: storage.savedAffirmations.isEmpty
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSource = .favorites
                        }
                    }
                    
                    // All Affirmations Button
                    SourceButton(
                        title: "All",
                        subtitle: "Browse all available affirmations",
                        icon: "list.bullet",
                        color: .museAccentBlue,
                        isDisabled: false
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSource = .library
                        }
                    }
                    
                    // AI Generated Button
                    SourceButton(
                        title: "AI Generated",
                        subtitle: "Personalized affirmations",
                        icon: "sparkles",
                        color: .museTeal,
                        isDisabled: true,
                        isComingSoon: true
                    ) {
                        // Coming soon
                    }
                }
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Favorites Selection View
    private var favoritesSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Back button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedSource = nil
                    selectedAffirmations.removeAll()
                    useRandom = false
                    selectedCategory = nil
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.museBodyMedium())
                }
                .foregroundColor(.museAccentBlue)
            }
            
            // Random Option
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    useRandom.toggle()
                    if useRandom {
                        selectedAffirmations.removeAll()
                    }
                }
            }) {
                HStack {
                    Image(systemName: "shuffle")
                        .font(.system(size: 20))
                        .foregroundColor(useRandom ? .museSoftWhite : .museGradientStart)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Random")
                            .font(.museHeadline())
                            .foregroundColor(.museSoftWhite)
                        Text("Cycle through all \(selectedCategory != nil ? "in category" : "saved")")
                            .font(.museCaption())
                            .foregroundColor(.museLightGray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: useRandom ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(useRandom ? .museSuccessGreen : .museLightGray)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(useRandom ? Color.museGradientStart.opacity(0.15) : Color.white.opacity(0.08))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.thinMaterial)
                                .opacity(useRandom ? 0.3 : 0.5)
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(useRandom ? Color.museGradientStart : Color.clear, lineWidth: useRandom ? 2 : 0)
                )
            }
            
            // Categories Section
            if !availableCategories.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filter by Category")
                        .font(.museHeadline())
                        .foregroundColor(.museSoftWhite)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // All option
                            CategoryPill(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                color: .museGradientStart
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = nil
                                }
                            }
                            
                            ForEach(availableCategories, id: \.self) { category in
                                CategoryPill(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    color: .museGradientStart
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Affirmations List (only show if not using random)
            if !useRandom {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Select Affirmations")
                            .font(.museHeadline())
                            .foregroundColor(.museSoftWhite)
                        
                        Spacer()
                        
                        if !filteredAffirmations.isEmpty {
                            Button(action: {
                                if selectedAffirmations.count == filteredAffirmations.count {
                                    selectedAffirmations.removeAll()
                                } else {
                                    selectedAffirmations = Set(filteredAffirmations.map { $0.id })
                                }
                            }) {
                                Text(selectedAffirmations.count == filteredAffirmations.count ? "Deselect All" : "Select All")
                                    .font(.museCaption())
                                    .foregroundColor(.museAccentBlue)
                            }
                        }
                    }
                    
                    if filteredAffirmations.isEmpty {
                        Text("No affirmations in this category")
                            .font(.museBodyMedium())
                            .foregroundColor(.museLightGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filteredAffirmations) { affirmation in
                                AffirmationSelectRow(
                                    affirmation: affirmation,
                                    isSelected: selectedAffirmations.contains(affirmation.id)
                                ) {
                                    toggleSelection(affirmation)
                                }
                            }
                        }
                    }
                }
            }
            
            // Music Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Background Music")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                VStack(spacing: 10) {
                    ForEach(BackgroundMusicTrack.allCases) { track in
                        MusicTrackButton(
                            track: track,
                            isSelected: storage.selectedMusicTrack == track,
                            onSelect: {
                                storage.selectedMusicTrack = track
                                BackgroundMusicManager.shared.selectedTrack = track
                            },
                            onPreview: {
                                BackgroundMusicManager.shared.preview(track: track)
                            }
                        )
                    }
                }
            }
            
            // Duration Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Duration")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                HStack(spacing: 10) {
                    ForEach(AffirmationDuration.allCases, id: \.self) { durationOption in
                        Button(action: { duration = durationOption }) {
                            Text(durationOption.rawValue)
                                .font(.museButtonMedium())
                                .foregroundColor(duration == durationOption ? .museSoftWhite : .museLightGray)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(duration == durationOption ? Color.museAccentBlue : Color.museDarkGray)
                                )
                        }
                    }
                }
            }
        }
        .onDisappear {
            // Stop any music preview when leaving this view
            BackgroundMusicManager.shared.stopPreview()
        }
    }
    
    // MARK: - AI Generated View
    private var aiGeneratedView: some View {
        VStack(spacing: 20) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedSource = nil
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.museBodyMedium())
                }
                .foregroundColor(.museAccentBlue)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.museTeal.opacity(0.5))
                
                Text("AI Generated Affirmations")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Text("Coming soon! AI will create personalized affirmations based on your goals and preferences.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 60)
        }
    }
    
    // MARK: - Library View (All Affirmations)
    private var libraryView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Back button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedSource = nil
                    selectedAffirmations.removeAll()
                    useRandom = false
                    selectedCategory = nil
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.museBodyMedium())
                }
                .foregroundColor(.museAccentBlue)
            }
            
            // Random Option
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    useRandom.toggle()
                    if useRandom {
                        selectedAffirmations.removeAll()
                    }
                }
            }) {
                HStack {
                    Image(systemName: "shuffle")
                        .font(.system(size: 20))
                        .foregroundColor(useRandom ? .museSoftWhite : .museAccentBlue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Random")
                            .font(.museHeadline())
                            .foregroundColor(.museSoftWhite)
                        Text("Cycle through all \(selectedCategory != nil ? "in category" : "available")")
                            .font(.museCaption())
                            .foregroundColor(.museLightGray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: useRandom ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(useRandom ? .museSuccessGreen : .museLightGray)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(useRandom ? Color.museAccentBlue.opacity(0.15) : Color.white.opacity(0.08))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.thinMaterial)
                                .opacity(useRandom ? 0.3 : 0.5)
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(useRandom ? Color.museAccentBlue : Color.clear, lineWidth: useRandom ? 2 : 0)
                )
            }
            
            // Categories Section
            if !availableCategories.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filter by Category")
                        .font(.museHeadline())
                        .foregroundColor(.museSoftWhite)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // All option
                            CategoryPill(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                color: .museAccentBlue
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = nil
                                }
                            }
                            
                            ForEach(availableCategories, id: \.self) { category in
                                CategoryPill(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    color: .museAccentBlue
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Affirmations List (only show if not using random)
            if !useRandom {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Select Affirmations")
                            .font(.museHeadline())
                            .foregroundColor(.museSoftWhite)
                        
                        Spacer()
                        
                        if !filteredAffirmations.isEmpty {
                            Button(action: {
                                if selectedAffirmations.count == filteredAffirmations.count {
                                    selectedAffirmations.removeAll()
                                } else {
                                    selectedAffirmations = Set(filteredAffirmations.map { $0.id })
                                }
                            }) {
                                Text(selectedAffirmations.count == filteredAffirmations.count ? "Deselect All" : "Select All")
                                    .font(.museCaption())
                                    .foregroundColor(.museAccentBlue)
                            }
                        }
                    }
                    
                    if filteredAffirmations.isEmpty {
                        Text("No affirmations in this category")
                            .font(.museBodyMedium())
                            .foregroundColor(.museLightGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filteredAffirmations) { affirmation in
                                AffirmationSelectRow(
                                    affirmation: affirmation,
                                    isSelected: selectedAffirmations.contains(affirmation.id)
                                ) {
                                    toggleSelection(affirmation)
                                }
                            }
                        }
                    }
                }
            }
            
            // Music Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Background Music")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                VStack(spacing: 10) {
                    ForEach(BackgroundMusicTrack.allCases) { track in
                        MusicTrackButton(
                            track: track,
                            isSelected: storage.selectedMusicTrack == track,
                            onSelect: {
                                storage.selectedMusicTrack = track
                                BackgroundMusicManager.shared.selectedTrack = track
                            },
                            onPreview: {
                                BackgroundMusicManager.shared.preview(track: track)
                            }
                        )
                    }
                }
            }
            
            // Duration Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Duration")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                HStack(spacing: 10) {
                    ForEach(AffirmationDuration.allCases, id: \.self) { durationOption in
                        Button(action: { duration = durationOption }) {
                            Text(durationOption.rawValue)
                                .font(.museButtonMedium())
                                .foregroundColor(duration == durationOption ? .museSoftWhite : .museLightGray)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(duration == durationOption ? Color.museAccentBlue : Color.museDarkGray)
                                )
                        }
                    }
                }
            }
        }
        .onAppear {
            // Load all affirmations when this view appears
            if allAffirmations.isEmpty {
                allAffirmations = ContentLoader.shared.loadAffirmations()
            }
        }
        .onDisappear {
            // Stop any music preview when leaving this view
            BackgroundMusicManager.shared.stopPreview()
        }
    }
    
    private func toggleSelection(_ affirmation: Affirmation) {
        if selectedAffirmations.contains(affirmation.id) {
            selectedAffirmations.remove(affirmation.id)
        } else {
            selectedAffirmations.insert(affirmation.id)
        }
    }
}

// MARK: - Music Track Button
struct MusicTrackButton: View {
    let track: BackgroundMusicTrack
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    @State private var isPreviewing = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: track.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .museSoftWhite : .museGradientStart)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color.museGradientStart : Color.museGradientStart.opacity(0.15))
                    )
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.rawValue)
                        .font(.museBodyMedium())
                        .foregroundColor(.museSoftWhite)
                    
                    Text(track.description)
                        .font(.museCaption())
                        .foregroundColor(.museLightGray)
                }
                
                Spacer()
                
                // Preview button (only for tracks with audio)
                if track.fileName != nil {
                    Button(action: {
                        isPreviewing.toggle()
                        if isPreviewing {
                            onPreview()
                        } else {
                            BackgroundMusicManager.shared.stopPreview()
                        }
                    }) {
                        Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.museAccentBlue)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.museAccentBlue.opacity(0.15))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .museSuccessGreen : .museLightGray)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.museSuccessGreen.opacity(0.1) : Color.museDarkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.museSuccessGreen.opacity(0.5) : Color.museMediumGray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                // Stop preview when selected
                isPreviewing = false
            }
        }
    }
}

// MARK: - Practice Mode Button
struct PracticeModeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(isDisabled ? .museLightGray : color)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDisabled ? Color.museMediumGray.opacity(0.3) : color.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isDisabled ? .museLightGray : .museSoftWhite)
                    
                    Text(subtitle)
                        .font(.museCaption())
                        .foregroundColor(.museLightGray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.museLightGray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thinMaterial)
                            .opacity(0.5)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.7 : 1)
    }
}

// MARK: - Breathwork Pattern Button
struct BreathworkPatternButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Text(subtitle)
                    .font(.museCaption())
                    .foregroundColor(.museLightGray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.museLightGray)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.thinMaterial)
                        .opacity(0.5)
                )
        )
        .contentShape(Rectangle()) // Ensure entire area is clickable
        .onTapGesture(perform: action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Frequency Button
struct FrequencyButton: View {
    let frequency: FrequencyItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(frequency.color.opacity(0.2))
                    
                    Image(systemName: frequency.icon)
                        .font(.system(size: 22))
                        .foregroundColor(frequency.color)
                }
                .frame(width: 50, height: 50)
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(frequency.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.museSoftWhite)
                    
                    Text(frequency.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.museLightGray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.museLightGray)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.thinMaterial)
                            .opacity(0.5)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Breathwork Placeholder View
struct BreathworkPlaceholderView: View {
    let onDismiss: () -> Void
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    var body: some View {
        ZStack {
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "wind")
                    .font(.system(size: 80))
                    .foregroundColor(.museTeal.opacity(0.5))
                
                Text("Breathwork Experience")
                    .font(.museDisplaySmall())
                    .foregroundColor(.museSoftWhite)
                
                Text("Immersive breathwork sessions coming soon!")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text("Close")
                        .font(.museButtonLarge())
                        .foregroundColor(.museSoftWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.museDarkGray)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Source Button
struct SourceButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isDisabled: Bool = false
    var isComingSoon: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isDisabled ? .museLightGray : color)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDisabled ? Color.museMediumGray.opacity(0.3) : color.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.museHeadline())
                        .foregroundColor(isDisabled ? .museLightGray : .museSoftWhite)
                    
                    Text(subtitle)
                        .font(.museCaption())
                        .foregroundColor(.museLightGray)
                }
                
                Spacer()
                
                if isComingSoon {
                    Text("Soon")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.museTeal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.museTeal.opacity(0.15)))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.museLightGray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thinMaterial)
                            .opacity(0.5)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.7 : 1)
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .museSoftWhite : .museLightGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.white.opacity(0.08))
                        .background(
                            Capsule()
                                .fill(.thinMaterial)
                                .opacity(isSelected ? 0 : 0.5)
                        )
                )
                .clipShape(Capsule())
        }
    }
}

// MARK: - Affirmation Select Row
struct AffirmationSelectRow: View {
    let affirmation: Affirmation
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .museSuccessGreen : .museLightGray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(affirmation.text)
                        .font(.museBodyMedium())
                        .foregroundColor(.museSoftWhite)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(affirmation.category.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.museGradientStart)
                }
                
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.museSuccessGreen.opacity(0.1) : Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                            .opacity(isSelected ? 0.3 : 0.5)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.museSuccessGreen.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Affirmation Selection Card (for horizontal scroll)
struct AffirmationSelectionCard: View {
    let affirmation: Affirmation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .museSuccessGreen : .museLightGray)
                    
                    Spacer()
                }
                
                Text(affirmation.text)
                    .font(.museBodySmall())
                    .foregroundColor(.museSoftWhite)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.museAccentBlue.opacity(0.2) : Color.museMediumGray.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.museAccentBlue : Color.museMediumGray, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

// MARK: - Countdown View
struct CountdownView: View {
    @Binding var countdown: Int
    let tipIndex: Int
    let onComplete: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    // Cycling tips for each session
    private let tips = [
        "Say the affirmations out loud or in your head. You choose.",
        "Affirmations activate brain pathways related to self-processing.",
        "Affirmations can buffer stress responses.",
        "Self-affirmation activates the brain's reward centers."
    ]
    
    private var currentTip: String {
        tips[tipIndex % tips.count]
    }
    
    var body: some View {
        ZStack {
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(.museSoftWhite)
                    .scaleEffect(scale)
                
                Spacer()
                
                // Tip text at the bottom
                Text(currentTip)
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
            }
            .onChange(of: countdown) { oldValue, newValue in
                if newValue > 0 {
                    withAnimation(.spring(response: 0.3)) {
                        scale = 1.3
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3)) {
                            scale = 1.0
                        }
                    }
                }
                
                if newValue == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        onComplete()
                    }
                }
            }
            .onAppear {
                if countdown == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onComplete()
                    }
                }
            }
        }
    }
}

// MARK: - Background Music Track




// MARK: - Affirmation Display View
struct AffirmationDisplayView: View {
    let affirmations: [Affirmation]
    let duration: StartAffirmationsView.AffirmationDuration
    let onComplete: () -> Void
    
    @StateObject private var musicManager = BackgroundMusicManager.shared
    @StateObject private var speechService = SpeechService.shared

    @State private var randomizedAffirmations: [Affirmation] = []
    @State private var currentIndex = 0
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var opacity: Double = 1.0
    @State private var sessionStartTime: Date = Date()
    @State private var completedAffirmations: [String] = []
    @State private var lastShownAffirmationId: UUID? = nil
    @State private var showVolumeSlider = false
    @State private var isStopped = false  // Flag to prevent scheduled tasks from running after stop
    @State private var isFinishingUp = false // Flag to let current affirmation finish before stopping
    @State private var isAnimatingGradient = false
    @State private var showControls = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Phase of the current affirmation
    enum AffirmationPhase {
        case speaking      // Voice is speaking
        case yourTurn      // User's turn to repeat
        case transitioning // Fading to next affirmation
    }
    
    @State private var currentPhase: AffirmationPhase = .speaking
    
    // Time for user to repeat the affirmation (in seconds)
    private let userRepeatDuration: Double = 6.0
    
    var body: some View {
        ZStack {
            // Background
            // Background
            if let uiImage = UIImage(named: "backgroundjungle2") {
                GeometryReader { geometry in
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .overlay(.ultraThinMaterial)
                        .overlay(Color.black.opacity(0.3))
                }
                .ignoresSafeArea()
            } else {
                Color.museDeepNavy
                    .ignoresSafeArea(.all)
            }
            
            // Progress bar
            VStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.museDarkGray.opacity(0.3))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .hueRotation(.degrees(isAnimatingGradient ? 360 : 0))
                            .frame(width: geometry.size.width * min(1.0, Double(elapsedTime) / Double(duration.seconds)))
                            .animation(.linear(duration: 1.0), value: elapsedTime) // Smooth movement
                    }
                }
                .frame(height: 4)
                .padding(.top, 60)
                
                Spacer()
            }
            .opacity(showControls ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: showControls)
            
            // Affirmation text and phase indicator
            if currentIndex < randomizedAffirmations.count {
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Phase indicator
                    HStack(spacing: 12) {
                        if currentPhase == .speaking {
                            // Speaking indicator with animation
                            HStack(spacing: 6) {
                                ForEach(0..<3, id: \.self) { i in
                                    SoundWaveBar(delay: Double(i) * 0.15)
                                }
                            }
                            .frame(width: 24, height: 16)
                            
                            Text("Listen...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.museGradientStart)
                        } else if currentPhase == .yourTurn {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.museTeal)
                            
                            Text("Your turn...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.museTeal)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .frame(height: 44) // Fixed height to prevent layout shift
                    .background(
                        Capsule()
                            .fill(currentPhase == .speaking ? Color.museGradientStart.opacity(0.15) : Color.museTeal.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(currentPhase == .speaking ? Color.museGradientStart.opacity(0.3) : Color.museTeal.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .opacity(currentPhase == .transitioning ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: currentPhase)
                    
                    // Affirmation text
                    Text(randomizedAffirmations[currentIndex].text)
                        .font(.system(size: 36, weight: .medium, design: .serif))
                        .foregroundColor(.museSoftWhite)
                        .multilineTextAlignment(.center)
                        .lineSpacing(12)
                        .padding(.horizontal, 40)
                        .frame(maxWidth: .infinity)
                        .opacity(opacity)
                    
                    Spacer()
                    

                }
            }
            
            // Top controls - Close button and Volume
            VStack {
                HStack {
                    // Volume button
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) {
                            showVolumeSlider.toggle()
                        }
                    }) {
                        Image(systemName: musicManager.volume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                            .padding(14)
                            .background(
                                Circle()
                                    .fill(Color.museDarkGray.opacity(0.8))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.museMediumGray.opacity(0.6), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.leading, 30)
                    .padding(.top, 80)
                    
                    Spacer()
                    
                    // Close button
                    Button(action: { stop() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                            .padding(14)
                            .background(
                                Circle()
                                    .fill(Color.museDarkGray.opacity(0.8))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.museMediumGray.opacity(0.6), lineWidth: 1)
                                        )
                            )
                    }
                    .padding(.trailing, 30)
                    .padding(.top, 80)
                }
                Spacer()
            }
            .opacity(showControls ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: showControls)
            
            // Volume slider overlay
            if showVolumeSlider {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.museLightGray)
                        
                        Slider(value: Binding(
                            get: { Double(musicManager.volume) },
                            set: { musicManager.setVolume(Float($0)) }
                        ), in: 0...1)
                        .accentColor(.museGradientStart)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.museLightGray)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.museDarkGray.opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.museMediumGray.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .ignoresSafeArea(.all)
        .statusBar(hidden: true)
        .onAppear { start() }
        .onDisappear { stop() }
        .onTapGesture {
            if showVolumeSlider {
                withAnimation(.spring(response: 0.3)) {
                    showVolumeSlider = false
                }
            } else {
                // Toggle controls visibility
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls.toggle()
                }
            }
        }
    }
    
    // MARK: - Session Control
    private func start() {
        print("🚀 AffirmationDisplayView: start() called")
        print("🚀 AffirmationDisplayView: affirmations count = \(affirmations.count)")
        
        guard !affirmations.isEmpty else {
            print("⚠️ AffirmationDisplayView: No affirmations! Completing...")
            onComplete()
            return
        }
        
        // Reset stopped flag
        isStopped = false
        isFinishingUp = false
        
        // Start rainbow animation
        withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
            isAnimatingGradient = true
        }
        
        sessionStartTime = Date()
        completedAffirmations = []
        // Use affirmations as provided (parent view handles shuffling/ordering)
        randomizedAffirmations = affirmations
        currentIndex = 0
        
        print("🚀 AffirmationDisplayView: First affirmation: \(randomizedAffirmations.first?.text.prefix(30) ?? "none")...")
        
        // Start background music with fade in
        musicManager.play(fadeInDuration: 2.0)
        
        // Prefetch upcoming affirmations (next 3) to prevent delays
        for i in 1...min(3, randomizedAffirmations.count - 1) {
            speechService.prefetch(randomizedAffirmations[i].text)
        }
        
        // Start speaking the first affirmation
        print("🚀 AffirmationDisplayView: Calling speakCurrentAffirmation()...")
        speakCurrentAffirmation()
        
        // Overall session timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
            if elapsedTime >= duration.seconds {
                // Instead of stopping immediately, mark as finishing up
                // This allows the current affirmation to complete (AI speech + user turn)
                isFinishingUp = true
            }
        }
    }
    
    private func speakCurrentAffirmation() {
        print("🎤 speakCurrentAffirmation() called, currentIndex = \(currentIndex)")
        
        // Check if session was stopped
        guard !isStopped else {
            print("🛑 speakCurrentAffirmation: Session stopped, not speaking")
            return
        }
        
        guard currentIndex < randomizedAffirmations.count else {
            print("⚠️ speakCurrentAffirmation: Index out of bounds!")
            return
        }
        
        currentPhase = .speaking
        let text = randomizedAffirmations[currentIndex].text
        
        print("🎤 Speaking text: \(text)")
        
        // Speak the affirmation using OpenAI TTS
        speechService.speak(text) {
            // Voice finished speaking, transition to user's turn
            DispatchQueue.main.async {
                // Check if stopped before transitioning
                guard !isStopped else {
                    print("🛑 Speech complete but session stopped, not transitioning")
                    return
                }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPhase = .yourTurn
                }
                
                // Auto-advance after userRepeatDuration if user doesn't tap
                DispatchQueue.main.asyncAfter(deadline: .now() + userRepeatDuration) {
                    // Check if stopped before auto-advancing
                    guard !isStopped else {
                        print("🛑 Auto-advance cancelled, session stopped")
                        return
                    }
                    if currentPhase == .yourTurn {
                        transitionToNext()
                    }
                }
            }
        }
    }
    
    private func transitionToNext() {
        // Check if session was stopped or needs to finish
        guard !isStopped else {
            print("🛑 transitionToNext: Session stopped, not transitioning")
            return
        }
        
        // If time is up, end the session now that the verification cycle is complete
        if isFinishingUp {
            print("🛑 Time is up! Finishing session gracefully after affirmation complete.")
            endSessionWithPadding()
            return
        }
        
        currentPhase = .transitioning
        
        // Stop any ongoing speech
        speechService.stopSpeaking()
        
        if currentIndex < randomizedAffirmations.count {
            completedAffirmations.append(randomizedAffirmations[currentIndex].text)
            lastShownAffirmationId = randomizedAffirmations[currentIndex].id
        }
        
        // Quick fade out
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Check if stopped before continuing
            guard !isStopped else {
                print("🛑 Fade transition cancelled, session stopped")
                return
            }
            
            // Move to next affirmation
            currentIndex = (currentIndex + 1) % randomizedAffirmations.count
            
            // Reshuffle if we've gone through all
            if currentIndex == 0 {
                reshuffleWithoutRepeat()
            }
            
            // Prefetch the one AFTER this one to keep buffer full
            let nextIndex = (currentIndex + 1) % randomizedAffirmations.count
            speechService.prefetch(randomizedAffirmations[nextIndex].text)
            
            // Start speaking FIRST before fade in (voice starts immediately)
            speakCurrentAffirmation()
            
            // Then fade in the text
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 1.0
            }
        }
    }
    
    // Reshuffle ensuring the last shown affirmation isn't first
    private func endSessionWithPadding() {
        // Stop sounds immediately
        speechService.stopSpeaking()
        musicManager.stop(fadeOutDuration: 1.0)
        
        // Wait 5 seconds of silence
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // If in background, ensure music stays off
            if UIApplication.shared.applicationState != .active {
                musicManager.stop()
            }
            
            // Save session
            let elapsed = Int(Date().timeIntervalSince(sessionStartTime))
            if !completedAffirmations.isEmpty {
                let session = AffirmationSession(
                    date: Date(),
                    duration: TimeInterval(elapsed),
                    affirmationCount: completedAffirmations.count,
                    affirmations: completedAffirmations
                )
                modelContext.insert(session)
            }
            
            onComplete()
        }
    }
    
    private func reshuffleWithoutRepeat() {
        guard affirmations.count > 1 else {
            randomizedAffirmations = affirmations
            return
        }
        
        var shuffled = affirmations.shuffled()
        
        // If the first item is the same as the last shown, move it elsewhere
        if let lastId = lastShownAffirmationId, shuffled.first?.id == lastId {
            if let firstItem = shuffled.first {
                shuffled.removeFirst()
                let insertIndex = Int.random(in: 1..<shuffled.count)
                shuffled.insert(firstItem, at: insertIndex)
            }
        }
        
        randomizedAffirmations = shuffled
    }
    
    private func stop() {
        print("🛑 AffirmationDisplayView: stop() called")
        
        // Set stopped flag FIRST to prevent any scheduled tasks from running
        isStopped = true
        
        // Stop speech but keep background music playing
        speechService.stopSpeaking()
        
        // Invalidate timer
        timer?.invalidate()
        timer = nil
        
        // Only save session if we actually started
        guard !completedAffirmations.isEmpty || elapsedTime > 0 else {
            onComplete()
            return
        }
        
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let affirmationCount = completedAffirmations.count
        
        let session = AffirmationSession(
            date: sessionStartTime,
            duration: sessionDuration,
            affirmationCount: affirmationCount,
            affirmations: completedAffirmations
        )
        modelContext.insert(session)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving session: \(error)")
        }
        
        onComplete()
    }
}

// MARK: - Sound Wave Animation Bar
struct SoundWaveBar: View {
    let delay: Double
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.museGradientStart)
            .frame(width: 3, height: isAnimating ? 16 : 6)
            .animation(
                Animation.easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    StartAffirmationsView()
}
