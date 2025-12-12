import SwiftUI

struct StartAffirmationsView: View {
    @StateObject private var storage = StorageService.shared
    @State private var selectedAffirmations: Set<UUID> = []
    @State private var duration: AffirmationDuration = .oneMinute
    @State private var isActive = false
    
    enum AffirmationDuration: String, CaseIterable {
        case oneMinute = "1 min"
        case twoMinutes = "2 min"
        case fiveMinutes = "5 min"
        case tenMinutes = "10 min"
        
        var seconds: Int {
            switch self {
            case .oneMinute: return 60
            case .twoMinutes: return 120
            case .fiveMinutes: return 300
            case .tenMinutes: return 600
            }
        }
    }
    
    var selectedAffirmationsList: [Affirmation] {
        storage.savedAffirmations.filter { selectedAffirmations.contains($0.id) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.museGradientStart)
                    
                    Text("Start Affirmations")
                        .font(.museDisplayMedium())
                        .foregroundColor(.museSoftWhite)
                }
                
                // Selection Section
                if !storage.savedAffirmations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Affirmations")
                            .font(.museHeadline())
                            .foregroundColor(.museSoftWhite)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(storage.savedAffirmations) { affirmation in
                                    AffirmationSelectionCard(
                                        affirmation: affirmation,
                                        isSelected: selectedAffirmations.contains(affirmation.id)
                                    ) {
                                        toggleSelection(affirmation)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                } else {
                    Text("Save affirmations from Discover to use this feature")
                        .font(.museBodyMedium())
                        .foregroundColor(.museLightGray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.museDarkGray)
                        )
                }
                
                // Duration Selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.museHeadline())
                        .foregroundColor(.museSoftWhite)
                    
                    HStack(spacing: 12) {
                        ForEach(AffirmationDuration.allCases, id: \.self) { durationOption in
                            Button(action: {
                                duration = durationOption
                            }) {
                                Text(durationOption.rawValue)
                                    .font(.museButtonMedium())
                                    .foregroundColor(duration == durationOption ? .museSoftWhite : .museLightGray)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(duration == durationOption ? Color.museAccentBlue : Color.museDarkGray)
                                    )
                            }
                        }
                    }
                }
                
                // Start Button
                if !selectedAffirmations.isEmpty {
                    Button(action: {
                        startCountdown()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Start")
                                .font(.museButtonLarge())
                        }
                        .foregroundColor(.museSoftWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.museGradientStart, Color.museGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.museDarkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.museGradientStart.opacity(0.3), Color.museGradientEnd.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        .fullScreenCover(isPresented: $isActive) {
            ImmersiveAffirmationView(
                affirmations: selectedAffirmationsList,
                duration: duration,
                onComplete: {
                    stopAffirmations()
                }
            )
        }
    }
    
    private func toggleSelection(_ affirmation: Affirmation) {
        if selectedAffirmations.contains(affirmation.id) {
            selectedAffirmations.remove(affirmation.id)
        } else {
            selectedAffirmations.insert(affirmation.id)
        }
    }
    
    private func startCountdown() {
        isActive = true
    }
    
    private func stopAffirmations() {
        isActive = false
    }
}

// MARK: - Affirmation Selection Card
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
    let onComplete: () -> Void
    @State private var scale: CGFloat = 1.0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.museDeepNavy
                .ignoresSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(.museSoftWhite)
                    .scaleEffect(scale)
                
                Text("Get ready...")
                    .font(.museHeadline())
                    .foregroundColor(.museLightGray)
            }
            .onChange(of: countdown) { oldValue, newValue in
                // Animate scale on countdown change
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
                
                // When countdown reaches 0, complete
                if newValue == 0 {
                    // Show "0" briefly, then transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        onComplete()
                    }
                }
            }
            .onAppear {
                // Check if countdown is already 0 when view appears
                if countdown == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onComplete()
                    }
                }
            }
        }
    }
}

// MARK: - Affirmation Display View
struct AffirmationDisplayView: View {
    let affirmations: [Affirmation]
    let duration: StartAffirmationsView.AffirmationDuration
    let onComplete: () -> Void
    
    @State private var randomizedAffirmations: [Affirmation] = []
    @State private var currentIndex = 0
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var displayTimer: Timer?
    @State private var opacity: Double = 1.0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.museDeepNavy
                .ignoresSafeArea(.all)
            
            // Progress indicator at top
            VStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.museDarkGray.opacity(0.3))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color.museGradientStart, Color.museGradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(1.0, Double(elapsedTime) / Double(duration.seconds)))
                    }
                }
                .frame(height: 4)
                .padding(.top, 60)
                
                Spacer()
            }
            
            // Current affirmation - centered and large
            if currentIndex < randomizedAffirmations.count {
                VStack(spacing: 0) {
                    Spacer()
                    
                    Text(randomizedAffirmations[currentIndex].text)
                        .font(.system(size: 48, weight: .medium, design: .rounded))
                        .foregroundColor(.museSoftWhite)
                        .multilineTextAlignment(.center)
                        .lineSpacing(20)
                        .padding(.horizontal, 50)
                        .frame(maxWidth: .infinity)
                        .opacity(opacity)
                    
                    Spacer()
                }
            }
            
            // Exit button in top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        stop()
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
                    .padding(.top, 60)
                }
                Spacer()
            }
        }
        .ignoresSafeArea(.all)
        .statusBar(hidden: true)
        .onAppear {
            start()
        }
        .onDisappear {
            stop()
        }
    }
    
    private func start() {
        guard !affirmations.isEmpty else {
            onComplete()
            return
        }
        
        // Randomize affirmations
        randomizedAffirmations = affirmations.shuffled()
        currentIndex = 0
        
        // Timer for total duration
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            elapsedTime += 1
            if elapsedTime >= duration.seconds {
                stop()
            }
        }
        
        // Timer for cycling affirmations (5 seconds each)
        displayTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            transitionToNext()
        }
    }
    
    private func transitionToNext() {
        // Fade out (dissolve)
        withAnimation(.easeOut(duration: 0.5)) {
            opacity = 0
        }
        
        // After fade out, change to next affirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Move to next (loop if needed)
            currentIndex = (currentIndex + 1) % randomizedAffirmations.count
            
            // If we've gone through all, reshuffle for variety
            if currentIndex == 0 {
                randomizedAffirmations = affirmations.shuffled()
            }
            
            // Fade in with new affirmation (dissolve)
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
        }
    }
    
    private func stop() {
        timer?.invalidate()
        displayTimer?.invalidate()
        timer = nil
        displayTimer = nil
        onComplete()
    }
}

#Preview {
    StartAffirmationsView()
}

