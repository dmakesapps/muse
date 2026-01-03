import SwiftUI
import UIKit
import SwiftData

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var progressService = ProgressService.shared
    @StateObject private var storage = StorageService.shared
    @State private var selectedCategory: ContentCategory = .affirmation
    @State private var currentIndex: Int = 0
    let onProfileTap: () -> Void
    let onMessageTap: () -> Void
    @State private var showMixPopup = false
    @State private var showPracticePopup = false
    @State private var selectedTagFilter: Set<String> = []  // Filter by specific tags
    @State private var showCategoryPicker = false
    @State private var showBackgroundPicker = false
    @State private var showHamburgerMenu = false  // Custom hamburger menu popup
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    let backgroundOptions = ["backgroundjungle2", "clouds", "ocean", "SolidDark"]
    
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
        if !selectedTagFilter.isEmpty {
            items = items.filter { selectedTagFilter.contains($0.category) }
        }
        
        return items
    }
    
    var body: some View {
        ZStack {
            // LAYER 1: CONTENT (Full Screen, Ignores Safe Area)
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                
                ZStack {
                    // Background
                    MuseBackgroundView(selectedBackground: selectedBackground)
                    //.ignoresSafeArea() - handled by parent
                
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
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    // Vertical swipe feed using native vertical paging
                    ScrollView([.vertical], showsIndicators: false) {
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
                                                            .stroke(selectedTagFilter.contains(item.category) ? Color.white : Color.clear, lineWidth: 2)
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
                                    .frame(maxWidth: item.isAffirmation ? geometry.size.width - (isLandscape ? 160 : 64) : nil)
                                    .padding(.horizontal, item.isAffirmation ? 0 : 40)
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
                    //.ignoresSafeArea() // Already handled by parent GeometryReader
                    // Force ScrollView to recreate when category, filter, or orientation changes
                    .id("\(selectedCategory.rawValue)-\(selectedTagFilter.sorted().joined(separator: ","))-\(geometry.size.width)-\(geometry.size.height)")
                    // Add fade mask for seamless scrolling
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),   // Top fade out
                                .init(color: .black, location: 0.15),  // Start visible content
                                .init(color: .black, location: 0.85),  // End visible content
                                .init(color: .clear, location: 1.0)    // Bottom fade out
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                }
            }
            .ignoresSafeArea() // Ensure content flows under notches/home bars for smoother feel
            
            // LAYER 2: UI OVERLAY (Respects Safe Area naturally)
            GeometryReader { proxy in // Use proxy to check orientation only
                let isLandscape = proxy.size.width > proxy.size.height
                
                ZStack {
                    VStack {
                        // Top bar - Category tabs centered, hamburger overlaid
                        ZStack {
                            // Left: Streak/Profile Button
                            if !isLandscape {
                                HStack {
                                    StreakFireButton(streak: progressService.currentStreak, action: onProfileTap)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            // Category selector (truly centered)
                            if !isLandscape {
                                HStack(spacing: 0) {
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = .affirmation
                                            selectedTagFilter.removeAll()
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
                                            selectedTagFilter.removeAll()
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
                            }
                            
                            // Hamburger menu button (absolute right position)
                            if !isLandscape {
                                HStack {
                                    Spacer()
                                    // LiquidMenu will be placed as an overlay on the root ZStack
                                    // to ensure it doesn't affect layout
                                    Color.clear
                                        .frame(width: 50, height: 50) 
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 10)
                        // Ensure menu stays on top of content
                        .zIndex(100) 
                        
                        Spacer()
                    
                        // Share and Heart buttons - centered
                        // HIDDEN IN LANDSCAPE
                        if !isLandscape {
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
                        }
                        
                        // Bottom - Only the Start button (centered)
                        if !isLandscape {
                            LiquidStartButton(action: { showPracticePopup = true })
                                .padding(.bottom, 20)
                        }
                    }
                    
                    // Old Hamburger/Popup Removed - LiquidMenu handles it
                    
                    // Liquid Menu Overlay (Top-Right)
                    // Placed here to be independent of layout flow (absolute position effect)
                    if !isLandscape {
                        VStack {
                            HStack {
                                Spacer()
                                LiquidMenu(
                                    isOpen: $showHamburgerMenu,
                                    onCategory: { showMixPopup = true },
                                    onBackground: { showBackgroundPicker = true }
                                )
                                .padding(.trailing, 16)
                                .padding(.top, 16) // Adjust for top bar padding
                            }
                            Spacer()
                        }
                    }
                }
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
                selectedCategories: $selectedTagFilter,
                contentType: selectedCategory
            )
            .presentationDetents([.large]) // Start at top / full screen
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBackgroundPicker) {
            BackgroundPickerView(selectedBackground: $selectedBackground, options: backgroundOptions)
                // Use a larger detent or allow dynamic sizing
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            progressService.setModelContext(modelContext)
            // Load content from JSON files
            if quotes.isEmpty {
                quotes = ContentLoader.shared.loadQuotes().shuffled()
            }
            if affirmations.isEmpty {
                affirmations = ContentLoader.shared.loadAffirmations()
            }
        }
        .ignoresSafeArea(.keyboard) // Only ignore keyboard, but respect safe areas for the UI layer by default (since we didn't add .ignoresSafeArea(.all) to the root)
        // Note: The first GeometryReader HAS .ignoresSafeArea() attached to it, so it will bleed.
        // The second GeometryReader/VStack DOES NOT, so it will respect safe areas.
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
// TopBarView removed - unused

// ContentCard removed - unused


// MARK: - Liquid Menu Component
struct LiquidMenu: View {
    @Binding var isOpen: Bool
    // Actions
    let onCategory: () -> Void
    let onBackground: () -> Void
    
    // Animation properties
    @Namespace private var animation
    
    // Config
    private let buttonSize: CGFloat = 50
    private let spacing: CGFloat = 16
    
    var body: some View {
        ZStack(alignment: .top) {
            // Options Stack (Behind the toggle button)
            ZStack {
                // Item 2: Background (Bottom-most)
                LiquidMenuItem(icon: "paintbrush.fill", index: 2, isOpen: isOpen) {
                    onBackground()
                    withAnimation { isOpen = false }
                }
                
                // Item 1: Categories (Top-most)
                LiquidMenuItem(icon: "square.grid.2x2.fill", index: 1, isOpen: isOpen) {
                    onCategory()
                    withAnimation { isOpen = false }
                }
            }
            .zIndex(0)
            
            // Main Toggle Button (Always on top)
            Button(action: {
                // Using a "bouncy" spring to feel like popping a bubble
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isOpen.toggle()
                }
            }) {
                ZStack {
                    // Glass Background - NOW A CAPSULE (Pill Shape)
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .frame(width: 60, height: 40) // Pill dimensions
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 5)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1) // Fine outline like left button
                        )
                    
                    // Icon
                    Image(systemName: isOpen ? "xmark" : "line.3.horizontal")
                        .font(.system(size: 18, weight: .medium)) // Slightly smaller to fit in 40pt height perfectly
                        .foregroundColor(.white)
                        .contentTransition(.symbolEffect(.replace))
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                }
            }
            .zIndex(1)
        }
        // Ensure the expanded menu doesn't capture touches outside the buttons
        // Adjusted frame calculation for 2 menu items
        .frame(width: 60, height: isOpen ? (50 * 3) + (spacing * 2) : 40, alignment: .top)
    }
}

struct LiquidMenuItem: View {
    let icon: String
    let index: Int
    let isOpen: Bool
    let action: () -> Void
    
    // Spacing constants
    private let buttonSize: CGFloat = 50
    private let spacing: CGFloat = 16
    
    var offset: CGFloat {
        if !isOpen { return 0 }
        return CGFloat(index) * (buttonSize + spacing)
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.3)) // Dark glass
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.museSoftWhite)
            }
        }
        .offset(y: offset)
        // Physics-simulating spring animation
        // "Heavy" liquid feel: items drop with a slight delay and bounce
        .animation(
            .spring(response: 0.5, dampingFraction: 0.6)
            .delay(isOpen ? Double(index) * 0.05 : 0),
            value: isOpen
        )
        // Fade in/out
        .opacity(isOpen ? 1 : 0)
        // Scale up/down for "pop" effect
        .scaleEffect(isOpen ? 1 : 0.5)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isOpen)
    }
}

