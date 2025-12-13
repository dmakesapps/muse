import SwiftUI
import UIKit

struct FeedView: View {
    @StateObject private var storage = StorageService.shared
    @State private var selectedCategory: ContentCategory = .affirmation
    @State private var currentIndex: Int = 0
    let onProfileTap: () -> Void
    let onMessageTap: () -> Void
    @State private var showMixPopup = false
    @State private var showPracticePopup = false
    
    enum ContentCategory: String {
        case affirmation = "affirmation"
        case quote = "quote"
    }
    
    // Default quotes
    @State private var quotes: [Quote] = [
        Quote(text: "Dreams get you started... Discipline keeps you going.", author: "Unknown", category: "Motivation"),
        Quote(text: "The only way to do great work is to love what you do", author: "Steve Jobs", category: "Success"),
        Quote(text: "Success is not final, failure is not fatal: it is the courage to continue that counts", author: "Winston Churchill", category: "Perseverance"),
        Quote(text: "The future belongs to those who believe in the beauty of their dreams", author: "Eleanor Roosevelt", category: "Dreams"),
        Quote(text: "It does not matter how slowly you go as long as you do not stop", author: "Confucius", category: "Progress"),
        Quote(text: "The only person you are destined to become is the person you decide to be", author: "Ralph Waldo Emerson", category: "Self-Determination"),
        Quote(text: "Believe you can and you're halfway there", author: "Theodore Roosevelt", category: "Confidence"),
        Quote(text: "You are never too old to set another goal or to dream a new dream", author: "C.S. Lewis", category: "Growth"),
        Quote(text: "The only way out is through.", author: "Robert Frost", category: "Wisdom"),
        Quote(text: "You are enough just as you are.", author: "Maya Angelou", category: "Self-Love"),
    ]
    
    // Default affirmations
    @State private var affirmations: [Affirmation] = [
        Affirmation(text: "I am capable of achieving my goals", category: "Confidence"),
        Affirmation(text: "I choose to focus on what I can control", category: "Peace"),
        Affirmation(text: "I am worthy of success and happiness", category: "Self-Worth"),
        Affirmation(text: "I trust in my ability to overcome challenges", category: "Strength"),
        Affirmation(text: "I am grateful for the opportunities in my life", category: "Gratitude"),
        Affirmation(text: "I refuse to let anyone make me doubt myself. Ever.", category: "Confidence"),
        Affirmation(text: "I am becoming the person I want to be", category: "Growth"),
        Affirmation(text: "I deserve to take care of myself", category: "Self-Care"),
        Affirmation(text: "I am confident, capable, and ready to embrace all the opportunities that come my way.", category: "Confidence"),
        Affirmation(text: "I am worthy of love, respect, and all the good things life has to offer.", category: "Self-Love"),
    ]
    
