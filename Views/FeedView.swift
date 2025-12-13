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
    // Content loaded from JSON files
    @State private var quotes: [Quote] = []
    @State private var affirmations: [Affirmation] = []
    
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
                // Vertical swipe feed using native vertical paging
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredContent.enumerated()), id: \.element.id) { index, item in
                                // Each page fills the screen
                                ZStack {
                                    Color.museDeepNavy
                                    
                                    VStack(spacing: 16) {
                                        // Category tag
                                        Text(item.category.uppercased())
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(item.tagColor)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(item.tagColor.opacity(0.15))
                                            )
                                        
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
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .id(index)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: Binding(
                        get: { currentIndex },
                        set: { if let newValue = $0 { currentIndex = newValue } }
                    ))
                }
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
                .padding(.top, 10)
                
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
                            // Toggle save state
                            if item.isSaved(storage: storage) {
                                // Remove from saved
                                if let affirmation = item.affirmation {
                                    storage.removeAffirmation(affirmation)
                                } else if let quote = item.quote {
                                    storage.removeQuote(quote)
                                }
                            } else {
                                // Add to saved
                                if let affirmation = item.affirmation {
                                    storage.saveAffirmation(affirmation)
                                } else if let quote = item.quote {
                                    storage.saveQuote(quote)
                                }
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
        .onAppear {
            // Load content from JSON files
            if quotes.isEmpty {
                quotes = ContentLoader.shared.loadQuotes().shuffled()
            }
            if affirmations.isEmpty {
                affirmations = ContentLoader.shared.loadAffirmations()
            }
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
    let category: String
    let isAffirmation: Bool
    let affirmation: Affirmation?
    let quote: Quote?
    
    // Tag color based on content type
    var tagColor: Color {
        isAffirmation ? .museGradientStart : .museTeal // Purple for affirmations, teal for quotes
    }
    
    init(affirmation: Affirmation) {
        self.id = affirmation.id
        self.text = affirmation.text
        self.author = nil
        self.category = affirmation.category
        self.isAffirmation = true
        self.affirmation = affirmation
        self.quote = nil
    }
    
    init(quote: Quote) {
        self.id = quote.id
        self.text = quote.text
        self.author = quote.author
        self.category = quote.category
        self.isAffirmation = false
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
    @State private var showFavorites = false
    
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
                            
                            Button(action: {}) {
                                Text("Unlock all")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.museSoftWhite)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.museDarkGray)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Title
                        Text("What do you want to focus on?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.museSoftWhite)
                            .padding(.horizontal, 20)
                        
                        // Make your own mix button
                        Button(action: {}) {
                            Text("Make your own mix")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.museSoftWhite)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.museMediumGray.opacity(0.5), lineWidth: 1.5)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Categories Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            MixCategoryCard(
                                title: "General",
                                icon: "globe",
                                isLocked: false,
                                action: {}
                            )
                            
                            MixCategoryCard(
                                title: "Reframe Thoughts (AI)",
                                icon: "brain.head.profile",
                                isLocked: true,
                                action: {}
                            )
                            
                            MixCategoryCard(
                                title: "Favorites",
                                icon: "heart.fill",
                                isLocked: false,
                                count: storage.savedAffirmations.count + storage.savedQuotes.count,
                                action: { showFavorites = true }
                            )
                            
                            MixCategoryCard(
                                title: "My own affirmations",
                                icon: "pencil",
                                isLocked: false,
                                action: {}
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Most popular section
                        Text("Most popular")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            MixCategoryCard(
                                title: "Christianity",
                                icon: "book.closed",
                                isLocked: false,
                                action: {}
                            )
                            
                            MixCategoryCard(
                                title: "Routine",
                                icon: "sunrise",
                                isLocked: true,
                                action: {}
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
            .sheet(isPresented: $showFavorites) {
                FavoritesView()
            }
        }
    }
}

// MARK: - Mix Category Card
struct MixCategoryCard: View {
    let title: String
    let icon: String
    let isLocked: Bool
    var count: Int = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.museDarkGray)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.museSoftWhite)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.museSoftWhite)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.museLightGray)
                } else if count > 0 {
                    Text("\(count) saved")
                        .font(.system(size: 10))
                        .foregroundColor(.museLightGray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.museDarkGray.opacity(0.5))
            )
        }
    }
}

