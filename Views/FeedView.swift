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
    @State private var selectedTagFilter: String? = nil  // Filter by specific tag
    @State private var showCategoryPicker = false
    @State private var showBackgroundPicker = false
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    let backgroundOptions = ["backgroundjungle2", "Gradient1", "Gradient2", "SolidDark"]
    
    enum ContentCategory: String {
        case affirmation = "affirmation"
        case quote = "quote"
    }
    
    // Default quotes
    // Content loaded from JSON files
    @State private var quotes: [Quote] = []
    @State private var affirmations: [Affirmation] = []
    
    // Get all unique categories for current content type
    private var availableCategories: [String] {
        if selectedCategory == .affirmation {
            return Array(Set(affirmations.map { $0.category })).sorted()
        } else {
            return Array(Set(quotes.map { $0.category })).sorted()
        }
    }
    
    // Filter content by selected category AND tag filter
    private var filteredContent: [AnyContentItem] {
        var items: [AnyContentItem]
        
        if selectedCategory == .affirmation {
            items = affirmations.map { AnyContentItem(affirmation: $0) }
        } else {
            items = quotes.map { AnyContentItem(quote: $0) }
        }
        
        // Apply tag filter if selected
        if let tagFilter = selectedTagFilter {
            items = items.filter { $0.category == tagFilter }
        }
        
        return items
    }
    
    var body: some View {
        ZStack {
            // Background
            // Background
            // Background
            MuseBackgroundView(selectedBackground: selectedBackground)
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
                                    Color.clear
                                    
                                    VStack(spacing: 16) {
                                        // Category tag - long press to filter by category
                                        Text(item.category.uppercased())
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(item.tagColor)
                                                    .shadow(color: item.tagColor.opacity(0.3), radius: 8, x: 0, y: 4)
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(selectedTagFilter == item.category ? Color.white : Color.clear, lineWidth: 2)
                                                    )
                                            )
                                            .onLongPressGesture {
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                                impactFeedback.impactOccurred()
                                                showCategoryPicker = true
                                            }
                                        
                                        Text(item.text)
                                            .font(.system(size: fontSizeFor(text: item.text), weight: .medium, design: .serif))
                                            .foregroundColor(.museSoftWhite)
                                            .multilineTextAlignment(.center)
                                            .lineSpacing(8)
                                        
                                        if let author = item.author {
                                            Text("— \(author)")
                                                .font(.system(size: fontSizeFor(text: item.text) * 0.65, weight: .regular, design: .serif))
                                                .foregroundColor(.museLightGray)
                                                .padding(.top, 8)
                                        }
                                    }

                                    .frame(width: item.isAffirmation ? UIScreen.main.bounds.width - 64 : nil)
                                    .padding(.horizontal, item.isAffirmation ? 0 : 40)
                                    .position(item.isAffirmation ? CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.45) : CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
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
                    // Force ScrollView to recreate when category or filter changes
                    .id("\(selectedCategory.rawValue)-\(selectedTagFilter ?? "all")")
                }
                .ignoresSafeArea()
                .onChange(of: selectedCategory) { _, _ in
                    currentIndex = 0
                    selectedTagFilter = nil  // Reset filter when switching content type
                }
                .onChange(of: selectedTagFilter) { _, _ in
                    currentIndex = 0
                }
            }
            
            // Fixed UI overlay
            VStack {
                // Top bar
                HStack {
                    // Profile button
                    // Profile button (Top Left)
                    GlassIconButton(icon: "person", action: onProfileTap)
                    
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
                            .pulsingRainbowBorder()
                    )
                    
                    Spacer()
                    
                    // Message button
                    // Message button (Top Right)
                    GlassIconButton(icon: "message", action: onMessageTap)
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
                    // Mix button (Bottom Left)
                    GlassIconButton(icon: "square.grid.2x2", action: { showMixPopup = true })
                    
                    Spacer()
                    
                    // Practice button (center) - Glowing Start button style (transparent center with animated glow)
                    if selectedCategory == .affirmation {
                        GlowingStartButton(action: { showPracticePopup = true })
                    }
                    
                    Spacer()
                    
                    // Placeholder for symmetry (or another button)
                    // Paintbrush button (Bottom Right)
                    GlassIconButton(icon: "paintbrush", action: { showBackgroundPicker = true })
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
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(
                categories: availableCategories,
                selectedCategory: $selectedTagFilter,
                contentType: selectedCategory
            )
            .presentationDetents([.medium, .large])
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBackgroundPicker) {
            BackgroundPickerView(selectedBackground: $selectedBackground, options: backgroundOptions)
                // Use a larger detent or allow dynamic sizing
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
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
        // Add quotation marks to quotes
        self.text = "\"\(quote.text)\""
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
                        // Add new affirmation or other actions
            Button(action: {
                print("Add button tapped")
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.museSoftWhite)
            }
            
            Spacer()
            
            // Right: Message button
            Button(action: onMessageTap) {
                Image(systemName: "message")
                    .font(.system(size: 20))
                    .foregroundColor(.museSoftWhite)
            }
        }
        .padding(.top, 10) // Fixed safe area padding
        .padding(.horizontal, 20)
        .onAppear {
            // Start background music if enabled
            BackgroundMusicManager.shared.startIfNeeded()
        }
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