    // Filter content by selected category
    private var filteredContent: [AnyContentItem] {
        if selectedCategory == .affirmation {
            return affirmations.map { AnyContentItem(affirmation: $0) }
        } else {
            return quotes.map { AnyContentItem(quote: $0) }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.museDeepNavy
                .ignoresSafeArea()
            
            if filteredContent.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "quote.bubble")
                        .font(.system(size: 48))
                        .foregroundColor(.museLightGray.opacity(0.5))
                    
                    Text("No \(selectedCategory.rawValue.capitalized)s yet")
                        .font(.museHeadline())
                        .foregroundColor(.museLightGray)
                }
            } else {
                // Vertical swipe feed
                TabView(selection: $currentIndex) {
                    ForEach(Array(filteredContent.enumerated()), id: \.element.id) { index, item in
                        // Page content - centered using GeometryReader
                        GeometryReader { geo in
                            VStack(spacing: 16) {
                                Text(item.text)
                                    .font(.system(size: fontSizeFor(text: item.text), weight: .medium, design: .serif))
                                    .foregroundColor(.museSoftWhite)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(8)
                                
                                if let author = item.author {
                                    Text("— \(author)")
                                        .font(.system(size: fontSizeFor(text: item.text) * 0.65, weight: .regular, design: .serif))
                                        .foregroundColor(.museLightGray)
                                }
                            }
                            .padding(.horizontal, 40)
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                        .background(Color.museDeepNavy)
                        .rotationEffect(.degrees(-90))
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .rotationEffect(.degrees(90))
                .ignoresSafeArea()
                .onChange(of: selectedCategory) { _, _ in
                    currentIndex = 0
                }
            }
            
            // Fixed UI overlay
            VStack {
                // Top bar
                HStack {
                    // Profile button
                    Button(action: onProfileTap) {
                        Image(systemName: "person")
                            .font(.system(size: 20))
                            .foregroundColor(.museSoftWhite)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.museDarkGray.opacity(0.6))
                            )
                    }
                    
                    Spacer()
                    
                    // Category selector
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = .affirmation
                            }
                        } label: {
                            Text("Affirmations")
                                .font(.system(size: 15, weight: selectedCategory == .affirmation ? .semibold : .regular))
                                .foregroundColor(selectedCategory == .affirmation ? .museSoftWhite : .museLightGray)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = .quote
                            }
                        } label: {
                            Text("Quotes")
                                .font(.system(size: 15, weight: selectedCategory == .quote ? .semibold : .regular))
                                .foregroundColor(selectedCategory == .quote ? .museSoftWhite : .museLightGray)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                        }
                    }
                    .background(
                        Capsule()
                            .fill(Color.museDarkGray.opacity(0.6))
                    )
                    
                    Spacer()
                    
                    // Message button
                    Button(action: onMessageTap) {
                        Image(systemName: "message")
                            .font(.system(size: 20))
                            .foregroundColor(.museSoftWhite)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.museDarkGray.opacity(0.6))
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                
                Spacer()
                
                // Share and Heart buttons - centered
                HStack(spacing: 32) {
                    Button(action: {
                        if currentIndex < filteredContent.count {
                            shareContent(filteredContent[currentIndex])
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 22))
                            .foregroundColor(.museSoftWhite)
                    }
                    
                    Button(action: {
                        if currentIndex < filteredContent.count {
                            let item = filteredContent[currentIndex]
                            if let affirmation = item.affirmation {
                                storage.saveAffirmation(affirmation)
                            } else if let quote = item.quote {
                                storage.saveQuote(quote)
                            }
                        }
                    }) {
                        Image(systemName: currentIndex < filteredContent.count && filteredContent[currentIndex].isSaved(storage: storage) ? "heart.fill" : "heart")
                            .font(.system(size: 22))
                            .foregroundColor(currentIndex < filteredContent.count && filteredContent[currentIndex].isSaved(storage: storage) ? .red : .museSoftWhite)
                    }
                }
                .padding(.bottom, 30)
                
                // Bottom buttons
                HStack {
                    // Mix button
                    Button(action: { showMixPopup = true }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 20))
                            .foregroundColor(.museSoftWhite)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.museDarkGray.opacity(0.6))
                            )
                    }
                    
                    Spacer()
                    
                    // Practice button (center)
                    if selectedCategory == .affirmation {
                        Button(action: { showPracticePopup = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.mind.and.body")
                                    .font(.system(size: 18))
                                Text("Practice")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.museSoftWhite)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.museDarkGray.opacity(0.6))
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Placeholder for symmetry (or another button)
                    Button(action: {}) {
                        Image(systemName: "paintbrush")
                            .font(.system(size: 20))
                            .foregroundColor(.museSoftWhite)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.museDarkGray.opacity(0.6))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showMixPopup) {
            MixPopupView()
        }
        .sheet(isPresented: $showPracticePopup) {
            PracticePopupView()
        }
    }
    
    // Calculate font size based on word count
    private func fontSizeFor(text: String) -> CGFloat {
        let wordCount = text.split(separator: " ").count
        switch wordCount {
        case 0...5:
            return 32
        case 6...10:
            return 28
        case 11...15:
            return 24
        case 16...20:
            return 22
        default:
            return 20
        }
    }
    
    private func shareContent(_ item: AnyContentItem) {
        let text = item.text
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// MARK: - Content Item Wrapper
struct AnyContentItem: Identifiable {
    let id: UUID
    let text: String
    let author: String?
    let affirmation: Affirmation?
    let quote: Quote?
    
    init(affirmation: Affirmation) {
        self.id = affirmation.id
        self.text = affirmation.text
        self.author = nil
        self.affirmation = affirmation
        self.quote = nil
    }
    
    init(quote: Quote) {
        self.id = quote.id
        self.text = quote.text
        self.author = quote.author
        self.affirmation = nil
        self.quote = quote
    }
    
    func isSaved(storage: StorageService) -> Bool {
        if let affirmation = affirmation {
            return storage.isAffirmationSaved(affirmation)
        } else if let quote = quote {
            return storage.isQuoteSaved(quote)
        }
        return false
    }
}

// MARK: - Top Bar View
struct TopBarView: View {
    @Binding var selectedCategory: FeedView.ContentCategory
    let onProfileTap: () -> Void
    let onMessageTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Profile button
            Button(action: onProfileTap) {
                Image(systemName: "person.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.museSoftWhite)
            }
            
            Spacer()
            
            // Center: Category selector
            HStack(spacing: 0) {
                // Affirmations button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = .affirmation
                    }
                } label: {
                    Text("Affirmations")
                        .font(.system(size: 15, weight: selectedCategory == .affirmation ? .semibold : .regular))
                        .foregroundColor(selectedCategory == .affirmation ? .museSoftWhite : .museLightGray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                
                // Quotes button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = .quote
                    }
                } label: {
                    Text("Quotes")
                        .font(.system(size: 15, weight: selectedCategory == .quote ? .semibold : .regular))
                        .foregroundColor(selectedCategory == .quote ? .museSoftWhite : .museLightGray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            .background(
                Capsule()
                    .fill(Color.museDarkGray.opacity(0.6))
            )
            
            Spacer()
            
            // Right: Message button
            Button(action: onMessageTap) {
                Image(systemName: "message")
                    .font(.system(size: 20))
                    .foregroundColor(.museSoftWhite)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Content Card
struct ContentCard: View {
    let item: AnyContentItem
    let currentIndex: Int
    let allContent: [AnyContentItem]
    let storage: StorageService
    let onSave: () -> Void
    let onShare: () -> Void
    let isSaved: Bool
    
    @State private var saved: Bool
    
    // Calculate font size based on word count
    private var fontSize: CGFloat {
        let wordCount = item.text.split(separator: " ").count
        switch wordCount {
        case 0...5:
            return 32
        case 6...10:
            return 28
        case 11...15:
            return 24
        case 16...20:
            return 22
        default:
            return 20
        }
    }
    
    // Fixed screen dimensions - calculated ONCE, shared across ALL instances
    private static let screenWidth = UIScreen.main.bounds.width
    private static let screenHeight = UIScreen.main.bounds.height
    private static let containerWidth = screenWidth - 64 // 32 padding on each side
    
    // Fixed Y position for text - calculated from screen center
    // Position text at 40% from top (above the action buttons)
    private static let textYPosition = screenHeight * 0.4
    
    init(item: AnyContentItem, currentIndex: Int, allContent: [AnyContentItem], storage: StorageService, onSave: @escaping () -> Void, onShare: @escaping () -> Void, isSaved: Bool) {
        self.item = item
        self.currentIndex = currentIndex
        self.allContent = allContent
        self.storage = storage
        self.onSave = onSave
        self.onShare = onShare
        self.isSaved = isSaved
        _saved = State(initialValue: isSaved)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.museDeepNavy
                .ignoresSafeArea()
            
            // Text content - ABSOLUTE POSITIONING
            // Using .position() with fixed screen coordinates ensures identical placement
            VStack(spacing: 16) {
                Text(item.text)
                    .font(.system(size: fontSize, weight: .medium, design: .serif))
                    .foregroundColor(.museSoftWhite)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: Self.containerWidth)
                
                if let author = item.author {
                    Text("— \(author)")
                        .font(.system(size: fontSize * 0.65, weight: .regular, design: .serif))
                        .foregroundColor(.museLightGray)
                        .padding(.top, 8)
                }
            }
            .frame(width: Self.containerWidth)
            // ABSOLUTE POSITION: Center horizontally, fixed Y from top
            // Position uses coordinate space where (0,0) is top-left
            .position(
                x: Self.screenWidth / 2,  // Always center horizontally
                y: Self.textYPosition     // Always same Y position
            )
        }
        .onChange(of: isSaved) { oldValue, newValue in
            saved = newValue
        }
    }
}

// MARK: - Mix Popup View
struct MixPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5E6D3") // Light beige background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "8B6F47"))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(Color(hex: "E8D5C4"))
                                    )
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Unlock all")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "8B6F47"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "E8D5C4"))
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Title
                        Text("What do you want to focus on?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        // Make your own mix button
                        Button(action: {}) {
                            Text("Make your own mix")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "8B6F47"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "E8D5C4"))
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Categories Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            MixCategoryCard(
                                title: "General",
                                icon: "globe",
                                isLocked: false
                            )
                            
                            MixCategoryCard(
                                title: "Reframe Thoughts (AI)",
                                icon: "brain.head.profile",
                                isLocked: true
                            )
                            
                            MixCategoryCard(
                                title: "Favorites",
                                icon: "heart.fill",
                                isLocked: false
                            )
                            
                            MixCategoryCard(
                                title: "My own affirmations",
                                icon: "pencil",
                                isLocked: false
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Most popular section
                        Text("Most popular")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            MixCategoryCard(
                                title: "Christianity",
                                icon: "book.closed",
                                isLocked: false
                            )
                            
                            MixCategoryCard(
                                title: "routine",
                                icon: "sunrise",
                                isLocked: true
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Mix Category Card
struct MixCategoryCard: View {
    let title: String
    let icon: String
    let isLocked: Bool
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "E8D5C4").opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "E8D5C4"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "E8D5C4").opacity(0.2))
            )
        }
    }
}

