import SwiftUI

struct QuoteCard: View {
    let quote: Quote
    @StateObject private var storage = StorageService.shared
    
    private var isSaved: Bool {
        storage.isQuoteSaved(quote)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote text
            Text(quote.text)
                .font(.museQuote())
                .foregroundColor(.museSoftWhite)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
            // Author and category
            HStack {
                Text("— \(quote.author)")
                    .font(.museCaption())
                    .foregroundColor(.museLightGray)
                
                Spacer()
                
                // Category badge
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
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        if isSaved {
                            storage.removeQuote(quote)
                        } else {
                            storage.saveQuote(quote)
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14, weight: .medium))
                        Text(isSaved ? "Saved" : "Save")
                            .font(.museButtonMedium())
                    }
                    .foregroundColor(isSaved ? .museSuccessGreen : .museAccentBlue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(isSaved ? Color.museSuccessGreen.opacity(0.15) : Color.museAccentBlue.opacity(0.15))
                    )
                }
                
                Button(action: {
                    // Share action
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.museLightGray)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.museDarkGray)
                        )
                }
                
                Spacer()
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

#Preview {
    ZStack {
        Color.museDeepNavy.ignoresSafeArea()
        QuoteCard(quote: Quote(
            text: "The only way out is through.",
            author: "Robert Frost",
            category: "Wisdom"
        ))
        .padding()
    }
}