// MARK: - Reusable Glass Icon Button
struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .blendMode(.overlay) // Adds a nice blend with the background
                )
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.2)) // Slight darkening for contrast
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1) // Frosted border
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Mix Popup View
struct MixPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    @State private var showFavorites = false
    @State private var showMyAffirmations = false
    @State private var selectedCategory: String? = nil
    
    // Count of user-created affirmations
    private var userCreatedCount: Int {
        storage.savedAffirmations.filter { $0.category == "Created By You" }.count
    }
    
    // Get all unique categories from affirmations
    private var allCategories: [String] {
        ContentLoader.shared.getAffirmationCategories()
    }
    
    // Get icon for category
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "self-love", "self-worth", "self-care", "self-acceptance":
            return "heart.fill"
        case "confidence":
            return "star.fill"
        case "inner peace", "peace":
            return "leaf.fill"
        case "gratitude":
            return "hands.clap.fill"
        case "strength", "resilience":
            return "bolt.fill"
        case "love", "relationships":
            return "heart.circle.fill"
        case "growth", "transformation":
            return "arrow.up.right.circle.fill"
        case "mental health", "anxiety relief", "healing":
            return "brain.head.profile"
        case "abundance", "manifestation", "success":
            return "sparkles"
        case "courage":
            return "flame.fill"
        case "trust", "faith":
            return "hand.raised.fill"
        case "forgiveness", "acceptance":
            return "hands.sparkles.fill"
        case "positivity":
            return "sun.max.fill"
        case "boundaries":
            return "shield.fill"
        case "compassion":
            return "hand.wave.fill"
        case "health":
            return "heart.text.square.fill"
        case "christianity", "faith":
            return "book.closed.fill"
        default:
            return "sparkle"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MuseBackgroundView(selectedBackground: selectedBackground)
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
                                            .rainbowBorder()
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
                            .rainbowBorder()
                            
                            MixCategoryCard(
                                title: "Reframe Thoughts (AI)",
                                icon: "brain.head.profile",
                                isLocked: true,
                                action: {}
                            )
                            .rainbowBorder()
                            
                            MixCategoryCard(
                                title: "Favorites",
                                icon: "heart.fill",
                                isLocked: false,
                                count: storage.savedAffirmations.count + storage.savedQuotes.count,
                                action: { showFavorites = true }
                            )
                            .rainbowBorder()
                            
                            MixCategoryCard(
                                title: "My own affirmations",
                                icon: "pencil",
                                isLocked: false,
                                count: userCreatedCount,
                                action: { showMyAffirmations = true }
                            )
                            .rainbowBorder()
                        }
                        .padding(.horizontal, 20)
                        
                        // Categories section
                        Text("Categories")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(allCategories, id: \.self) { category in
                                MixCategoryCard(
                                    title: category,
                                    icon: iconForCategory(category),
                                    isLocked: false,
                                    action: { selectedCategory = category }
                                )
                                .rainbowBorder()
                            }
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
            .sheet(isPresented: $showMyAffirmations) {
                MyAffirmationsView()
            }
            .sheet(item: $selectedCategory) { category in
                CategoryAffirmationsView(category: category)
            }
        }
    }
}

