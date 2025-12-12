import SwiftUI

struct LibraryView: View {
    @StateObject private var storage = StorageService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.museDeepNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Top section with logo
                        HStack(alignment: .top, spacing: 16) {
                            // Logo in top-left corner
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Library")
                                    .font(.museDisplayLarge())
                                    .foregroundColor(.museSoftWhite)
                                
                                Text("Your personal affirmations hub")
                                    .font(.museSubheadline())
                                    .foregroundColor(.museLightGray)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Start Affirmations Section
                        StartAffirmationsView()
                            .padding(.horizontal, 20)
                        
                        // Quotes Section
                        if !storage.savedQuotes.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "quote.bubble.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.museTeal)
                                    
                                    Text("Saved Quotes")
                                        .font(.museDisplayMedium())
                                        .foregroundColor(.museSoftWhite)
                                    
                                    Spacer()
                                    
                                    Text("\(storage.savedQuotes.count)")
                                        .font(.museCaption())
                                        .foregroundColor(.museLightGray)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.museDarkGray)
                                        )
                                }
                                .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(storage.savedQuotes) { quote in
                                            SavedQuoteCard(quote: quote)
                                                .frame(width: 320)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Affirmations Section
                        if !storage.savedAffirmations.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 24))
                                        .foregroundColor(.museGradientStart)
                                    
                                    Text("Saved Affirmations")
                                        .font(.museDisplayMedium())
                                        .foregroundColor(.museSoftWhite)
                                    
                                    Spacer()
                                    
                                    Text("\(storage.savedAffirmations.count)")
                                        .font(.museCaption())
                                        .foregroundColor(.museLightGray)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.museDarkGray)
                                        )
                                }
                                .padding(.horizontal, 20)
                                
                                VStack(spacing: 16) {
                                    ForEach(storage.savedAffirmations) { affirmation in
                                        SavedAffirmationCard(affirmation: affirmation)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Empty state
                        if storage.savedQuotes.isEmpty && storage.savedAffirmations.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 48))
                                    .foregroundColor(.museLightGray.opacity(0.5))
                                
                                Text("Your library is empty")
                                    .font(.museHeadline())
                                    .foregroundColor(.museLightGray)
                                
                                Text("Save quotes and affirmations from Discover to see them here")
                                    .font(.museBodyMedium())
                                    .foregroundColor(.museLightGray.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                    }
                    .padding(.bottom, 20)
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

// MARK: - Saved Quote Card
struct SavedQuoteCard: View {
    let quote: Quote
    @StateObject private var storage = StorageService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(quote.text)
                .font(.museQuote())
                .foregroundColor(.museSoftWhite)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text("— \(quote.author)")
                    .font(.museCaption())
                    .foregroundColor(.museLightGray)
                
                Spacer()
                
                Text(quote.category)
                    .font(.museCaption())
                    .foregroundColor(.museTeal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.museTeal.opacity(0.2))
                    )
            }
            
            Button(action: {
                withAnimation {
                    storage.removeQuote(quote)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Remove")
                        .font(.museButtonMedium())
                }
                .foregroundColor(.museSuccessGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.museSuccessGreen.opacity(0.15))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.museDarkGray)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.museMediumGray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Saved Affirmation Card
struct SavedAffirmationCard: View {
    let affirmation: Affirmation
    @StateObject private var storage = StorageService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(affirmation.text)
                .font(.museAffirmation())
                .foregroundColor(.museSoftWhite)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text(affirmation.category)
                    .font(.museCaption())
                    .foregroundColor(.museGradientStart)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.museGradientStart.opacity(0.2), Color.museGradientEnd.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        storage.removeAffirmation(affirmation)
                    }
                }) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.museSuccessGreen)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.museSuccessGreen.opacity(0.15))
                        )
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
    }
}

#Preview {
    LibraryView()
}