// MARK: - Practice Popup View
struct PracticePopupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @State private var selectedAffirmations: Set<UUID> = []
    @State private var duration: StartAffirmationsView.AffirmationDuration = .oneMinute
    @State private var isActive = false
    
    var selectedAffirmationsList: [Affirmation] {
        storage.savedAffirmations.filter { selectedAffirmations.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.museDeepNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.museSoftWhite)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(Color.museDarkGray)
                                    )
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Title
                        Text("Start Affirmations")
                            .font(.museDisplayLarge())
                            .foregroundColor(.museSoftWhite)
                            .padding(.horizontal, 20)
                        
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
                            .padding(.horizontal, 20)
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
                                .padding(.horizontal, 20)
                        }
                        
                        // Duration Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.museHeadline())
                                .foregroundColor(.museSoftWhite)
                            
                            HStack(spacing: 12) {
                                ForEach(StartAffirmationsView.AffirmationDuration.allCases, id: \.self) { durationOption in
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
                        .padding(.horizontal, 20)
                        
                        // Start Button
                        if !selectedAffirmations.isEmpty {
                            Button(action: {
                                isActive = true
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
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
            .fullScreenCover(isPresented: $isActive) {
                ImmersiveAffirmationView(
                    affirmations: selectedAffirmationsList,
                    duration: duration,
                    onComplete: {
                        isActive = false
                        dismiss()
                    }
                )
            }
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


#Preview {
    FeedView(
        onProfileTap: {},
        onMessageTap: {}
    )
}
