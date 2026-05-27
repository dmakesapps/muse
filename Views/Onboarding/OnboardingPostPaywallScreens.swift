import SwiftUI
import UserNotifications

// MARK: - Category mapping from onboarding blockage

enum OnboardingNotificationCategories {
    static func categories(
        for blockage: String?,
        generatedAffirmations: [Affirmation]
    ) -> (affirmations: Set<String>, quotes: Set<String>) {
        switch blockage {
        case "Anxiety Loop":
            return (["Anxiety Relief", "Inner Peace"], ["Anxiety", "Inner Peace", "Emotional Health"])
        case "Scarcity Circuit":
            return (["Abundance", "Self-Worth"], ["Abundance", "Growth"])
        case "Imposter Syndrome":
            return (["Confidence", "Self-Worth"], ["Confidence", "Wisdom", "Empowerment"])
        case "Relationship Pattern":
            return (["Relationships", "Self-Love"], ["Love", "Connection", "Compassion"])
        case "Lack of Direction":
            return (["Purpose", "Growth"], ["Purpose", "Wisdom", "Growth"])
        case "Self-Sabotage":
            return (["Self-Worth", "Confidence"], ["Growth", "Empowerment", "Healing"])
        default:
            let fromGenerated = Set(generatedAffirmations.map(\.category))
            let affirmationCats = fromGenerated.isEmpty ? ["Self-Worth"] : fromGenerated
            return (affirmationCats, ["Wisdom", "Purpose", "Inner Peace"])
        }
    }
    
    static func personalizedSubtitle(blockage: String?) -> String {
        guard let blockage, !blockage.isEmpty else {
            return "Get gentle nudges with affirmations and quotes picked for your journey."
        }
        return "Stay consistent with daily reminders aligned to your \(blockage.lowercased()) work."
    }
}

// MARK: - Screen 9: Notification pre-prompt

struct Screen9_NotificationPrompt: View {
    let blockage: String?
    var onEnable: () -> Void
    var onSkip: () -> Void
    
    @State private var cardsVisible = false
    @State private var bellPulse = false
    
    private let mockNotifications: [(icon: String, title: String, message: String, color: Color)] = [
        ("sparkles", "✨ Daily Affirmation", "I am enough exactly as I am.", .purple),
        ("quote.bubble.fill", "💭 Daily Quote", "\"Peace comes from within.\" — Buddha", .museTeal),
        ("bell.fill", "Muse", "Ready for your affirmations session?", .museAccentBlue)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            
            ZStack {
                Circle()
                    .fill(Color.museAccentBlue.opacity(0.15))
                    .frame(width: 88, height: 88)
                    .scaleEffect(bellPulse ? 1.08 : 1.0)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.museAccentBlue, .museTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.bottom, 28)
            
            Text("Stay on track")
                .font(.museDisplaySmall())
                .foregroundColor(.museSoftWhite)
                .multilineTextAlignment(.center)
            
            Text(OnboardingNotificationCategories.personalizedSubtitle(blockage: blockage))
                .font(.museBodyMedium())
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 12)
            
            VStack(spacing: 10) {
                ForEach(Array(mockNotifications.enumerated()), id: \.offset) { index, item in
                    MockNotificationCard(
                        icon: item.icon,
                        title: item.title,
                        message: item.message,
                        accent: item.color
                    )
                    .opacity(cardsVisible ? 1 : 0)
                    .offset(y: cardsVisible ? 0 : 16)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(index) * 0.12),
                        value: cardsVisible
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: onEnable) {
                    Text("Enable Reminders")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MusePrimaryButtonStyle())
                
                Button(action: onSkip) {
                    Text("Not now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.museLightGray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                bellPulse = true
            }
            cardsVisible = true
        }
    }
}

private struct MockNotificationCard: View {
    let icon: String
    let title: String
    let message: String
    let accent: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(accent.opacity(0.2)))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Muse")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.museLightGray)
                    Spacer()
                    Text("now")
                        .font(.system(size: 10))
                        .foregroundColor(.museLightGray.opacity(0.7))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.museSoftWhite)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.museLightGray)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }
}

// MARK: - Screen 11: Quick notification setup

struct Screen11_QuickNotificationSetup: View {
    let affirmationCategories: Set<String>
    let quoteCategories: Set<String>
    var onContinue: () -> Void
    var onSkip: () -> Void
    
