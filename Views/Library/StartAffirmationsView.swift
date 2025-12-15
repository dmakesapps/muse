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
                    .ignoresSafeArea()
            }
            
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
    let onComplete: () -> Void
    @State private var scale: CGFloat = 1.0
    @Environment(\.dismiss) private var dismiss
    
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

// MARK: - Background Music Track
enum BackgroundMusicTrack: String, CaseIterable, Identifiable {
    case none = "None"
    case djTaye = "Ambient Waves"
    case krishna = "Krishna C Major"
    
    var id: String { rawValue }
    
    var fileName: String? {
        switch self {
        case .none: return nil
        case .djTaye: return "DJTAYEbackground"
        case .krishna: return "KrishnaCmaj"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .djTaye: return "waveform"
        case .krishna: return "music.note"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "No background music"
        case .djTaye: return "Calm ambient waves"
        case .krishna: return "Peaceful meditation"
        }
    }
    
    /// Volume multiplier to normalize loudness across tracks
    /// Adjust these values to balance the perceived volume
    var volumeMultiplier: Float {
        switch self {
        case .none: return 0.0
        case .djTaye: return 1.0      // Reference volume
        case .krishna: return 0.5     // Krishna is louder, so reduce to 50%
        }
    }
}

// MARK: - Background Music Manager
import AVFoundation

class BackgroundMusicManager: ObservableObject {
    static let shared = BackgroundMusicManager()
    
    private var audioPlayer: AVAudioPlayer?
    @Published var volume: Float = 0.5
    @Published var isPlaying = false
    @Published var selectedTrack: BackgroundMusicTrack = .djTaye
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Get the effective volume (user volume × track multiplier)
    private var effectiveVolume: Float {
        volume * selectedTrack.volumeMultiplier
    }
    
    func play(fadeInDuration: TimeInterval = 2.0) {
        // If no track selected, don't play anything
        guard let fileName = selectedTrack.fileName else {
            print("🎵 No music track selected")
            return
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("🎵 Could not find \(fileName).mp3")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0 // Start at 0 for fade in
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            
            print("🎵 Playing: \(selectedTrack.rawValue) at volume multiplier: \(selectedTrack.volumeMultiplier)")
            
            // Fade in to effective volume (user volume × track multiplier)
            fadeToVolume(effectiveVolume, duration: fadeInDuration)
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func stop(fadeOutDuration: TimeInterval = 1.5) {
        guard isPlaying else { return }
        
        // Fade out then stop
        fadeToVolume(0, duration: fadeOutDuration) {
            self.audioPlayer?.stop()
            self.audioPlayer = nil
            self.isPlaying = false
        }
    }
    
    func setVolume(_ newVolume: Float) {
        volume = newVolume
        // Apply volume with track multiplier
        audioPlayer?.volume = newVolume * selectedTrack.volumeMultiplier
    }
    
    /// Preview a track (plays a short clip)
    func preview(track: BackgroundMusicTrack) {
        // Stop current playback first
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        
        guard let fileName = track.fileName else { return }
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = 0 // Don't loop for preview
            // Apply volume with track's multiplier for accurate preview
            audioPlayer?.volume = volume * track.volumeMultiplier
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            
            // Stop after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.audioPlayer?.stop()
                self?.isPlaying = false
            }
        } catch {
            print("Failed to preview audio: \(error)")
        }
    }
    
    func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
    
    private func fadeToVolume(_ targetVolume: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let player = audioPlayer else {
            completion?()
            return
        }
        
        let startVolume = player.volume
        let volumeDiff = targetVolume - startVolume
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Float(i) / Float(steps)
                player.volume = startVolume + (volumeDiff * progress)
                
                if i == steps {
                    completion?()
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
            } else if currentPhase == .yourTurn {
                // User tapped to proceed to next affirmation
                transitionToNext()
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
        
        sessionStartTime = Date()
        completedAffirmations = []
        randomizedAffirmations = affirmations.shuffled()
        currentIndex = 0
        
        print("🚀 AffirmationDisplayView: First affirmation: \(randomizedAffirmations.first?.text.prefix(30) ?? "none")...")
        
        // Start background music with fade in
        musicManager.play(fadeInDuration: 2.0)
        
        // Start speaking the first affirmation
        print("🚀 AffirmationDisplayView: Calling speakCurrentAffirmation()...")
        speakCurrentAffirmation()
        
        // Overall session timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
            if elapsedTime >= duration.seconds {
                stop()
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
        // Check if session was stopped
        guard !isStopped else {
            print("🛑 transitionToNext: Session stopped, not transitioning")
            return
        }
        
        currentPhase = .transitioning
        
        // Stop any ongoing speech
        speechService.stopSpeaking()
        
        if currentIndex < randomizedAffirmations.count {
            completedAffirmations.append(randomizedAffirmations[currentIndex].text)
            lastShownAffirmationId = randomizedAffirmations[currentIndex].id
        }
        
        // Fade out
        withAnimation(.easeOut(duration: 0.4)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
            
            // Fade in
            withAnimation(.easeIn(duration: 0.4)) {
                opacity = 1.0
            }
            
            // Start speaking the new affirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Final check before speaking
                guard !isStopped else {
                    print("🛑 Speaking new affirmation cancelled, session stopped")
                    return
                }
                speakCurrentAffirmation()
            }
        }
    }
    
    // Reshuffle ensuring the last shown affirmation isn't first
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
        
        // Stop speech
        speechService.stopSpeaking()
        
        // Stop background music with fade out
        musicManager.stop(fadeOutDuration: 1.5)
        
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
