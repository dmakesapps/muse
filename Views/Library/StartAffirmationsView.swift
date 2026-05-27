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
    @State private var showVolumeSlider = false
    @StateObject private var musicManager = BackgroundMusicManager.shared
    
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
                // Top controls - Volume left, X right (matching AffirmationDisplayView)
                topControls
                    .opacity(showControls ? 1 : 0)
                
                // Top info bar - breathing pattern indicators
                if showControls {
                    topInfoBar
                        .padding(.top, 16)
                }
                
                Spacer()
                
                // Breathing circle
                breathingCircle
                
                Spacer()
                
                // Bottom controls - Play/Pause and Timer (matching Manifest style)
                bottomControls
                    .padding(.bottom, 40)
                    .opacity(showControls ? 1 : 0)
            }
            
            // Volume slider overlay
            if showVolumeSlider {
                volumeSliderOverlay
            }
        }
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            if showVolumeSlider {
                withAnimation(.spring(response: 0.3)) {
                    showVolumeSlider = false
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls.toggle()
                }
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
    
    // MARK: - Top Controls (matching AffirmationDisplayView)
    private var topControls: some View {
        HStack {
            // Volume button (left)
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
            
            Spacer()
            
            // Close button (right)
            Button(action: {
                isRunning = false
                // Log the breathwork session
                ProgressService.shared.logBreathworkSession(duration: elapsedTime)
                onComplete()
            }) {
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
        }
        .padding(.top, 70)
    }
    
    // MARK: - Top Info Bar (compact breathing pattern indicators)
    private var topInfoBar: some View {
        HStack(spacing: 16) {
            // Inhale indicator
            phaseIndicator(
                icon: "nose",
                duration: pattern.phases.first { $0.type == .inhale }?.duration ?? 4
            )
            
            // HoldIn indicator (if pattern has holdIn phase)
            if let holdIn = pattern.phases.first(where: { $0.type == .holdIn }), holdIn.duration > 0 {
                phaseIndicator(
                    icon: "pause.circle",
                    duration: holdIn.duration
                )
            }
            
            // Exhale indicator
            phaseIndicator(
                icon: "mouth",
                duration: pattern.phases.first { $0.type == .exhale }?.duration ?? 4
            )
            
            // HoldOut indicator (if pattern has holdOut phase after exhale)
            if let holdOut = pattern.phases.first(where: { $0.type == .holdOut }), holdOut.duration > 0 {
                phaseIndicator(
                    icon: "pause.circle",
                    duration: holdOut.duration
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.museDarkGray.opacity(0.6))
                .overlay(
                    Capsule()
                        .stroke(Color.museMediumGray.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    // Helper for consistent phase indicator styling
    private func phaseIndicator(icon: String, duration: TimeInterval) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.museSoftWhite.opacity(0.8))
                .frame(height: 22) // Fixed height for alignment
            
            Text("\(Int(duration))s")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.museSuccessGreen)
                .frame(height: 16) // Fixed height for alignment
        }
        .frame(width: 40) // Fixed width for consistent spacing
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
    
    // MARK: - Bottom Controls (Play/Pause centered, Timer below)
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Pause/Play button (centered, matching Manifest style)
            Button(action: {
                isPaused.toggle()
            }) {
                Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.museSoftWhite)
                    .shadow(color: .black.opacity(0.3), radius: 10)
            }
            
            // Timer display
            Text(formattedTime)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.museSoftWhite)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.museDarkGray.opacity(0.6))
                        .overlay(
                            Capsule()
                                .stroke(Color.museMediumGray.opacity(0.4), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Volume Slider Overlay
    private var volumeSliderOverlay: some View {
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
            .padding(.bottom, 180)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        // Stop breathwork sounds but keep background music playing
        phasePlayers.values.forEach { $0.stop() }
        
        // Wait 5 seconds before completing (moment of silence)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
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
    @EnvironmentObject var entitlementManager: EntitlementManager
    @StateObject private var storage = StorageService.shared
    
    var initialPracticeMode: PracticeMode? = nil
    var openJournalOnAppear: Bool = false
    
    @State private var selectedMode: PracticeMode? = nil
    @State private var selectedSource: AffirmationSource? = nil
    @State private var selectedAffirmations: Set<UUID> = []
    @State private var useRandom: Bool = false
    @State private var selectedCategories: Set<String> = []
    @State private var duration: AffirmationDuration = .oneMinute
    @State private var isActive = false
    @State private var activeBreathworkPattern: BreathingPattern? // Use item for sheet logic
    @State private var allAffirmations: [Affirmation] = []
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    @State private var showManifestView = false
    @State private var activeFrequency: FrequencyItem? = nil // For frequencies immersive view
    @State private var showAIChat = false // For AI-generated affirmations chat
    @State private var searchText: String = "" // Search affirmations by text or category
    @State private var isAffirmationsListCollapsed: Bool = false // Collapse/expand affirmations list
    @State private var isSavedAIExpanded: Bool = false // Expand saved AI affirmations for selection
    @State private var showJournalView: Bool = false // Show journal view
    @State private var isLoadingLibrary: Bool = false // Loading state for library affirmations
    @State private var spinnerRotation: Double = 0 // Spinner rotation angle
    @State private var pendingPremiumSessionStart = false
    
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
        switch selectedSource {
        case .library:
            return allAffirmations
        case .aiGenerated:
            return storage.aiGeneratedAffirmations
        case .favorites, .none:
            return storage.savedAffirmations
        }
    }
    
    // Get unique categories from current affirmation pool
    private var availableCategories: [String] {
        let categories = currentAffirmationPool.map { $0.category }
        return Array(Set(categories)).sorted()
    }
    
    // Filter affirmations by selected categories and search text
    private var filteredAffirmations: [Affirmation] {
        var result: [Affirmation] = []

        if selectedCategories.isEmpty {
            result = currentAffirmationPool
        } else {
            if selectedCategories.contains("Mine") {
                result.append(contentsOf: storage.savedAffirmations)
            }

            let otherCategories = selectedCategories.filter { $0 != "Mine" }
            if !otherCategories.isEmpty {
                let otherAffirmations = currentAffirmationPool.filter { otherCategories.contains($0.category) }
                result.append(contentsOf: otherAffirmations)
            }

            var seenIds = Set<UUID>()
            result = result.filter { seenIds.insert($0.id).inserted }
        }
        
        // Filter by search text (searches both affirmation text and category name)
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            result = result.filter { affirmation in
                affirmation.text.lowercased().contains(lowercasedSearch) ||
                affirmation.category.lowercased().contains(lowercasedSearch)
            }
        }
        
        return result
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
                    Button(action: {
                        attemptSessionStart()
                    }) {
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
        .fullScreenCover(isPresented: $showJournalView) {
            JournalView()
        }
        .onChange(of: entitlementManager.isPremium) { _, isPremium in
            guard isPremium, pendingPremiumSessionStart else { return }
            pendingPremiumSessionStart = false
            isActive = true
        }
        .onChange(of: entitlementManager.showPaywall) { _, isShowingPaywall in
            if !isShowingPaywall && !entitlementManager.isPremium {
                pendingPremiumSessionStart = false
            }
        }
        .onAppear {
            guard entitlementManager.isPremium else {
                entitlementManager.triggerPaywall(source: .sessionLimit, presenter: .practice)
                return
            }
            if let initialPracticeMode {
                selectedMode = initialPracticeMode
            }
            if openJournalOnAppear {
                showJournalView = true
            }
        }
        .paywallFullScreenCover(presenter: .practice)
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
                    guard entitlementManager.requiresPremium(presenter: .practice) else { return }
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
                    guard entitlementManager.requiresPremium(presenter: .practice) else { return }
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
                    guard entitlementManager.requiresPremium(presenter: .practice) else { return }
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
                    guard entitlementManager.requiresPremium(presenter: .practice) else { return }
                    showManifestView = true
                }
                
                // Journal Button
                PracticeModeButton(
                    title: "Journal",
                    subtitle: "Reflect on your day",
                    icon: "book.closed.fill",
                    color: .orange,
                    isDisabled: false
                ) {
                    guard entitlementManager.requiresPremium(presenter: .practice) else { return }
                    showJournalView = true
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
                        guard entitlementManager.requiresPremium(presenter: .practice) else { return }
                        activeBreathworkPattern = .boxBreathing
                    }
                    
                    BreathworkPatternButton(
                        title: "4-7-8 Relaxation",
                        subtitle: "4-7-8 pattern • Sleep aid",
                        icon: "moon.fill",
                        color: .museTeal
                    ) {
                        guard entitlementManager.requiresPremium(presenter: .practice) else { return }
                        activeBreathworkPattern = .relaxation478
                    }
                    
                    BreathworkPatternButton(
                        title: "4-6 Calming",
                        subtitle: "4-6 pattern • Simple calm",
                        icon: "leaf.fill",
                        color: .green
                    ) {
                        guard entitlementManager.requiresPremium(presenter: .practice) else { return }
                        activeBreathworkPattern = .calming46
                    }
                    
                    BreathworkPatternButton(
                        title: "Energizing Breath",
                        subtitle: "2-1-4-1 pattern • Energy boost",
                        icon: "bolt.fill",
                        color: .orange
                    ) {
                        guard entitlementManager.requiresPremium(presenter: .practice) else { return }
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
                                guard entitlementManager.requiresPremium(presenter: .practice) else { return }
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
                        subtitle: isLoadingLibrary ? "Loading..." : "Browse all available affirmations",
                        icon: isLoadingLibrary ? "arrow.triangle.2.circlepath" : "list.bullet",
                        color: .museAccentBlue,
                        isDisabled: isLoadingLibrary,
                        isLoading: isLoadingLibrary
                    ) {
                        loadLibraryAffirmations()
                    }
                    
                    // AI Generated Button
                    SourceButton(
                        title: "AI Generated",
                        subtitle: "Create personalized affirmations",
                        icon: "sparkles",
                        color: .museTeal,
                        isDisabled: false, // We keep it enabled to trigger the paywall on tap
                        isComingSoon: false
                    ) {
                        if entitlementManager.canUseAIFeatures(presenter: .practice) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSource = .aiGenerated
                            }
                        }
                    }
                }
                .padding(.top, 20)
                
                // Loading Overlay
                if isLoadingLibrary {
                    VStack(spacing: 16) {
                        ZStack {
                            // Use SwiftUI's native ProgressView for guaranteed animation
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .museAccentBlue))
                                .scaleEffect(2.5)
                            
                            // Brain icon in the center (offset slightly to not overlap spinner)
                        }
                        .frame(width: 60, height: 60)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 28))
                            .foregroundColor(.museAccentBlue)
                        
                        Text("Loading your neural library...")
                            .font(.museBodyMedium())
                            .foregroundColor(.museLightGray)
                    }
                    .padding(.top, 40)
                }
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
                    selectedCategories.removeAll()
                    searchText = ""
                    isAffirmationsListCollapsed = false
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
                        Text("Cycle through all \(selectedCategories.isEmpty ? "saved" : "in selected categories")")
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
            
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.museLightGray)
                
                TextField("Search affirmations or categories...", text: $searchText)
                    .font(.museBodyMedium())
                    .foregroundColor(.museSoftWhite)
                    .autocorrectionDisabled()
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.museLightGray)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                            .opacity(0.5)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            // Categories Section (FlowLayout grid like Reminders page)
            if !availableCategories.isEmpty || !storage.savedAffirmations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(.museHeadline())
                        .foregroundColor(.museSoftWhite)
                    
                    FlowLayout(spacing: 8) {
                        // All option
                        CategoryBubble(
                            title: "All",
                            isSelected: selectedCategories.isEmpty,
                            color: .museGradientStart
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategories.removeAll()
                                useRandom = false
                            }
                        }
                        
                        // Mine option (user's saved affirmations)
                        if !storage.savedAffirmations.isEmpty {
                            CategoryBubble(
                                title: "Mine",
                                isSelected: selectedCategories.contains("Mine"),
                                color: .museTeal
                            ) {
                                toggleCategory("Mine")
                            }
                        }
                        
                        // Dynamic categories from content
                        ForEach(availableCategories, id: \.self) { category in
                            CategoryBubble(
                                title: category,
                                isSelected: selectedCategories.contains(category),
                                color: .museGradientStart
                            ) {
                                toggleCategory(category)
                            }
                        }
                    }
                }
            }
            
            // Affirmations List (only show if not using random)
            if !useRandom {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isAffirmationsListCollapsed.toggle()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Select Affirmations")
                                    .font(.museHeadline())
                                    .foregroundColor(.museSoftWhite)
                                
                                Image(systemName: isAffirmationsListCollapsed ? "chevron.right" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.museLightGray)
                                
                                if !filteredAffirmations.isEmpty {
                                    Text("(\(filteredAffirmations.count))")
                                        .font(.museCaption())
                                        .foregroundColor(.museLightGray)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if !filteredAffirmations.isEmpty && !isAffirmationsListCollapsed {
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
                    
                    // Use opacity-based animation for smooth collapse (avoids animating 900+ views)
                    Group {
                        if filteredAffirmations.isEmpty {
                            Text(searchText.isEmpty ? "No affirmations in this category" : "No affirmations match your search")
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
                    .frame(maxHeight: isAffirmationsListCollapsed ? 0 : nil)
                    .opacity(isAffirmationsListCollapsed ? 0 : 1)
                    .clipped()
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
                                        .fill(duration == durationOption ? Color.museAccentBlue.opacity(0.8) : Color.white.opacity(0.08))
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.thinMaterial)
                                                .opacity(0.5)
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(duration == durationOption ? Color.museAccentBlue : Color.clear, lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 20) {
            // Back button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedSource = nil
                    selectedAffirmations.removeAll()
                    useRandom = false
                    isSavedAIExpanded = false
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
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.museTeal)
                
                Text("AI Generated Affirmations")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Text("Answer a few questions and I'll create personalized affirmations just for you.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            
            // Previously Generated Section
            if !storage.aiGeneratedAffirmations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with expand/collapse toggle
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isSavedAIExpanded.toggle()
                            if !isSavedAIExpanded {
                                // Reset selections when collapsing
                                selectedAffirmations.removeAll()
                                useRandom = false
                            }
                        }
                    }) {
                        HStack {
                            Text("Previously Generated")
                                .font(.museHeadline())
                                .foregroundColor(.museSoftWhite)
                            
                            Image(systemName: isSavedAIExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.museLightGray)
                            
                            Spacer()
                            
                            Text("\(storage.aiGeneratedAffirmations.count) saved")
                                .font(.museCaption())
                                .foregroundColor(.museLightGray)
                        }
                    }
                    
                    // Expanded content
                    if isSavedAIExpanded {
                        // Random option
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
                                    .font(.system(size: 18))
                                    .foregroundColor(useRandom ? .museSoftWhite : .museTeal)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Random")
                                        .font(.museBodyMedium())
                                        .foregroundColor(.museSoftWhite)
                                    Text("Cycle through all saved")
                                        .font(.museCaption())
                                        .foregroundColor(.museLightGray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: useRandom ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(useRandom ? .museSuccessGreen : .museLightGray)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(useRandom ? Color.museTeal.opacity(0.15) : Color.white.opacity(0.08))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.thinMaterial)
                                            .opacity(0.5)
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(useRandom ? Color.museTeal : Color.clear, lineWidth: 1)
                            )
                        }
                        
                        // Selection controls (only when not using random)
                        if !useRandom {
                            HStack {
                                Text("Select Affirmations")
                                    .font(.museCaption())
                                    .foregroundColor(.museLightGray)
                                
                                Spacer()
                                
                                Button(action: {
                                    if selectedAffirmations.count == storage.aiGeneratedAffirmations.count {
                                        selectedAffirmations.removeAll()
                                    } else {
                                        selectedAffirmations = Set(storage.aiGeneratedAffirmations.map { $0.id })
                                    }
                                }) {
                                    Text(selectedAffirmations.count == storage.aiGeneratedAffirmations.count ? "Deselect All" : "Select All")
                                        .font(.museCaption())
                                        .foregroundColor(.museTeal)
                                }
                            }
                            .padding(.top, 8)
                            
                            // Affirmations list
                            VStack(spacing: 8) {
                                ForEach(storage.aiGeneratedAffirmations) { affirmation in
                                    Button(action: {
                                        if selectedAffirmations.contains(affirmation.id) {
                                            selectedAffirmations.remove(affirmation.id)
                                        } else {
                                            selectedAffirmations.insert(affirmation.id)
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: selectedAffirmations.contains(affirmation.id) ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 20))
                                                .foregroundColor(selectedAffirmations.contains(affirmation.id) ? .museSuccessGreen : .museLightGray)
                                            
                                            Text(affirmation.text)
                                                .font(.museBodyMedium())
                                                .foregroundColor(.museSoftWhite)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedAffirmations.contains(affirmation.id) ? Color.museSuccessGreen.opacity(0.1) : Color.white.opacity(0.05))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedAffirmations.contains(affirmation.id) ? Color.museSuccessGreen.opacity(0.4) : Color.clear, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Start Session button (when selections made or random enabled)
                        if useRandom || !selectedAffirmations.isEmpty {
                            Button(action: {
                                attemptSessionStart {
                                    if useRandom {
                                        selectedAffirmations = Set(storage.aiGeneratedAffirmations.map { $0.id })
                                    }
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16))
                                    Text("Start Session (\(useRandom ? storage.aiGeneratedAffirmations.count : selectedAffirmations.count) affirmations)")
                                        .font(.museButtonMedium())
                                }
                                .foregroundColor(.museSoftWhite)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.museTeal)
                                )
                            }
                            .padding(.top, 8)
                        }
                    } else {
                        // Collapsed state - quick use button
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isSavedAIExpanded = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "chevron.down.circle")
                                    .font(.system(size: 14))
                                Text("Tap to select affirmations")
                                    .font(.museBodyMedium())
                            }
                            .foregroundColor(.museLightGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.thinMaterial)
                                            .opacity(0.5)
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.top, 10)
            }
            
            // Duration Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Session Duration")
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
                                        .fill(duration == durationOption ? Color.museTeal.opacity(0.8) : Color.white.opacity(0.08))
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.thinMaterial)
                                                .opacity(0.5)
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(duration == durationOption ? Color.museTeal : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(.top, 20)
            
            // Create New Button
            Button(action: {
                showAIChat = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Create New Affirmations")
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
            .padding(.top, 20)
        }
        .fullScreenCover(isPresented: $showAIChat) {
            AIAffirmationsChatView(
                duration: duration,
                onComplete: {
                    showAIChat = false
                    selectedSource = nil
                }
            )
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
                    selectedCategories.removeAll()
                    searchText = ""
                    isAffirmationsListCollapsed = false
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
                        Text("Cycle through all \(selectedCategories.isEmpty ? "available" : "in selected categories")")
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
            
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.museLightGray)
                
                TextField("Search affirmations or categories...", text: $searchText)
                    .font(.museBodyMedium())
                    .foregroundColor(.museSoftWhite)
                    .autocorrectionDisabled()
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.museLightGray)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                            .opacity(0.5)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            // Categories Section (FlowLayout grid like Reminders page)
            if !availableCategories.isEmpty || !storage.savedAffirmations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(.museHeadline())
                        .foregroundColor(.museSoftWhite)
                    
                    FlowLayout(spacing: 8) {
                        // All option
                        CategoryBubble(
                            title: "All",
                            isSelected: selectedCategories.isEmpty,
                            color: .museAccentBlue
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategories.removeAll()
                                useRandom = false
                            }
                        }
                        
                        // Mine option (user's saved affirmations)
                        if !storage.savedAffirmations.isEmpty {
                            CategoryBubble(
                                title: "Mine",
                                isSelected: selectedCategories.contains("Mine"),
                                color: .museTeal
                            ) {
                                toggleCategory("Mine")
                            }
                        }
                        
                        // Dynamic categories from content
                        ForEach(availableCategories, id: \.self) { category in
                            CategoryBubble(
                                title: category,
                                isSelected: selectedCategories.contains(category),
                                color: .museAccentBlue
                            ) {
                                toggleCategory(category)
                            }
                        }
                    }
                }
            }
            
            // Affirmations List (only show if not using random)
            if !useRandom {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isAffirmationsListCollapsed.toggle()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Select Affirmations")
                                    .font(.museHeadline())
                                    .foregroundColor(.museSoftWhite)
                                
                                Image(systemName: isAffirmationsListCollapsed ? "chevron.right" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.museLightGray)
                                
                                if !filteredAffirmations.isEmpty {
                                    Text("(\(filteredAffirmations.count))")
                                        .font(.museCaption())
                                        .foregroundColor(.museLightGray)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if !filteredAffirmations.isEmpty && !isAffirmationsListCollapsed {
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
                    
                    // Use opacity-based animation for smooth collapse (avoids animating 900+ views)
                    Group {
                        if filteredAffirmations.isEmpty {
                            Text(searchText.isEmpty ? "No affirmations in this category" : "No affirmations match your search")
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
                    .frame(maxHeight: isAffirmationsListCollapsed ? 0 : nil)
                    .opacity(isAffirmationsListCollapsed ? 0 : 1)
                    .clipped()
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
                                        .fill(duration == durationOption ? Color.museAccentBlue.opacity(0.8) : Color.white.opacity(0.08))
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.thinMaterial)
                                                .opacity(0.5)
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(duration == durationOption ? Color.museAccentBlue : Color.clear, lineWidth: 1)
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
    
    private func toggleCategory(_ category: String) {
        withAnimation(.spring(response: 0.3)) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }

            if !selectedCategories.isEmpty {
                useRandom = true
                selectedAffirmations.removeAll()
            } else {
                useRandom = false
            }
        }
    }

    private func toggleSelection(_ affirmation: Affirmation) {
        withAnimation(.spring(response: 0.3)) {
            if selectedAffirmations.contains(affirmation.id) {
                selectedAffirmations.remove(affirmation.id)
            } else {
                selectedAffirmations.insert(affirmation.id)
            }

            // Manual picks should override random mode.
            useRandom = false
        }
    }

    private func attemptSessionStart(prepareSelection: (() -> Void)? = nil) {
        prepareSelection?()
        pendingPremiumSessionStart = true

        if entitlementManager.canPlaySession(presenter: .practice) {
            pendingPremiumSessionStart = false
            isActive = true
        }
    }
    
    private func loadLibraryAffirmations() {
        // Show loading state
        isLoadingLibrary = true
        
        // Load on background thread to prevent UI freeze
        DispatchQueue.global(qos: .userInitiated).async {
            let loaded = ContentLoader.shared.loadAffirmations()
            
            DispatchQueue.main.async {
                self.allAffirmations = loaded
                self.isLoadingLibrary = false
                
                withAnimation(.spring(response: 0.3)) {
                    self.selectedSource = .library
                }
            }
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

// BreathworkPlaceholderView removed - unused

// MARK: - Source Button
struct SourceButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isDisabled: Bool = false
    var isComingSoon: Bool = false
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with optional spinning animation
                Group {
                    if isLoading {
                        // Use native ProgressView for guaranteed animation
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: color))
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(isDisabled ? .museLightGray : color)
                    }
                }
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

// MARK: - Category Bubble (Reminders-style flowing capsule)
struct CategoryBubble: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title.capitalized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .museSoftWhite : .museLightGray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.6) : Color.white.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : Color.white.opacity(0.15), lineWidth: 1)
                )
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