    @StateObject private var notificationService = NotificationService.shared
    @State private var affirmationCount = 2
    @State private var quoteCount = 1
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Your daily rhythm")
                    .font(.museDisplaySmall())
                    .foregroundColor(.museSoftWhite)
                
                Text("Recommended for you — change anytime in Profile.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 40)
            .padding(.bottom, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    frequencyCard(
                        title: "Daily affirmations",
                        icon: "sparkles",
                        color: .purple,
                        selection: $affirmationCount
                    )
                    
                    frequencyCard(
                        title: "Daily quotes",
                        icon: "quote.bubble.fill",
                        color: .museTeal,
                        selection: $quoteCount
                    )
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: saveAndContinue) {
                    Text("Save & Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(MusePrimaryButtonStyle())
                
                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.museLightGray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private func frequencyCard(title: String, icon: String, color: Color, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.museSoftWhite)
            }
            
            HStack(spacing: 8) {
                ForEach(0...3, id: \.self) { count in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection.wrappedValue = count
                        }
                    } label: {
                        Text(count == 0 ? "Off" : "\(count)/day")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selection.wrappedValue == count ? .white : .museLightGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selection.wrappedValue == count ? color.opacity(0.85) : Color.white.opacity(0.08))
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.museDarkGray.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func saveAndContinue() {
        notificationService.updateAffirmationSettings(
            count: affirmationCount,
            categories: affirmationCategories
        )
        notificationService.updateQuoteSettings(
            count: quoteCount,
            categories: quoteCategories
        )
        onContinue()
    }
}

// MARK: - Screen 12: Home Screen widgets

struct Screen12_WidgetPrompt: View {
    let sampleAffirmation: String
    let sampleQuote: String
    let sampleAuthor: String
    var onContinue: () -> Void
    
    @State private var previewsVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Take Muse home")
                    .font(.museDisplaySmall())
                    .foregroundColor(.museSoftWhite)
                
                Text("Add widgets for inspiration on your Home Screen and Lock Screen.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .padding(.top, 36)
            .padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack(spacing: 14) {
                        OnboardingWidgetPreview(
                            title: "Affirmations",
                            text: sampleAffirmation,
                            subtitle: nil,
                            accent: .purple
                        )
                        OnboardingWidgetPreview(
                            title: "Quotes",
                            text: sampleQuote,
                            subtitle: "— \(sampleAuthor)",
                            accent: .museTeal
                        )
                    }
                    .opacity(previewsVisible ? 1 : 0)
                    .offset(y: previewsVisible ? 0 : 12)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        widgetStep(number: 1, text: "Long-press your Home Screen")
                        widgetStep(number: 2, text: "Tap the + button, then search \"Muse\"")
                        widgetStep(number: 3, text: "Add Affirmations or Quotes widget")
                        widgetStep(number: 4, text: "Heart favorites in the app to fill your widgets")
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.museDarkGray.opacity(0.5))
                    )
                    .opacity(previewsVisible ? 1 : 0)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Continue to Muse")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(MusePrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                previewsVisible = true
            }
        }
    }
    
    private func widgetStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.museAccentBlue))
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.museSoftWhite)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingWidgetPreview: View {
    let title: String
    let text: String
    let subtitle: String?
    let accent: Color
    
    private let rainbowColors: [Color] = [
        Color(red: 1.0, green: 0.3, blue: 0.3),
        Color(red: 1.0, green: 0.6, blue: 0.2),
        Color(red: 0.3, green: 0.7, blue: 1.0),
        Color(red: 0.6, green: 0.4, blue: 1.0),
        Color(red: 1.0, green: 0.4, blue: 0.8),
        Color(red: 1.0, green: 0.3, blue: 0.3)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(accent)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.09, blue: 0.14),
                                Color(red: 0.12, green: 0.13, blue: 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                AngularGradient(
                                    colors: rainbowColors,
                                    center: .center
                                ),
                                lineWidth: 2.5
                            )
                    )
                
                VStack(spacing: 6) {
                    Text(text)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .minimumScaleFactor(0.7)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 9, weight: .regular, design: .serif))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                    }
                }
                .padding(10)
            }
            .frame(height: 118)
        }
        .frame(maxWidth: .infinity)
    }
}
