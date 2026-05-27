import SwiftUI

struct OnboardingContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @EnvironmentObject private var entitlementManager: EntitlementManager
    
    // State for the User's Journey
    @State private var currentPage: Int = 1
    @State private var selectedBlockage: String? = nil
    @State private var specificityInput: String = ""
    @State private var desiredStateInput: String = ""
    @State private var generatedAffirmations: [Affirmation] = []
    @State private var chatConversation: String = "" // For "Other" flow chat history
    
    // Animation States
    @State private var calibrationText = "Analyzing neural patterns..."
    
    var body: some View {
        ZStack {
            // Shared Background - Dark Navy (hide during immersive preview)
            if currentPage != 8 && currentPage != 10 {
                MuseBackgroundView(selectedBackground: "backgroundjungle2")
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.3)) // Slight darken for text legibility
            }
            
            // Content Dispatcher
            VStack {
                switch currentPage {
                case 1:
                    Screen1_Splash(onNext: { advance() })
                case 2:
                    Screen2_ScienceHook(onNext: { advance() })
                case 3:
                    Screen3_Mechanism(onNext: { advance() })
                case 4:
                    Screen4_BlockageSelector(
                        selectedBlockage: $selectedBlockage,
                        onNext: { 
                            // For pre-defined blockages, use pre-selected affirmations
                            // Skip screens 5 & 6 and go directly to calibration
                            startCalibrationWithPrebuilt()
                        },
                        onOther: { 
                            // Skip to chat screen for custom AI generation
                            withAnimation { currentPage = 10 }
                        }
                    )
                case 5:
                    Screen5_Specificity(selectedBlockage: selectedBlockage, text: $specificityInput, onNext: { advance() })
                case 6:
                    Screen6_DesiredState(text: $desiredStateInput, onNext: { 
                        // Trigger generation then advance
                        startCalibration()
                    })
                case 7:
                    Screen7_Calibration(statusText: $calibrationText)
                case 8:
                    Screen8_ImmersivePreview(
                        affirmations: generatedAffirmations,
                        onComplete: { 
                            entitlementManager.triggerPaywall(source: .onboarding, presenter: .onboarding)
                        }
                    )
                case 9:
                    Screen9_NotificationPrompt(
                        blockage: selectedBlockage,
                        onEnable: { requestNotificationsAndAdvance() },
                        onSkip: { goToWidgetScreen() }
                    )
                case 10:
                    // "Other" AI Chat Flow
                    Screen_OtherChat(
                        onAffirmationsReady: { affirmations in
                            self.generatedAffirmations = affirmations
                            // Go directly to immersive preview, skip calibration (chat IS the calibration)
                            withAnimation { currentPage = 8 }
                        }
                    )
                case 11:
                    Screen11_QuickNotificationSetup(
                        affirmationCategories: notificationCategorySets.affirmations,
                        quoteCategories: notificationCategorySets.quotes,
                        onContinue: { goToWidgetScreen() },
                        onSkip: { goToWidgetScreen() }
                    )
                case 12:
                    Screen12_WidgetPrompt(
                        sampleAffirmation: widgetSampleAffirmation,
                        sampleQuote: widgetSampleQuote,
                        sampleAuthor: widgetSampleAuthor,
                        onContinue: { completeOnboarding() }
                    )
                default:
                    EmptyView()
                }
            }
            .transition(.opacity) // Smooth fades between screens
        }
        .onAppear {
            BackgroundMusicManager.shared.startIfNeeded()
        }
        .onChange(of: entitlementManager.shouldCompleteOnboarding) { _, shouldComplete in
            guard shouldComplete else { return }
            entitlementManager.consumeOnboardingCompletionRequest()
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage = 9
            }
        }
        .onChange(of: entitlementManager.isPremium) { _, isPremium in
            guard isPremium, !hasCompletedOnboarding, currentPage == 8, !entitlementManager.showPaywall else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage = 9
            }
        }
        .paywallFullScreenCover(presenter: .onboarding)
    }
    
    private func advance() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage += 1
        }
    }
    
    // MARK: - Pre-built Affirmations by Blockage Category
    private func prebuiltAffirmationsForBlockage(_ blockage: String) -> [Affirmation] {
        switch blockage {
        case "Anxiety Loop":
            return [
                Affirmation(text: "My racing thoughts are slowing down with each breath.", category: "Anxiety Relief"),
                Affirmation(text: "I release the need to predict every outcome.", category: "Anxiety Relief"),
                Affirmation(text: "This feeling is temporary. I am safe right now.", category: "Anxiety Relief"),
                Affirmation(text: "I trust my ability to handle whatever comes.", category: "Anxiety Relief"),
                Affirmation(text: "My nervous system is calming. Peace is returning.", category: "Anxiety Relief")
            ]
        case "Scarcity Circuit":
            return [
                Affirmation(text: "There is more than enough for me and everyone.", category: "Abundance"),
                Affirmation(text: "Money flows to me easily and frequently.", category: "Abundance"),
                Affirmation(text: "I release the fear that I won't have enough.", category: "Abundance"),
                Affirmation(text: "Opportunities are everywhere. I see them now.", category: "Abundance"),
                Affirmation(text: "I am worthy of financial abundance and success.", category: "Abundance")
            ]
        case "Imposter Syndrome":
            return [
                Affirmation(text: "I earned my place. I belong here.", category: "Confidence"),
                Affirmation(text: "My unique perspective is exactly what's needed.", category: "Confidence"),
                Affirmation(text: "I release the fear of being found out.", category: "Confidence"),
                Affirmation(text: "I am qualified. My work speaks for itself.", category: "Confidence"),
                Affirmation(text: "I deserve every success I've achieved.", category: "Confidence")
            ]
        case "Relationship Pattern":
            return [
                Affirmation(text: "I attract people who respect and value me.", category: "Relationships"),
                Affirmation(text: "I release the patterns that no longer serve me.", category: "Relationships"),
                Affirmation(text: "I deserve love that feels peaceful and safe.", category: "Relationships"),
                Affirmation(text: "I recognize red flags early and honor my boundaries.", category: "Relationships"),
                Affirmation(text: "My past does not define my future relationships.", category: "Relationships")
            ]
        case "Lack of Direction":
            return [
                Affirmation(text: "Clarity is coming. I trust my path is unfolding.", category: "Purpose"),
                Affirmation(text: "One step forward is all I need right now.", category: "Purpose"),
                Affirmation(text: "I release the pressure to have it all figured out.", category: "Purpose"),
                Affirmation(text: "My intuition knows the way. I am listening.", category: "Purpose"),
                Affirmation(text: "Every experience is guiding me to my purpose.", category: "Purpose")
            ]
        case "Self-Sabotage":
            return [
                Affirmation(text: "I am safe to succeed. I allow good things in.", category: "Self-Worth"),
                Affirmation(text: "I release the patterns that hold me back.", category: "Self-Worth"),
                Affirmation(text: "I deserve happiness and I choose it now.", category: "Self-Worth"),
                Affirmation(text: "I am worthy of the success I'm creating.", category: "Self-Worth"),
                Affirmation(text: "I stop running from my own greatness.", category: "Self-Worth")
            ]
        default:
            return getFallbackAffirmations()
        }
    }
    
    // MARK: - Start Calibration with Pre-built Affirmations (skip AI)
    private func startCalibrationWithPrebuilt() {
        withAnimation { currentPage = 7 }
        
        // Get pre-built affirmations for selected blockage
        let affirmations = prebuiltAffirmationsForBlockage(selectedBlockage ?? "")
        self.generatedAffirmations = affirmations
        
        // Play the calibration animation sequence
        let sequence = [
            "Analyzing neural patterns...",
            "Matching to your blockage profile...",
            "Loading targeted affirmations...",
            "Your session is ready."
        ]
        
        var delay: TimeInterval = 0
        for (index, text) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation { self.calibrationText = text }
                if index == sequence.count - 1 {
                    // Advance to immersive preview after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.advance()
                    }
                }
            }
            delay += 1.5
        }
    }
    
    // MARK: - Start Calibration with AI Generation (for "Other" chat flow)
    private func startCalibration() {
        withAnimation { currentPage = 7 }
        
        // Simulate the AI Neural work
        let sequence = [
            "Analyzing neural patterns...",
            "Identifying resonance frequency...",
            "Calibrating affirmation sequence...",
            "Your custom pathway is ready."
        ]
        
        var delay: TimeInterval = 0
        for (index, text) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation { self.calibrationText = text }
                if index == sequence.count - 1 {
                    // Generate the affirmations using AI
                    self.generateAffirmations()
                }
            }
            delay += 2.0
        }
    }
    
    private func generateAffirmations() {
        let prompt = """
        The user identified their blockage as: "\(selectedBlockage ?? "general stress")".
        They described what it feels like: "\(specificityInput)".
        They described their desired state: "\(desiredStateInput)".
        
        Generate exactly 4 short, powerful affirmations (each max 12 words) that:
        1. Are in first person, present tense ("I am", "I have", "I release")
        2. Directly address their specific pain points
        3. Bridge from their current state to their desired state
        4. Are emotionally resonant and feel personal
        
        Return ONLY the 4 affirmations, one per line. No numbering, no quotes.
        """
        
        let messages = [ChatMessage(text: prompt, isUser: true)]
        let systemPrompt = "You are an expert in neuroplasticity and affirmations. Generate powerful, hyper-personalized affirmations."
        
        OpenRouterChatService.shared.sendMessage(history: messages, systemPrompt: systemPrompt) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Parse the response into lines and convert to Affirmation objects
                    let lines = response.components(separatedBy: "\n").filter { !$0.isEmpty }
                    if lines.isEmpty {
                        self.generatedAffirmations = self.getFallbackAffirmations()
                    } else {
                        self.generatedAffirmations = lines.map { Affirmation(text: $0, category: "Personalized") }
                    }
                case .failure(_):
                    self.generatedAffirmations = self.getFallbackAffirmations()
                }
                
                // Advance to preview after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.advance()
                }
            }
        }
    }
    
    private func getFallbackAffirmations() -> [Affirmation] {
        return [
            Affirmation(text: "I release the need to control outcomes.", category: "Personalized"),
            Affirmation(text: "My mind is calm. My thoughts are clear.", category: "Personalized"),
            Affirmation(text: "I trust myself to handle whatever comes.", category: "Personalized"),
            Affirmation(text: "Peace flows through me naturally.", category: "Personalized")
        ]
    }
    
    private var notificationCategorySets: (affirmations: Set<String>, quotes: Set<String>) {
        OnboardingNotificationCategories.categories(
            for: selectedBlockage,
            generatedAffirmations: generatedAffirmations
        )
    }
    
    private var widgetSampleAffirmation: String {
        generatedAffirmations.first?.text ?? "I am enough exactly as I am."
    }
    
    private var widgetSampleQuote: String {
        let quotes = ContentLoader.shared.loadQuotes()
        if let match = quotes.first(where: { notificationCategorySets.quotes.contains($0.category) }) {
            return match.text
        }
        return quotes.first?.text ?? "Peace comes from within."
    }
    
    private var widgetSampleAuthor: String {
        let quotes = ContentLoader.shared.loadQuotes()
        if let match = quotes.first(where: { notificationCategorySets.quotes.contains($0.category) }) {
            return match.author
        }
        return quotes.first?.author ?? "Buddha"
    }
    
    private func requestNotificationsAndAdvance() {
        NotificationService.shared.requestAuthorization { granted in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentPage = granted ? 11 : 12
                }
            }
        }
    }
    
    private func goToWidgetScreen() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage = 12
        }
    }
    
    private func completeOnboarding() {
        entitlementManager.refreshCustomerInfo()
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - PHASE 1: THE HOOK

struct Screen1_Splash: View {
    var onNext: () -> Void
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Pulsing Border Logo
            Circle()
                .fill(Color.museDeepNavy)
                .frame(width: 140, height: 140)
                .overlay(
                    Circle().stroke(
                        LinearGradient(colors: [.musePink, .museAccentBlue, .museTeal], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 4
                    )
                    .scaleEffect(pulse ? 1.1 : 1.0)
                    .opacity(pulse ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                )
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                )
                .onAppear { pulse = true }
            
            VStack(spacing: 16) {
                Text("Your thoughts aren't random.\nThey're patterns.")
                    .font(.museDisplayMedium())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("And patterns can be rewritten.")
                    .font(.museDisplaySmall())
                    .foregroundColor(.museTeal)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("Begin Calibration →") { onNext() }
                .buttonStyle(MusePrimaryButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
        }
    }
}

struct Screen2_ScienceHook: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Abstract Neural Network Visualization (Simplified with Shapes)
            ZStack {
                ForEach(0..<5) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 100 + CGFloat(i * 40), height: 100 + CGFloat(i * 40))
                }
                Image(systemName: "network")
                    .font(.system(size: 60))
                    .foregroundColor(.museAccentBlue)
            }
            .frame(height: 250)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("🧠 The Reticular Activating System")
                    .font(.museHeadline())
                    .foregroundColor(.museTeal)
                
                Text("Your brain filters 2.3 million bits of data per second. It only shows you what it thinks you need to see.")
                    .font(.museBodyMedium())
                    .foregroundColor(.white)
                    .lineSpacing(4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("This is why:")
                        .font(.museBodySmall())
                        .foregroundColor(.museLightGray)
                    Text("• You notice red cars after buying one")
                    Text("• Negative thoughts loop endlessly")
                    Text("• You feel 'stuck' in the same patterns")
                }
                .font(.museBodyMedium())
                .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button("Show me →") { onNext() }
                .buttonStyle(MusePrimaryButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
        }
    }
}

