import SwiftUI

struct OnboardingContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0
    
    // Transition state
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            // Shared Background
            MuseBackgroundView(selectedBackground: "backgroundjungle2")
                .ignoresSafeArea()
            
            VStack {
                // Header (Progress)
                HStack(spacing: 8) {
                    ForEach(0..<2) { index in
                        Capsule()
                            .fill(index <= currentPage ? Color.museAccentBlue : Color.white.opacity(0.2))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                    }
                }

                .padding(.horizontal, 40)
                .padding(.top, 60) // Safe Area
                .padding(.bottom, 20)
                
                // Content Pages
                TabView(selection: $currentPage) {
                    OnboardingIntroView(onNext: { withAnimation { currentPage = 1 } })
                        .tag(0)
                    
                    OnboardingGoalsView(onNext: {
                        // User finished goals.
                        // 1. Trigger Superwall
                        EntitlementManager.shared.triggerPaywall(source: .onboarding)
                        // 2. Mark onboarding as complete (User enters app as Free or Paid)
                        // Note: Superwall presents on top of the window, so switching the underlying view is fine.
                        completeOnboarding()
                    })
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                // .disabled(true) // REMOVED: This disables ALL interaction inside
                .onChange(of: EntitlementManager.shared.isPremium) { isPremium in
                    if isPremium {
                        // If user becomes premium during onboarding, finish automatically
                        completeOnboarding()
                    }
                }
            }
    }
    .onAppear {
        // Start background music (Forest Birds default)
        BackgroundMusicManager.shared.startIfNeeded()
    }
    }
    
    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Page 1: Intro
struct OnboardingIntroView: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon/Image
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.museGradientStart, .museGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                )
                .pulsingRainbowBorder()
            
            VStack(spacing: 16) {
                Text("Rewire Your Mind")
                    .font(.museDisplayLarge())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Muse uses advanced AI and sound frequencies to help you reshape your reality through affirmations.")
                    .font(.museBodyLarge())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            Button(action: onNext) {
                Text("Get Started")
                    .font(.museButtonLarge())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.museAccentBlue)
                    .cornerRadius(16)
                    .contentShape(Rectangle()) // Ensure the whole area is tappable
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
            .zIndex(10) // Force on top
        }
    }
}

// MARK: - Page 2: Goals
struct OnboardingGoalsView: View {
    var onNext: () -> Void
    @State private var selectedGoals: Set<String> = []
    
    let goals = [
        "Reduce Anxiety",
        "Better Sleep",
        "Manifest Wealth",
        "Build Confidence",
        "Spiritual Growth",
        "Heal Trauma"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            
            VStack(spacing: 8) {
                Text("What brings you here?")
                    .font(.museDisplayMedium()) // Changed to Medium
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.museCaption())
                    .foregroundColor(.museLightGray)
            }
            .padding(.top, 40)
            
            // Grid of choices
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(goals, id: \.self) { goal in
                    Button(action: {
                        if selectedGoals.contains(goal) {
                            selectedGoals.remove(goal)
                        } else {
                            selectedGoals.insert(goal)
                        }
                    }) {
                        Text(goal)
                            .font(.museBodyMedium())
                            .foregroundColor(selectedGoals.contains(goal) ? .white : .museLightGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedGoals.contains(goal) ? Color.museAccentBlue.opacity(0.8) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedGoals.contains(goal) ? Color.museAccentBlue : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.museButtonLarge())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(selectedGoals.isEmpty ? Color.gray.opacity(0.3) : Color.museAccentBlue)
                    .cornerRadius(16)
            }
            .disabled(selectedGoals.isEmpty)
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Page 3: Final / Paywall Trigger
struct OnboardingPaywallView: View {
    var onFinish: () -> Void
    var onSkip: () -> Void
    
    @ObservedObject var entitlementManager = EntitlementManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.museTeal)
                .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                Text("Your Journey Begins")
                    .font(.museDisplayLarge())
                    .foregroundColor(.white)
                
                Text("Start with 10 free sessions this week. Unlock unlimited access and AI features with Premium.")
                    .font(.museBodyLarge())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Feature List (Premium)
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "brain", text: "Unlimited AI Affirmations")
                featureRow(icon: "waveform", text: "All Healing Frequencies")
                featureRow(icon: "infinity", text: "Unlimited Sessions")
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                // Trigger Superwall
                EntitlementManager.shared.triggerPaywall(source: .onboarding)
                // We don't call onFinish immediately here; we wait for the result
                // But for V1 UX where we might want to just proceed after they see it:
                // Actually, triggerPaywall is async in UI sense.
                // We'll rely on the user closing the paywall or subscribing to move forward.
                // However, for this specific flow, we want to move to the main app after they interact with Superwall.
                // For simplicity in V1: success or close -> update state in Container.
            }) {
                Text("Start Free Trial")
                    .font(.museButtonLarge())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [.museGradientStart, .museGradientEnd], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                    .shadow(color: .museGradientStart.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 32)
            
            Button(action: onSkip) {
                Text("Continue with Limited Version")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .padding(.vertical, 12)
            }
            .padding(.bottom, 40)
        }
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.museSuccessGreen)
                .frame(width: 30)
            
            Text(text)
                .font(.museBodyMedium())
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}