// MARK: - String extension for sheet item
extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Category Affirmations View
struct CategoryAffirmationsView: View {
    let category: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    // Get affirmations for this category
    private var affirmations: [Affirmation] {
        ContentLoader.shared.loadAffirmations().filter { $0.category == category }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                MuseBackgroundView(selectedBackground: selectedBackground)
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
                        
                        Text(category)
                            .font(.museHeadline())
                            .foregroundColor(.museSoftWhite)
                        
                        Spacer()
                        
                        // Invisible spacer for balance
                        Color.clear.frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Affirmations count
                    Text("\(affirmations.count) affirmations")
                        .font(.museCaption())
                        .foregroundColor(.museLightGray)
                        .padding(.bottom, 16)
                    
                    if affirmations.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 48))
                                .foregroundColor(.museLightGray.opacity(0.5))
                            
                            Text("No affirmations in this category")
                                .font(.museBodyMedium())
                                .foregroundColor(.museLightGray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(affirmations) { affirmation in
                                    CategoryAffirmationRow(
                                        affirmation: affirmation,
                                        isSaved: storage.isAffirmationSaved(affirmation),
                                        onSave: {
                                            if storage.isAffirmationSaved(affirmation) {
                                                storage.removeAffirmation(affirmation)
                                            } else {
                                                storage.saveAffirmation(affirmation)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Category Affirmation Row
struct CategoryAffirmationRow: View {
    let affirmation: Affirmation
    let isSaved: Bool
    let onSave: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(affirmation.text)
                    .font(.museBodyMedium())
                    .foregroundColor(.museSoftWhite)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(affirmation.category.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.museGradientStart)
            }
            
            Spacer()
            
            Button(action: onSave) {
                Image(systemName: isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(isSaved ? .museGradientStart : .museLightGray)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.museDarkGray)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.museMediumGray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - My Affirmations View
struct MyAffirmationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    @State private var showCreateSheet = false
    @State private var newAffirmationText = ""
    
    // Filter only user-created affirmations
    private var userAffirmations: [Affirmation] {
        storage.savedAffirmations.filter { $0.category == "Created By You" }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                MuseBackgroundView(selectedBackground: selectedBackground)
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
                        
                        Text("My Affirmations")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                        
                        Spacer()
                        
                        Button(action: { showCreateSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.museSoftWhite)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.museAccentBlue)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // Create button
                    Button(action: { showCreateSheet = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                            Text("Create New Affirmation")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.museSoftWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.museAccentBlue.opacity(0.3))
                                .rainbowBorder()
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    
                    // Content
                    if userAffirmations.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "pencil.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.museLightGray.opacity(0.5))
                            Text("No affirmations yet")
                                .font(.system(size: 16))
                                .foregroundColor(.museLightGray)
                            Text("Create your own personal affirmations")
                                .font(.system(size: 14))
                                .foregroundColor(.museLightGray.opacity(0.7))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(userAffirmations) { affirmation in
                                    UserAffirmationCard(
                                        text: affirmation.text,
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
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateAffirmationSheet(onSave: { text in
                    let newAffirmation = Affirmation(
                        text: text,
                        category: "Created By You"
                    )
                    storage.saveAffirmation(newAffirmation)
                })
            }
        }
    }
}

// MARK: - User Affirmation Card
struct UserAffirmationCard: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category tag
            Text("CREATED BY YOU")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.museGradientStart)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.museGradientStart.opacity(0.15))
                )
            
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.museSoftWhite)
                .multilineTextAlignment(.leading)
            
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

// MARK: - Create Affirmation Sheet
struct CreateAffirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var affirmationText = ""
    @FocusState private var isTextFieldFocused: Bool
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.museDeepNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .font(.system(size: 16))
                                .foregroundColor(.museLightGray)
                        }
                        
                        Spacer()
                        
                        Text("New Affirmation")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                        
                        Spacer()
                        
                        Button(action: {
                            if !affirmationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSave(affirmationText.trimmingCharacters(in: .whitespacesAndNewlines))
                                dismiss()
                            }
                        }) {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(affirmationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .museLightGray : .museAccentBlue)
                        }
                        .disabled(affirmationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips for great affirmations:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.museSoftWhite)
                        
                        Text("• Start with \"I am\" or \"I have\"\n• Use present tense\n• Keep it positive\n• Make it personal and meaningful")
                            .font(.system(size: 13))
                            .foregroundColor(.museLightGray)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.museDarkGray.opacity(0.5))
                    )
                    .padding(.horizontal, 20)
                    
                    // Text editor
                    ZStack(alignment: .topLeading) {
                        if affirmationText.isEmpty {
                            Text("I am...")
                                .font(.system(size: 18, design: .serif))
                                .foregroundColor(.museLightGray.opacity(0.5))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }
                        
                        TextEditor(text: $affirmationText)
                            .font(.system(size: 18, design: .serif))
                            .foregroundColor(.museSoftWhite)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .focused($isTextFieldFocused)
                    }
                    .frame(minHeight: 150)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.museDarkGray.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.museMediumGray.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Glowing Start Button