struct Screen3_Mechanism: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Lit up synapses
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.museOrange)
                .padding(.bottom, 20)
            
            Text("✨ Neuroplasticity in Action")
                .font(.museHeadline())
                .foregroundColor(.musePink)
            
            VStack(spacing: 20) {
                Text("Your RAS can be reprogrammed in as little as **66 seconds**.")
                    .font(.museDisplaySmall())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("By feeding your subconscious hyper-specific, emotionally resonant affirmations, you create new 'Silent Circuits' that automatically filter reality toward your goals.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button("I'm ready to rewire →") { onNext() }
                .buttonStyle(MusePrimaryButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
        }
    }
}


// MARK: - PHASE 2: THE DIAGNOSIS

struct Screen4_BlockageSelector: View {
    @Binding var selectedBlockage: String?
    var onNext: () -> Void
    var onOther: () -> Void // New callback for "Other" option
    
    let options = [
        ("Anxiety Loop", "Racing thoughts, worst-case scenarios"),
        ("Scarcity Circuit", "Never enough money, time, or success"),
        ("Imposter Syndrome", "Feeling like a fraud"),
        ("Relationship Pattern", "Repeating toxic cycles"),
        ("Lack of Direction", "Paralyzed by options"),
        ("Self-Sabotage", "Blowing up your own success")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's running in the background?")
                .font(.museDisplaySmall())
                .foregroundColor(.white)
                .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(options, id: \.0) { option in
                         Button(action: {
                             selectedBlockage = option.0
                         }) {
                             HStack {
                                 VStack(alignment: .leading, spacing: 4) {
                                     Text(option.0)
                                         .font(.museBodyMedium())
                                         .foregroundColor(.white)
                                         .bold()
                                     Text(option.1)
                                         .font(.caption)
                                         .foregroundColor(.museLightGray)
                                 }
                                 Spacer()
                                 if selectedBlockage == option.0 {
                                     Image(systemName: "circle.circle.fill")
                                         .foregroundColor(.museAccentBlue)
                                 }
                             }
                             .padding()
                             .background(
                                 RoundedRectangle(cornerRadius: 12)
                                     .fill(selectedBlockage == option.0 ? Color.museAccentBlue.opacity(0.2) : Color.white.opacity(0.05))
                                     .overlay(
                                         RoundedRectangle(cornerRadius: 12)
                                             .stroke(selectedBlockage == option.0 ? Color.museAccentBlue : Color.white.opacity(0.1), lineWidth: 1)
                                     )
                             )
                         }
                    }
                    
                    // "Other" Option - Goes to AI Chat
                    Button(action: {
                        onOther()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Something else...")
                                    .font(.museBodyMedium())
                                    .foregroundColor(.white)
                                    .bold()
                                Text("Chat with Muse AI to explore")
                                    .font(.caption)
                                    .foregroundColor(.museTeal)
                            }
                            Spacer()
                            Image(systemName: "sparkles")
                                .foregroundColor(.museTeal)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.museTeal.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.museTeal.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Button(action: onNext) {
                Text("Continue")
            }
            .buttonStyle(MusePrimaryButtonStyle())
            .disabled(selectedBlockage == nil)
            .opacity(selectedBlockage == nil ? 0.5 : 1.0)
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
    }
}

struct Screen5_Specificity: View {
    let selectedBlockage: String?
    @Binding var text: String
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            SwiftUI.ProgressView(value: 0.33)
                .tint(.museAccentBlue)
                .padding(.horizontal, 32)
                .padding(.top, 20)
            