// AffirmationSelectionCard removed - unused

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
    @State private var hasCalledComplete = false  // Flag to prevent double onComplete() calls
    @State private var sessionAlreadySaved = false  // Flag to prevent double session saves
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
    
    // User's selected background
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    // Time for user to repeat the affirmation (in seconds)
    private let userRepeatDuration: Double = 6.0
    
    var body: some View {
        ZStack {
            // Background - uses user's selected background with proper blur
            MuseBackgroundView(selectedBackground: selectedBackground)
                .ignoresSafeArea()
            
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
        // Stop speech but keep background music playing
        speechService.stopSpeaking()
        
        // Save session IMMEDIATELY (before the delay) to avoid context issues
        let elapsed = Int(Date().timeIntervalSince(sessionStartTime))
        if !completedAffirmations.isEmpty && !sessionAlreadySaved {
            sessionAlreadySaved = true  // Mark as saved to prevent double-save
            do {
                let session = AffirmationSession(
                    date: Date(),
                    duration: TimeInterval(elapsed),
                    affirmationCount: completedAffirmations.count,
                    affirmations: completedAffirmations
                )
                modelContext.insert(session)
                try modelContext.save()
                // Refresh the shared ProgressService so all UI updates
                ProgressService.shared.setModelContext(modelContext)
                print("✅ Session saved: \(elapsed)s, \(completedAffirmations.count) affirmations")
            } catch {
                print("❌ Error saving session: \(error)")
                // Don't crash - the session just won't be saved
            }
        }
        
        // Wait 5 seconds of silence before completing (view dismissal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            guard !isStopped && !hasCalledComplete else { return }
            hasCalledComplete = true
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
        
        // Guard against re-entry and double onComplete calls
        guard !hasCalledComplete else {
            print("🛑 AffirmationDisplayView: stop() already completed, skipping")
            return
        }
        
        // Set stopped flag FIRST to prevent any scheduled tasks from running
        isStopped = true
        
        // Stop speech but keep background music playing
        speechService.stopSpeaking()
        
        // Invalidate timer
        timer?.invalidate()
        timer = nil
        
        // Only save session if we actually started and haven't already saved
        guard (!completedAffirmations.isEmpty || elapsedTime > 0) && !sessionAlreadySaved else {
            hasCalledComplete = true
            onComplete()
            return
        }
        
        sessionAlreadySaved = true  // Mark as saved to prevent double-save
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let affirmationCount = completedAffirmations.count
        
        do {
            let session = AffirmationSession(
                date: sessionStartTime,
                duration: sessionDuration,
                affirmationCount: affirmationCount,
                affirmations: completedAffirmations
            )
            modelContext.insert(session)
            try modelContext.save()
            // Refresh the shared ProgressService so all UI updates
            ProgressService.shared.setModelContext(modelContext)
            print("✅ Session saved: \(Int(sessionDuration))s, \(affirmationCount) affirmations")
        } catch {
            print("❌ Error saving session: \(error)")
            // Don't crash - the session just won't be saved
        }
        
        hasCalledComplete = true
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