struct GlowingStartButton: View {
    let action: () -> Void
    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Animated pulsing glow layers (behind)
                Circle()
                    .fill(Color.clear)
                    .frame(width: 120, height: 120)
                    .scaleEffect(glowScale)
                    .shadow(color: .white.opacity(glowOpacity * 0.8), radius: 20 * glowScale, x: 0, y: 0)
                    .shadow(color: .white.opacity(glowOpacity * 0.6), radius: 30 * glowScale, x: 0, y: 0)
                    .shadow(color: .white.opacity(glowOpacity * 0.4), radius: 40 * glowScale, x: 0, y: 0)
                    .shadow(color: .white.opacity(glowOpacity * 0.3), radius: 50 * glowScale, x: 0, y: 0)
                
                // Outer animated glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(glowOpacity * 0.6),
                                .white.opacity(glowOpacity * 0.3),
                                .white.opacity(glowOpacity * 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(glowScale)
                
                // Inner border (static)
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                // Text
                Text("Start")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        // Animate both scale and opacity for a more visible pulse
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            glowScale = 1.15
            glowOpacity = 1.0
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
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    @State private var selectedTab = 0
    @State private var showFeed = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                MuseBackgroundView(selectedBackground: selectedBackground)
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
                                            text: "\"\(quote.text)\"",
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
                                .rainbowBorder()
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
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
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
            MuseBackgroundView(selectedBackground: selectedBackground)
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
                                    // Solid background prevents text cutoff during scroll
                                    Color.clear
                                    
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
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(maxWidth: geometry.size.width - 80)
                                        
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

// MARK: - Category Picker View
struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [String]
    @Binding var selectedCategory: String?
    let contentType: FeedView.ContentCategory
    
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
                        
                        Text("Filter by Category")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                        
                        Spacer()
                        
                        // Clear filter button
                        if selectedCategory != nil {
                            Button(action: {
                                selectedCategory = nil
                                dismiss()
                            }) {
                                Text("Clear")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.museAccentBlue)
                            }
                        } else {
                            Color.clear
                                .frame(width: 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Current filter indicator
                    if let current = selectedCategory {
                        HStack {
                            Text("Currently showing:")
                                .font(.system(size: 13))
                                .foregroundColor(.museLightGray)
                            
                            Text(current)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(contentType == .affirmation ? .museGradientStart : .museTeal)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    
                    // Show all option
                    Button(action: {
                        selectedCategory = nil
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 18))
                                .foregroundColor(.museSoftWhite)
                            
                            Text("Show All \(contentType == .affirmation ? "Affirmations" : "Quotes")")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.museSoftWhite)
                            
                            Spacer()
                            
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.museAccentBlue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCategory == nil ? Color.museAccentBlue.opacity(0.2) : Color.museDarkGray.opacity(0.5))
                                .rainbowBorder()
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    // Categories list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                    dismiss()
                                }) {
                                    HStack {
                                        Text(category)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.museSoftWhite)
                                        
                                        Spacer()
                                        
                                        if selectedCategory == category {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.museAccentBlue)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedCategory == category ? Color.museAccentBlue.opacity(0.2) : Color.museDarkGray.opacity(0.5))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}