            Text("Let's get specific.")
                .font(.museDisplayMedium())
                .foregroundColor(.white)
            
            Text("Describe what '\(selectedBlockage ?? "this")' feels like for you right now.")
                .font(.museBodyMedium())
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.05))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .frame(height: 150)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1).padding(.horizontal, 24))
            
            Spacer()
            
            Button("Continue →") { onNext() }
                .buttonStyle(MusePrimaryButtonStyle())
                .disabled(text.count < 10)
                .opacity(text.count < 10 ? 0.5 : 1.0)
                .padding(.horizontal, 32)
                .padding(.bottom, 30)
        }
    }
}

struct Screen6_DesiredState: View {
    @Binding var text: String
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            SwiftUI.ProgressView(value: 0.66)
                .tint(.musePink)
                .padding(.horizontal, 32)
                .padding(.top, 20)
            
            Text("Now, imagine the opposite.")
                .font(.museDisplayMedium())
                .foregroundColor(.white)
            
            Text("If this blockage dissolved completely, what would you be doing differently?")
                .font(.museBodyMedium())
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.05))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .frame(height: 150)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1).padding(.horizontal, 24))
            
            Spacer()
            
            Button("Generate My Neural Pathway →") { onNext() }
                .buttonStyle(MusePrimaryButtonStyle())
                .disabled(text.count < 10)
                .opacity(text.count < 10 ? 0.5 : 1.0)
                .padding(.horizontal, 32)
                .padding(.bottom, 30)
        }
    }
}

