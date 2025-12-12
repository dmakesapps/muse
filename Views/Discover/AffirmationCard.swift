import SwiftUI

struct AffirmationCard: View {
    let affirmation: Affirmation
    @StateObject private var storage = StorageService.shared
    
    private var isSaved: Bool {
        storage.isAffirmationSaved(affirmation)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Affirmation text
            Text(affirmation.text)
                .font(.museAffirmation())
                .foregroundColor(.museSoftWhite)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Category and actions
            HStack {
                // Category badge
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
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            if isSaved {
                                storage.removeAffirmation(affirmation)
                            } else {
                                storage.saveAffirmation(affirmation)
                            }
                        }
                    }) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSaved ? .museSuccessGreen : .museLightGray)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Color.museMediumGray.opacity(0.3))
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
                                    .fill(Color.museMediumGray.opacity(0.3))
                            )
                    }
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
    ZStack {
        Color.museDeepNavy.ignoresSafeArea()
        AffirmationCard(affirmation: Affirmation(
            text: "I am confident, capable, and ready to embrace all the opportunities that come my way.",
            category: "Confidence"
        ))
        .padding()
    }
}

