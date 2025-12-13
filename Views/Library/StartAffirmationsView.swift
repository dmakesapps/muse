import SwiftUI
import SwiftData

struct StartAffirmationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @State private var selectedSource: AffirmationSource? = nil
    @State private var selectedAffirmations: Set<UUID> = []
    @State private var useRandom: Bool = false
    @State private var selectedCategory: String? = nil
    @State private var duration: AffirmationDuration = .oneMinute
    @State private var isActive = false
    
    enum AffirmationSource: String, CaseIterable {
        case favorites = "Favorites"
        case aiGenerated = "AI Generated"
        case library = "Library"
    }
    
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
    
    // Get unique categories from saved affirmations
    private var availableCategories: [String] {
        let categories = storage.savedAffirmations.map { $0.category }
        return Array(Set(categories)).sorted()
    }
    
    // Filter affirmations by selected category
    private var filteredAffirmations: [Affirmation] {
        if let category = selectedCategory {
            return storage.savedAffirmations.filter { $0.category == category }
        }
        return storage.savedAffirmations
    }
    
    // Get the affirmations to use for the session
    var selectedAffirmationsList: [Affirmation] {
        if useRandom {
            // Use all saved affirmations (or filtered by category)
            return filteredAffirmations
        } else {
            return storage.savedAffirmations.filter { selectedAffirmations.contains($0.id) }
        }
    }
    
    var body: some View {
        ZStack {
            Color.museDeepNavy
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
                    
                    Text("Start Affirmations")
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
                        // Source Selection
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                
                Spacer()
            }
            
            // Bottom Start Button
            VStack {
                Spacer()
                
                if selectedSource != nil && canStart {
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
                            LinearGradient(
                                colors: [.museGradientStart, .museGradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
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
    }
    
    private var canStart: Bool {
        if selectedSource == .favorites {
            return useRandom ? !filteredAffirmations.isEmpty : !selectedAffirmations.isEmpty
        }
        return false
    }
    
    // MARK: - Source Selection View
    private var sourceSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Source")
                .font(.museHeadline())
                .foregroundColor(.museSoftWhite)
            
            VStack(spacing: 12) {
                // Favorites Button
                SourceButton(
                    title: "Favorites",
                    subtitle: "\(storage.savedAffirmations.count) saved",
                    icon: "heart.fill",
                    color: .museGradientStart,
                    isDisabled: storage.savedAffirmations.isEmpty
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSource = .favorites
                    }
                }
                
                // AI Generated Button
                SourceButton(
                    title: "AI Generated",
                    subtitle: "Coming soon",
                    icon: "sparkles",
                    color: .museTeal,
                    isDisabled: true,
                    isComingSoon: true
                ) {
                    // Coming soon
                }
                
                // Library Button
                SourceButton(
                    title: "Library",
                    subtitle: "Coming soon",
                    icon: "books.vertical.fill",
                    color: .museAccentBlue,
                    isDisabled: true,
                    isComingSoon: true
                ) {
                    // Coming soon
                }
            }
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
                        .fill(useRandom ? Color.museGradientStart.opacity(0.15) : Color.museDarkGray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(useRandom ? Color.museGradientStart : Color.museMediumGray.opacity(0.5), lineWidth: useRandom ? 2 : 1)
                        )
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
    
    // MARK: - Library View
    private var libraryView: some View {
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
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.museAccentBlue.opacity(0.5))
                
                Text("Affirmation Library")
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Text("Coming soon! Browse and select from our curated collection of affirmations.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 60)
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
                    .fill(Color.museDarkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.museMediumGray.opacity(0.3), lineWidth: 1)
                    )
            )
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
                        .fill(isSelected ? color : Color.museDarkGray)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : Color.museMediumGray.opacity(0.5), lineWidth: 1)
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
                    .fill(isSelected ? Color.museSuccessGreen.opacity(0.1) : Color.museDarkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.museSuccessGreen.opacity(0.5) : Color.museMediumGray.opacity(0.3), lineWidth: 1)
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

// MARK: - Affirmation Display View
struct AffirmationDisplayView: View {
    let affirmations: [Affirmation]
    let duration: StartAffirmationsView.AffirmationDuration
    let onComplete: () -> Void
    
    @StateObject private var speechService = SpeechService()
    @State private var randomizedAffirmations: [Affirmation] = []
    @State private var currentIndex = 0
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var userTimer: Timer?
    @State private var speechStartTime: Date?
    @State private var opacity: Double = 1.0
    @State private var highlightedWordIndex: Int = -1
    @State private var sessionStartTime: Date = Date()
    @State private var completedAffirmations: [String] = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            Color.museDeepNavy
                .ignoresSafeArea(.all)
            
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
            
            if currentIndex < randomizedAffirmations.count {
                VStack(spacing: 0) {
                    Spacer()
                    
                    HighlightedAffirmationText(
                        text: randomizedAffirmations[currentIndex].text,
                        highlightedIndex: highlightedWordIndex,
                        highlightColor: .museAccentBlue,
                        fontSize: 48
                    )
                    .padding(.horizontal, 50)
                    .frame(maxWidth: .infinity)
                    .opacity(opacity)
                    
                    Spacer()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
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
                    .padding(.top, 60)
                }
                Spacer()
            }
        }
        .ignoresSafeArea(.all)
        .statusBar(hidden: true)
        .onAppear { start() }
        .onDisappear { stop() }
    }
    
    private func start() {
        guard !affirmations.isEmpty else {
            onComplete()
            return
        }
        
        sessionStartTime = Date()
        completedAffirmations = []
        randomizedAffirmations = affirmations.shuffled()
        currentIndex = 0
        
        startAffirmationCycle()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            elapsedTime += 1
            if elapsedTime >= duration.seconds {
                stop()
            }
        }
    }
    
    private func startAffirmationCycle() {
        guard currentIndex < randomizedAffirmations.count else { return }
        
        highlightedWordIndex = -1
        let affirmation = randomizedAffirmations[currentIndex]
        let words = affirmation.text.split(separator: " ").map { String($0) }
        let totalWords = words.count
        
        speechService.speak(affirmation.text, wordCallback: { wordIndex in
            if wordIndex >= 0 && wordIndex < totalWords {
                self.highlightedWordIndex = wordIndex
            }
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.transitionToNext()
            }
        }
    }
    
    private func transitionToNext() {
        if currentIndex < randomizedAffirmations.count {
            completedAffirmations.append(randomizedAffirmations[currentIndex].text)
        }
        
        speechService.stop()
        userTimer?.invalidate()
        userTimer = nil
        highlightedWordIndex = -1
        
        withAnimation(.easeOut(duration: 0.5)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentIndex = (currentIndex + 1) % randomizedAffirmations.count
            
            if currentIndex == 0 {
                randomizedAffirmations = affirmations.shuffled()
            }
            
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startAffirmationCycle()
            }
        }
    }
    
    private func stop() {
        speechService.stop()
        
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
        
        timer?.invalidate()
        userTimer?.invalidate()
        timer = nil
        userTimer = nil
        highlightedWordIndex = -1
        onComplete()
    }
}

// MARK: - Highlighted Affirmation Text View
struct HighlightedAffirmationText: View {
    let text: String
    let highlightedIndex: Int
    let highlightColor: Color
    let fontSize: CGFloat
    
    private var words: [String] {
        text.split(separator: " ").map { String($0) }
    }
    
    var body: some View {
        Text(attributedString)
            .font(.system(size: fontSize, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
            .lineSpacing(20)
    }
    
    private var attributedString: AttributedString {
        var attributed = AttributedString()
        let words = self.words
        
        for (index, word) in words.enumerated() {
            var wordAttributed = AttributedString(word)
            
            if index == highlightedIndex {
                wordAttributed.foregroundColor = highlightColor
            } else {
                wordAttributed.foregroundColor = .museSoftWhite
            }
            
            attributed.append(wordAttributed)
            
            if index < words.count - 1 {
                attributed.append(AttributedString(" "))
            }
        }
        
        return attributed
    }
}

#Preview {
    StartAffirmationsView()
}