struct Screen7_Calibration: View {
    @Binding var statusText: String
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [.red, .purple, .blue, .green, .yellow, .red]), center: .center),
                        lineWidth: 4
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                
                Image(systemName: "brain")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
            
            Spacer().frame(height: 50)
            
            Text(statusText)
                .font(.museDisplaySmall())
                .foregroundColor(.white)
                .transition(.opacity)
                .id(statusText) // Forces transition
            
            Spacer()
        }
    }
}

struct Screen8_ImmersivePreview: View {
    let affirmations: [Affirmation]
    var onComplete: () -> Void
    
    var body: some View {
        // Use the actual ImmersiveAffirmationView from the app
        // This ensures the onboarding preview matches the real app experience
        ImmersiveAffirmationView(
            affirmations: affirmations,
            duration: .oneMinute, // Short demo session
            isAIGenerated: false, // Don't show save prompt during onboarding
            isOnboarding: true, // Don't count towards free session limit
            onComplete: onComplete
        )
    }
}

// MARK: - Helper Button Style
struct MusePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.museButtonLarge())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.museAccentBlue)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - "Other" AI Chat Screen
struct Screen_OtherChat: View {
    var onAffirmationsReady: ([Affirmation]) -> Void
    
    @State private var messages: [OnboardingChatMessage] = []
    @State private var userInput: String = ""
    @State private var isLoading: Bool = false
    @State private var canGenerateSession: Bool = false
    @FocusState private var isInputFocused: Bool
    