// MARK: - Favorites View
struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @State private var selectedTab = 0
    @State private var showFeed = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.museDeepNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
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
                        
                        Text("Favorites")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        Button {
                            withAnimation { selectedTab = 0 }
                        } label: {
                            Text("Affirmations")
                                .font(.system(size: 15, weight: selectedTab == 0 ? .semibold : .regular))
                                .foregroundColor(selectedTab == 0 ? .museSoftWhite : .museLightGray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                        
                        Button {
                            withAnimation { selectedTab = 1 }
                        } label: {
                            Text("Quotes")
                                .font(.system(size: 15, weight: selectedTab == 1 ? .semibold : .regular))
                                .foregroundColor(selectedTab == 1 ? .museSoftWhite : .museLightGray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }
                    }
                    .background(
                        Capsule()
                            .fill(Color.museDarkGray.opacity(0.6))
                    )
                    .padding(.bottom, 20)
                    
                    // Show in Feed button
                    if (selectedTab == 0 && !storage.savedAffirmations.isEmpty) ||
                       (selectedTab == 1 && !storage.savedQuotes.isEmpty) {
                        Button(action: { showFeed = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                                Text("Show in Feed")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.museSoftWhite)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.museAccentBlue)
                            )
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // Content
                    if selectedTab == 0 {
                        // Affirmations
                        if storage.savedAffirmations.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "heart")
                                    .font(.system(size: 48))
                                    .foregroundColor(.museLightGray.opacity(0.5))
                                Text("No saved affirmations yet")
                                    .font(.system(size: 16))
                                    .foregroundColor(.museLightGray)
                                Text("Tap the heart icon to save")
                                    .font(.system(size: 14))
                                    .foregroundColor(.museLightGray.opacity(0.7))
                            }
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(storage.savedAffirmations) { affirmation in
                                        FavoriteCard(
                                            text: affirmation.text,
                                            author: nil,
                                            category: affirmation.category,
                                            isAffirmation: true,
                                            onDelete: {
                                                storage.removeAffirmation(affirmation)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                            }
                        }
                    } else {
                        // Quotes
                        if storage.savedQuotes.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "heart")
                                    .font(.system(size: 48))
                                    .foregroundColor(.museLightGray.opacity(0.5))
                                Text("No saved quotes yet")
                                    .font(.system(size: 16))
                                    .foregroundColor(.museLightGray)
                                Text("Tap the heart icon to save")
                                    .font(.system(size: 14))
                                    .foregroundColor(.museLightGray.opacity(0.7))
                            }
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(storage.savedQuotes) { quote in
                                        FavoriteCard(
                                            text: quote.text,
                                            author: quote.author,
                                            category: quote.category,
                                            isAffirmation: false,
                                            onDelete: {
                                                storage.removeQuote(quote)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showFeed) {
                FavoritesFeedView(showAffirmations: selectedTab == 0)
            }
        }
    }
}

// MARK: - Favorites Feed View
struct FavoritesFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    let showAffirmations: Bool
    @State private var currentIndex = 0
    
    private var items: [AnyContentItem] {
        if showAffirmations {
            return storage.savedAffirmations.map { AnyContentItem(affirmation: $0) }
        } else {
            return storage.savedQuotes.map { AnyContentItem(quote: $0) }
        }
    }
    
    private func fontSizeFor(text: String) -> CGFloat {
        let wordCount = text.split(separator: " ").count
        switch wordCount {
        case 0...5: return 32
        case 6...10: return 28
        case 11...15: return 24
        case 16...20: return 22
        default: return 20
        }
    }
    
    var body: some View {
        ZStack {
            Color.museDeepNavy
                .ignoresSafeArea()
            
            if items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 48))
                        .foregroundColor(.museLightGray.opacity(0.5))
                    Text("No favorites to show")
                        .font(.system(size: 16))
                        .foregroundColor(.museLightGray)
                }
            } else {
                // Vertical swipe feed using native vertical paging
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                ZStack {
                                    Color.museDeepNavy
                                    
                                    VStack(spacing: 16) {
                                        // Category tag
                                        Text(item.category.uppercased())
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(item.tagColor)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(item.tagColor.opacity(0.15))
                                            )
                                        
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
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .id(index)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: Binding(
                        get: { currentIndex },
                        set: { if let newValue = $0 { currentIndex = newValue } }
                    ))
                }
                .ignoresSafeArea()
            }
            
            // Close button overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.museSoftWhite)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.museDarkGray.opacity(0.8))
                            )
                    }
                    
                    Spacer()
                    
                    // Counter
                    if !items.isEmpty {
                        Text("\(currentIndex + 1) / \(items.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.museSoftWhite)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.museDarkGray.opacity(0.8))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
        }
    }
}

// MARK: - Favorite Card
struct FavoriteCard: View {
    let text: String
    let author: String?
    let category: String
    let isAffirmation: Bool
    let onDelete: () -> Void
    
    private var tagColor: Color {
        isAffirmation ? .museGradientStart : .museTeal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category tag - purple for affirmations, teal for quotes
            Text(category.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(tagColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(tagColor.opacity(0.15))
                )
            
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.museSoftWhite)
                .multilineTextAlignment(.leading)
            
            if let author = author {
                Text("— \(author)")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundColor(.museLightGray)
            }
            
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.museLightGray)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.museDarkGray.opacity(0.5))
        )
    }
}

// MARK: - Practice Popup View
struct PracticePopupView: View {
    var body: some View {
        StartAffirmationsView()
    }
}


#Preview {
    FeedView(
        onProfileTap: {},
        onMessageTap: {}
    )
}