// GlassIconButton removed - unused

// MARK: - Mix Popup View (Redesigned)
struct MixPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = StorageService.shared
    @AppStorage("selectedBackground") private var selectedBackground: String = "backgroundjungle2"
    
    // Bottom Tab State
    enum ContentTab {
        case affirmation
        case quote
    }
    @State private var selectedTab: ContentTab = .affirmation
    
    // Helper States
    @State private var showFavorites = false
    @State private var showMyAffirmations = false
    @State private var selectedCategory: String? = nil
    
    // Data
    private var affirmationCategories: [String] {
        ContentLoader.shared.getAffirmationCategories()
    }
    
    private var quoteCategories: [String] {
        ContentLoader.shared.getQuoteCategories()
    }
    
    // Computed Properties for Cleaner View Body
    private var userCreatedCount: Int {
        storage.savedAffirmations.filter { $0.category == "Created By You" }.count
    }
    
    private var favoritesCount: Int {
        selectedTab == .affirmation ? storage.savedAffirmations.count : storage.savedQuotes.count
    }
    
    private var displayedCategories: [String] {
        selectedTab == .affirmation ? affirmationCategories : quoteCategories
    }
    
    // Icon Helper
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "self-love", "self-worth", "self-care", "self-acceptance": return "heart.fill"
        case "confidence", "wisdom": return "star.fill"
        case "inner peace", "peace", "calm": return "leaf.fill"
        case "gratitude": return "hands.clap.fill"
        case "strength", "resilience", "motivation": return "bolt.fill"
        case "love", "relationships": return "heart.circle.fill"
        case "growth", "transformation", "purpose": return "arrow.up.right.circle.fill"
        case "mental health", "healing", "wellness": return "brain.head.profile"
        case "abundance", "success": return "sparkles"
        case "courage": return "flame.fill"
        case "faith", "hope": return "hand.raised.fill"
        case "positivity", "happiness": return "sun.max.fill"
        default: return "sparkle"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MuseBackgroundView(selectedBackground: selectedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Explore")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Invisible spacer to balance the header
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // 2. Scrollable Grid
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            // Section: Tools & Favorites
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                
                                // Favorites (Always Visible)
                                MixCategoryCard(
                                    title: "Favorites",
                                    icon: "heart.fill",
                                    isLocked: false,
                                    count: favoritesCount,
                                    action: { showFavorites = true }
                                )
                                
                                if selectedTab == .affirmation {
                                    // Affirmation Specific Tools
                                    MixCategoryCard(
                                        title: "My own affirmations",
                                        icon: "pencil",
                                        isLocked: false,
                                        count: userCreatedCount,
                                        action: { showMyAffirmations = true }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Section: Categories Toggle (Replaces simple divider)
                            HStack(spacing: 0) {
                                // Affirmations Tab
                                Button(action: { withAnimation(.smooth) { selectedTab = .affirmation } }) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 16))
                                        Text("Affirmations")
                                            .font(.system(size: 14, weight: .semibold))
                                            .fixedSize()
                                    }
                                    .foregroundColor(selectedTab == .affirmation ? .white : .museLightGray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedTab == .affirmation ? Color.white.opacity(0.15) : Color.clear)
                                    )
                                }
                                
                                // Quotes Tab
                                Button(action: { withAnimation(.smooth) { selectedTab = .quote } }) {
                                    HStack {
                                        Image(systemName: "quote.bubble")
                                            .font(.system(size: 16))
                                        Text("Quotes")
                                            .font(.system(size: 14, weight: .semibold))
                                            .fixedSize()
                                    }
                                    .foregroundColor(selectedTab == .quote ? .white : .museLightGray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedTab == .quote ? Color.white.opacity(0.15) : Color.clear)
                                    )
                                }
                            }
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.3))
                            )
                            .padding(.horizontal, 20)
                            
                            // Section: Categories Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(displayedCategories, id: \.self) { category in
                                    MixCategoryCard(
                                        title: category,
                                        icon: iconForCategory(category),
                                        isLocked: false,
                                        action: { selectedCategory = category }
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
                // Icon Bubble
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.museLightGray)
                    } else if count > 0 {
                        Text("\(count) items")
                            .font(.system(size: 11))
                            .foregroundColor(.museLightGray)
                    }
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit) // Square aspect ratio
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
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
                    ScrollView([.vertical], showsIndicators: false) {
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
    @Binding var selectedCategories: Set<String>
    let contentType: FeedView.ContentCategory
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
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
                        
                        // Clear button
                        if !selectedCategories.isEmpty {
                            Button(action: { selectedCategories.removeAll() }) {
                                Text("Clear")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.museAccentBlue)
                            }
                        } else {
                            Color.clear.frame(width: 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Show All Button
                    Button(action: { selectedCategories.removeAll() }) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 18))
                                .foregroundColor(.museSoftWhite)
                            
                            Text("Show All \(contentType == .affirmation ? "Affirmations" : "Quotes")")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.museSoftWhite)
                            
                            Spacer()
                            
                            if selectedCategories.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.museAccentBlue)
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(.museLightGray)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedCategories.isEmpty ? Color.museAccentBlue.opacity(0.2) : Color.museDarkGray.opacity(0.5))
                                .rainbowBorder()
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.bottom, 12)
                    
                    // Categories list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                CategoryRow(
                                    category: category,
                                    isSelected: selectedCategories.contains(category),
                                    action: {
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
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
}