    // Initial greeting
    private let initialMessage = "Hey! ✨ I'm Muse, your neural guide.\n\nTell me what's been on your mind lately. What thoughts or feelings have been holding you back? I'll create a personalized affirmation session just for you."
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chat with Muse")
                        .font(.museDisplaySmall())
                        .foregroundColor(.white)
                    Text("Tell me what's on your mind")
                        .font(.caption)
                        .foregroundColor(.museLightGray)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(.museTeal)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            OnboardingChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            HStack {
                                OnboardingTypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Generate Button (appears after conversation)
            if canGenerateSession {
                Button(action: generateAffirmations) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Generate My Session")
                    }
                }
                .buttonStyle(MusePrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Type your thoughts...", text: $userInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                    .focused($isInputFocused)
                    .lineLimit(1...4)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(userInput.isEmpty ? .gray : .museAccentBlue)
                }
                .disabled(userInput.isEmpty || isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.museDarkGray.opacity(0.8))
        }
        .onAppear {
            // Add initial AI greeting
            messages.append(OnboardingChatMessage(text: initialMessage, isUser: false))
        }
    }
    
    private func sendMessage() {
        let text = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Add user message
        messages.append(OnboardingChatMessage(text: text, isUser: true))
        userInput = ""
        isLoading = true
        
        // Build conversation context
        let conversationHistory = messages.map { msg in
            ChatMessage(text: msg.text, isUser: msg.isUser)
        }
        
        let systemPrompt = """
        You are Muse, an empathetic AI guide helping someone discover what's holding them back.
        Your goal is to understand their emotional state deeply through 2-3 exchanges.
        
        Be warm, understanding, and ask thoughtful follow-up questions.
        Keep responses concise (2-3 sentences max).
        
        After they've shared enough (usually 2-3 messages from them), end your response with:
        "I understand now. I'm ready to create your personalized affirmation session whenever you are. 💫"
        
        This signals that you have enough information to generate affirmations.
        """
        
        OpenRouterChatService.shared.sendMessage(history: conversationHistory, systemPrompt: systemPrompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    messages.append(OnboardingChatMessage(text: response, isUser: false))
                    
                    // Check if AI is ready to generate
                    if response.contains("ready to create") || response.contains("whenever you are") || messages.filter({ $0.isUser }).count >= 3 {
                        withAnimation {
                            canGenerateSession = true
                        }
                    }
                    
                case .failure(_):
                    messages.append(OnboardingChatMessage(text: "I'm having trouble connecting. Let me try again...", isUser: false))
                }
            }
        }
    }
    
    private func generateAffirmations() {
        isLoading = true
        
        // Compile the conversation into a prompt
        let userMessages = messages.filter { $0.isUser }.map { $0.text }.joined(separator: "\n")
        
        let prompt = """
        Based on this conversation with the user about what's holding them back:
        
        "\(userMessages)"
        
        Generate exactly 4 short, powerful affirmations (each max 12 words) that:
        1. Are in first person, present tense ("I am", "I have", "I release")
        2. Directly address their specific pain points mentioned
        3. Help shift their mindset toward their desired state
        4. Are emotionally resonant and feel personal
        
        Return ONLY the 4 affirmations, one per line. No numbering, no quotes.
        """
        
        let messages = [ChatMessage(text: prompt, isUser: true)]
        let systemPrompt = "You are an expert in neuroplasticity and affirmations. Generate powerful, hyper-personalized affirmations based on the user's conversation."
        
        OpenRouterChatService.shared.sendMessage(history: messages, systemPrompt: systemPrompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    let lines = response.components(separatedBy: "\n").filter { !$0.isEmpty }
                    let affirmations = lines.isEmpty ? fallbackAffirmations() : lines.map { Affirmation(text: $0, category: "Personalized") }
                    onAffirmationsReady(affirmations)
                    
                case .failure(_):
                    onAffirmationsReady(fallbackAffirmations())
                }
            }
        }
    }
    
    private func fallbackAffirmations() -> [Affirmation] {
        return [
            Affirmation(text: "I release what no longer serves me.", category: "Personalized"),
            Affirmation(text: "I am exactly where I need to be.", category: "Personalized"),
            Affirmation(text: "I trust the process of my life.", category: "Personalized"),
            Affirmation(text: "I am becoming who I am meant to be.", category: "Personalized")
        ]
    }
}

// MARK: - Chat Message Model
struct OnboardingChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

// MARK: - Chat Bubble
struct OnboardingChatBubble: View {
    let message: OnboardingChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.text)
                .font(.museBodyMedium())
                .foregroundColor(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isUser ? Color.museAccentBlue.opacity(0.8) : Color.white.opacity(0.1))
                )
            
            if !message.isUser { Spacer() }
        }
    }
}

// MARK: - Typing Indicator
struct OnboardingTypingIndicator: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.museLightGray)
                    .frame(width: 8, height: 8)
                    .opacity(dotCount == index ? 1.0 : 0.3)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                dotCount = (dotCount + 1) % 3
            }
        }
    }
}
