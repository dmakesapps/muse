import SwiftUI

struct DiscoverView: View {
    @StateObject private var storage = StorageService.shared
    
    // Default quotes
    @State private var quotes: [Quote] = [
        Quote(text: "The only way out is through.", author: "Robert Frost", category: "Wisdom"),
        Quote(text: "You are enough just as you are.", author: "Maya Angelou", category: "Self-Love"),
        Quote(text: "The present moment is the only time over which we have dominion.", author: "Thich Nhat Hanh", category: "Mindfulness"),
        Quote(text: "What lies behind us and what lies before us are tiny matters compared to what lies within us.", author: "Ralph Waldo Emerson", category: "Strength"),
        Quote(text: "The wound is the place where the Light enters you.", author: "Rumi", category: "Healing")
    ]
    
    // Default affirmations
    @State private var affirmations: [Affirmation] = [
        Affirmation(text: "I am confident, capable, and ready to embrace all the opportunities that come my way.", category: "Confidence"),
        Affirmation(text: "I choose to focus on what I can control and release what I cannot.", category: "Peace"),
        Affirmation(text: "I am worthy of love, respect, and all the good things life has to offer.", category: "Self-Love"),
        Affirmation(text: "Every day, I grow stronger, wiser, and more aligned with my true purpose.", category: "Growth"),
        Affirmation(text: "I trust the process of life and know that everything is unfolding perfectly.", category: "Trust")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.museDeepNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Top section with title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Discover")
                                .font(.museDisplayLarge())
                                .foregroundColor(.museSoftWhite)
                            
                            Text("Browse quotes & generate affirmations")
                                .font(.museSubheadline())
                                .foregroundColor(.museLightGray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Quotes Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "quote.bubble.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.museTeal)
                                
                                Text("Quotes")
                                    .font(.museDisplayMedium())
                                    .foregroundColor(.museSoftWhite)
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(quotes) { quote in
                                        QuoteCard(quote: quote)
                                            .frame(width: 320)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Affirmations Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24))
                                    .foregroundColor(.museGradientStart)
                                
                                Text("Affirmations")
                                    .font(.museDisplayMedium())
                                    .foregroundColor(.museSoftWhite)
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                ForEach(affirmations) { affirmation in
                                    AffirmationCard(affirmation: affirmation)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
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

#Preview {
    DiscoverView()
}