// Subview to reduce compiler complexity
private struct CategoryRow: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(category)
                    .font(.system(size: 16))
                    .foregroundColor(.museSoftWhite)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .museAccentBlue : .museLightGray.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.museAccentBlue.opacity(0.15) : Color.museDarkGray.opacity(0.3))
            )
        }
    }
}

// MARK: - Reusable Background View
struct MuseBackgroundView: View {
    let selectedBackground: String
    
    private func loadImage() -> UIImage? {
        // First try UIImage(named:) which works for asset catalogs
        if let image = UIImage(named: selectedBackground) {
            return image
        }
        // Then try loading from bundle with .jpg extension (for files in Resources folder)
        if let path = Bundle.main.path(forResource: selectedBackground, ofType: "jpg"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        // Try .png as fallback
        if let path = Bundle.main.path(forResource: selectedBackground, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            if selectedBackground == "SolidDark" {
                Color.museDeepNavy
            } else if let uiImage = loadImage() {
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
    
    private func loadPickerImage(_ name: String) -> UIImage? {
        // First try UIImage(named:) which works for asset catalogs
        if let image = UIImage(named: name) {
            return image
        }
        // Then try loading from bundle with .jpg extension
        if let path = Bundle.main.path(forResource: name, ofType: "jpg"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        // Try .png as fallback
        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            Color.museDeepNavy.ignoresSafeArea()
            
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Choose Background")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.museSoftWhite)
                            .padding(.top, 24)
                        
                        ScrollView([.horizontal], showsIndicators: false) {
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
                                            } else if let uiImage = loadPickerImage(bg) {
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
            ScrollView([.horizontal], showsIndicators: false) {
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


struct LiquidStartButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var rotation: Double = 0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 1. Alive Aura (Background Glow) - Kept the cool effect but subtler
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                .museGradientStart.opacity(0.0),
                                .museGradientStart.opacity(0.15),
                                .museTeal.opacity(0.15),
                                .museGradientStart.opacity(0.0)
                            ]),
                            center: .center
                        )
                    )
                    .frame(width: 160, height: 160) // Larger aura
                    .rotationEffect(.degrees(rotation))
                    .blur(radius: 20) // Softer blur
                
                // 2. The Button Core (Glass)
                ZStack {
                    // Dark Glass Background
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    
                    // Rotating "Liquid Light" Glow - The "cool effect" blended in
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.2),
                                    .white.opacity(0.5),
                                    .museGradientStart.opacity(0.8), // The "flash" of color
                                    .white.opacity(0.5),
                                    .white.opacity(0.2)
                                ]),
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .rotationEffect(.degrees(rotation))
                        .blur(radius: 4) // Soft glow behind the sharp line
                    
                    // SOLID WHITE OUTLINE (The "Screenshot" look - Crisp & Clean)
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                    
                    // Inner Highlight (Depth)
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .padding(4)
                }
                .frame(width: 100, height: 100) // Significantly Larger
                .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
                
                // 3. Text
                Text("Start")
                    .font(.system(size: 20, weight: .semibold, design: .rounded)) // Larger, clearer text
                    .foregroundColor(.white)
                    // Clean, bright text
                    .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
            }
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(LiquidButtonStyle(isPressed: $isPressed))
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) { // Very slow, majestic rotation
                rotation = 360
            }
        }
    }
}

// Custom button style to track press state
struct LiquidButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}


struct StreakFireButton: View {
    let streak: Int
    let action: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Animated Flame - Slow, calming breath
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white) // White clean look
                    // Removing aggressive bounce symbolEffect
                    .opacity(isAnimating ? 1.0 : 0.7) // Gentle fade
                    .scaleEffect(isAnimating ? 1.05 : 0.95) // Subtle breathing size
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("\(streak)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.museSoftWhite)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    FeedView(
        onProfileTap: {},
        onMessageTap: {}
    )
}