// MARK: - Reusable Background View
struct MuseBackgroundView: View {
    let selectedBackground: String
    
    var body: some View {
        ZStack {
            if selectedBackground == "SolidDark" {
                Color.museDeepNavy
            } else if let uiImage = UIImage(named: selectedBackground) {
                GeometryReader { geometry in
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: 30)
                        .overlay(Color.black.opacity(0.3))
                }
            } else {
                Color.museDeepNavy
            }
        }
    }
}

// MARK: - Background Picker View
struct BackgroundPickerView: View {
    @Binding var selectedBackground: String
    let options: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.museDeepNavy.ignoresSafeArea()
            
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Choose Background")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                            .padding(.top, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(options, id: \.self) { bg in
                                    Button(action: {
                                        withAnimation {
                                            selectedBackground = bg
                                        }
                                    }) {
                                        ZStack {
                                            if bg == "SolidDark" {
                                                Rectangle()
                                                    .fill(Color.museDeepNavy)
                                                    .frame(width: 100, height: 160)
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        Text("Dark")
                                                            .font(.system(size: 14, weight: .medium))
                                                            .foregroundColor(.museSoftWhite)
                                                    )
                                            } else if let uiImage = UIImage(named: bg) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 160)
                                                    .clipped()
                                                    .cornerRadius(12)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray)
                                                    .frame(width: 100, height: 160)
                                                    .cornerRadius(12)
                                                    .overlay(Text(bg).font(.caption).foregroundColor(.white))
                                            }
                                            
                                            if selectedBackground == bg {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white, lineWidth: 3)
                                                    .frame(width: 100, height: 160)
                                                    
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                                    .shadow(radius: 4)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)
                        
                        Divider()
                            .background(Color.museMediumGray)
                            .padding(.horizontal, 20)
                        
                        // Music Selection
                        VStack(spacing: 16) {
                            HStack {
                                Text("Background Music")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.museSoftWhite)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            MusicPickerView()
                        }
                        .padding(.bottom, 30)
                    }
                }
        }
    }
}

struct MusicPickerView: View {
    @ObservedObject private var musicManager = BackgroundMusicManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Volume Slider
            if musicManager.selectedTrack != .none {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.museLightGray)
                    
                    Slider(value: $musicManager.volume, in: 0...1)
                        .accentColor(.museAccentBlue)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.museSoftWhite)
                }
                .padding(.horizontal, 20)
            }
            
            // Track Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(BackgroundMusicTrack.allCases) { track in
                        Button(action: {
                            withAnimation {
                                musicManager.selectedTrack = track
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(musicManager.selectedTrack == track ? Color.museAccentBlue : Color.museDarkGray)
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.museMediumGray, lineWidth: 1)
                                        )
                                    
                                    Image(systemName: track.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(musicManager.selectedTrack == track ? .white : .museLightGray)
                                }
                                
                                Text(track.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(musicManager.selectedTrack == track ? .museSoftWhite : .museLightGray)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 80)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}


#Preview {
    FeedView(
        onProfileTap: {},
        onMessageTap: {}
    )
}
