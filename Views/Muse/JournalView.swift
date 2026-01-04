import SwiftUI

/// A journal view for the AI chat that stores conversation memories and insights

struct JournalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var journalEntries: [JournalEntry] = []
    
    var body: some View {
        ZStack {
            // Background
            Color.museDeepNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                ZStack {
                    // Centered Title
                    Text("Muse Journal")
                        .font(.custom("Palatino-Bold", size: 24))
                        .foregroundColor(.museSoftWhite)
                    
                    // Buttons
                    HStack {
                        Spacer()
                        
                        // Close Button (Right)
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.museLightGray)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(Color.museDeepNavy)
                
                // Show entries or empty state
                if journalEntries.isEmpty {
                    emptyStateView
                } else {
                    journalEntriesList
                }
            }
            .blur(radius: isCheckingIn ? 10 : 0) // Blur background when checking in
            .overlay {
                if isCheckingIn {
                    checkInFlowView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
    }
    
    // MARK: - Data Models
    struct DailyJournalEntry: Identifiable {
        let id = UUID()
        let date: Date
        let mood: String
        let groundingPrompt: String
        let groundingResponse: String
        
        // Journal Fields
        let gratitude: [String]
        let great: [String]
        let affirmation: String
        let amazing: [String]
        let better: [String]
        
        // AI Content
        let aiReflection: String
        let quote: String
        let quoteAuthor: String
        let dynamicAffirmation: String
    }

    @State private var savedEntries: [DailyJournalEntry] = []
    
    // Check if we have an entry for today
    private var todaysEntry: DailyJournalEntry? {
        savedEntries.first { Calendar.current.isDateInToday($0.date) }
    }
    
    // MARK: - Check In Flow State
    @StateObject private var speechRecognizer = SpeechRecognizer.shared
    @State private var isCheckingIn = false
    @State private var checkInStep = 1
    @State private var selectedMood: String? = nil
    @State private var groundingResponseText: String = ""
    @State private var isSendingResponse = false
    @State private var aiResponse: String? = nil
    
    // Journal Page Data
    @State private var gratitude1 = ""
    @State private var gratitude2 = ""
    @State private var gratitude3 = ""
    @State private var great1 = ""
    @State private var great2 = ""
    @State private var great3 = ""
    @State private var affirmation = ""
    
    // New Sections (Evening / Reflection)
    @State private var amazing1 = ""
    @State private var amazing2 = ""
    @State private var amazing3 = ""
    @State private var better1 = ""
    @State private var better2 = ""
    
    // AI Content
    @State private var dynamicQuote = "The man who does not read good books has no advantage over the man who cannot read them."
    @State private var dynamicQuoteAuthor = "Mark Twain"
    @State private var dynamicAffirmation = "I am capable of handling whatever comes my way."
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Check In Button (Prominently placed at the top)
            checkInButton
                .padding(.top, 20)
            
            // Decorative icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.museGradientStart.opacity(0.3), Color.museGradientEnd.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.museGradientStart, Color.museGradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 10)
            
            VStack(spacing: 12) {
                Text(todaysEntry != nil ? "Entry Saved" : "Your Journal is Empty")
                    .font(.museDisplaySmall())
                    .foregroundColor(.museSoftWhite)
                
                Text("As you chat with Muse, important insights,\nmemories, and reflections will be saved here.")
                    .font(.museBodyMedium())
                    .foregroundColor(.museLightGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Placeholder cards showing what will be here
            VStack(spacing: 12) {
                placeholderCard(
                    icon: "brain.head.profile",
                    title: "Insights",
                    subtitle: "Key realizations from your conversations"
                )
                
                placeholderCard(
                    icon: "heart.fill",
                    title: "Emotional Patterns",
                    subtitle: "Tracked feelings and moods over time"
                )
                
                placeholderCard(
                    icon: "lightbulb.fill",
                    title: "Growth Moments",
                    subtitle: "Breakthroughs and personal discoveries"
                )
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var checkInButton: some View {
        Button(action: {
            if let entry = todaysEntry {
                // Load existing entry
                loadEntry(entry)
            } else {
                // Start new check-in
                startNewCheckIn()
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    if todaysEntry != nil {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(todaysEntry != nil ? "View Today's Journal" : "Daily Check-In")
                        .font(.museHeadline())
                        .foregroundColor(.white)
                    
                    Text(todaysEntry != nil ? "Great job checking in today!" : "Log your mood & mindset")
                        .font(.museCaption())
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: todaysEntry != nil 
                        ? [Color.green.opacity(0.8), Color.blue.opacity(0.8)] // Different gradient for completed
                        : [Color.museGradientStart, Color.museGradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.museGradientStart.opacity(0.4), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Check In Flow View
    
    private var checkInFlowView: some View {
        ZStack {
            // Dimmed Background Tap to Dismiss
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isCheckingIn = false
                    }
                }
            
            // Modal Content
            VStack(spacing: 0) {
                if checkInStep == 1 {
                    moodSelectionStep
                } else if checkInStep == 2 {
                    groundingPromptStep
                } else if checkInStep == 3 {
                    aiReflectionStep
                } else if checkInStep == 4 {
                    journalPageView
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.museDeepNavy)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 10)
            )
            .padding(20)
        }
    }
    
    // MARK: - Step 1: Mood
    private var moodSelectionStep: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        isCheckingIn = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.museMediumGray)
                }
            }
            
            // Question
            Text("How are you feeling?")
                .font(.custom("Palatino-Bold", size: 28))
                .foregroundColor(.museSoftWhite)
                .multilineTextAlignment(.center)
            
            // Mood Options
            VStack(spacing: 12) {
                moodOptionButton(emoji: "😔", title: "Very bad")
                moodOptionButton(emoji: "😕", title: "Just getting by")
                moodOptionButton(emoji: "😐", title: "Okay")
                moodOptionButton(emoji: "🙂", title: "Pretty good")
                moodOptionButton(emoji: "😁", title: "I'm feeling great today")
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Step 2: Grounding Prompt
    private var groundingPromptStep: some View {
        VStack(spacing: 24) {
             // Header
            HStack {
                Button(action: {
                    withAnimation {
                        checkInStep = 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.museLightGray)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isCheckingIn = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.museMediumGray)
                }
            }
            
            // Question based on mood
            Text(groundingPromptForMood)
                .font(.custom("Palatino-Bold", size: 24))
                .foregroundColor(.museSoftWhite)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            
            // Input Area
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    TextField("Write 1-3 lines (optional)...", text: $groundingResponseText, axis: .vertical)
                        .font(.museBodyMedium())
                        .foregroundColor(.museSoftWhite)
                        .lineLimit(1...5)
                        .padding(16)
                        .background(Color.museDarkGray)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    // Mic Button
                    Button(action: {
                        speechRecognizer.toggleRecording()
                    }) {
                        ZStack {
                            Circle()
                                .fill(speechRecognizer.isRecording ? Color.red.opacity(0.2) : Color.museDarkGray)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(speechRecognizer.isRecording ? Color.red : Color.white.opacity(0.1), lineWidth: 1)
                                )
                            
                            Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(speechRecognizer.isRecording ? .red : .museLightGray)
                        }
                    }
                }
                
                Button(action: submitGroundingResponse) {
                    HStack {
                        Text("Shared with Muse")
                            .fontWeight(.medium)
                        Image(systemName: "arrow.up.circle.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                groundingResponseText.isEmpty ? AnyShapeStyle(Color.museMediumGray) : AnyShapeStyle(LinearGradient(colors: [.museGradientStart, .museGradientEnd], startPoint: .leading, endPoint: .trailing))
                            )
                    )
                }
                .disabled(groundingResponseText.isEmpty || isSendingResponse || speechRecognizer.isRecording)
                
                Button(action: {
                     // Pass empty text to just move to next step without user input
                     groundingResponseText = "Thinking..." // Temporary placeholder or handle skip
                     submitGroundingResponse(isSkip: true)
                }) {
                    Text("Skip for now")
                        .font(.museCaption())
                        .foregroundColor(.museLightGray)
                }
            }
            .onChange(of: speechRecognizer.transcript) { _, newTranscript in
                if speechRecognizer.isRecording && !newTranscript.isEmpty {
                    groundingResponseText = newTranscript
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Step 3: AI Reflection
    private var aiReflectionStep: some View {
        VStack(spacing: 32) {
            if isSendingResponse {
                // Loading State (Pulsing Brain)
                VStack(spacing: 24) {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.museGradientStart, .museGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.museGradientStart.opacity(0.5), radius: 20, x: 0, y: 0)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isSendingResponse)
                    
                    Text("Reflecting...")
                        .font(.museHeadline())
                        .foregroundColor(.museLightGray)
                }
                .frame(minHeight: 300)
            } else if let response = aiResponse {
                // Success State (The "Magic Moment")
                VStack(spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(LinearGradient(colors: [.museGradientStart, .museGradientEnd], startPoint: .top, endPoint: .bottom))
                        Text("Muscle Reflection")
                            .font(.museHeadline())
                            .foregroundColor(.museLightGray)
                        Image(systemName: "sparkles")
                            .foregroundStyle(LinearGradient(colors: [.museGradientStart, .museGradientEnd], startPoint: .top, endPoint: .bottom))
                    }
                    
                    // The Reflection Text
                    Text(response)
                        .font(.system(size: 22, weight: .medium, design: .serif)) // Palatino-like feel
                        .foregroundColor(.museSoftWhite)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 10)
                    
                    // Continue Button
                    Button(action: {
                        withAnimation {
                            checkInStep = 4 // Proceed to Journal Page
                        }
                    }) {
                        Text("Continue")
                            .font(.museButtonMedium())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [.museGradientStart, .museGradientEnd], startPoint: .leading, endPoint: .trailing))
                            )
                    }
                    .padding(.top, 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    // MARK: - Step 4: Journal Page
    private var journalPageView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // 1. Header with Date & Icon
                HStack {
                    Spacer()
                    Text(Date().formatted(date: .long, time: .omitted))
                        .font(.museCaption())
                        .kerning(1.5)
                        .foregroundColor(.museLightGray)
                    Image(systemName: "sun.max.fill") 
                        .foregroundColor(.yellow)
                    Spacer()
                }
                .padding(.top, 10)
                
                // 2. Dynamic Quote (Top Feature)
                VStack(spacing: 8) {
                    Text(dynamicQuote)
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.museSoftWhite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("— \(dynamicQuoteAuthor.uppercased())")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundColor(.museMediumGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
                
                // 3. Morning Sections
                Group {
                    // Grateful For
                    journalSection(title: "I am grateful for...") {
                        VStack(spacing: 12) {
                            underlinedTextField(placeholder: "1.", text: $gratitude1)
                            underlinedTextField(placeholder: "2.", text: $gratitude2)
                            underlinedTextField(placeholder: "3.", text: $gratitude3)
                        }
                    }
                    
                    // What would make today great
                    journalSection(title: "What would make today great?") {
                         VStack(spacing: 12) {
                            underlinedTextField(placeholder: "1.", text: $great1)
                            underlinedTextField(placeholder: "2.", text: $great2)
                            underlinedTextField(placeholder: "3.", text: $great3)
                        }
                    }
                    
                    // Daily Affirmations
                    journalSection(title: "Daily affirmations. I am...") {
                         VStack(alignment: .leading, spacing: 8) {
                             if !dynamicAffirmation.isEmpty {
                                 Text("Suggested: \"\(dynamicAffirmation)\"")
                                     .font(.caption)
                                     .italic()
                                     .foregroundColor(.museAccentBlue)
                             }
                             underlinedTextField(placeholder: "I am...", text: $affirmation)
                         }
                    }
                }
                
                Divider()
                    .background(Color.museLightGray.opacity(0.3))
                    .padding(.vertical, 10)
                
                // 4. Evening/Reflection Sections (Optional but part of layout)
                Group {
                    Text("3 Amazing things that happened today...")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.museSoftWhite)
                        .padding(.top, 10)
                    
                    VStack(spacing: 12) {
                        underlinedTextField(placeholder: "1.", text: $amazing1)
                        underlinedTextField(placeholder: "2.", text: $amazing2)
                        underlinedTextField(placeholder: "3.", text: $amazing3)
                    }
                    
                    Text("How could I have made today better?")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.museSoftWhite)
                        .padding(.top, 10)
                    
                     VStack(spacing: 12) {
                        underlinedTextField(placeholder: "", text: $better1)
                        underlinedTextField(placeholder: "", text: $better2)
                    }
                }
                
                // 5. Muse Reflection (The "Magic" Interaction)
                if let response = aiResponse {
                    VStack(alignment: .center, spacing: 12) {
                         HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(LinearGradient(colors: [.museGradientStart, .museGradientEnd], startPoint: .top, endPoint: .bottom))
                            Text("Muse Insight")
                                .font(.museHeadline())
                                .foregroundColor(.museLightGray)
                        }
                        
                        TypewriterText(text: response)
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundColor(.museSoftWhite.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                }
                
                // Finish Button
                Button(action: finishCheckIn) {
                    Text("Save Entry")
                        .font(.museButtonMedium())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.museGradientStart, .museGradientEnd], startPoint: .leading, endPoint: .trailing))
                        )
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: 650)
    }
    
    private func journalSection<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .regular, design: .serif)) // Serif for journal feel
                .italic()
                .foregroundColor(.museSoftWhite)
            
            content()
        }
    }
    
    private func underlinedTextField(placeholder: String, text: Binding<String>) -> some View {
        VStack(spacing: 4) {
            TextField(placeholder, text: text)
                .font(.museBodyMedium())
                .foregroundColor(.white)
                .tint(.museAccentBlue)
            
            Rectangle()
                .fill(Color.museMediumGray.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Actions
    
    private func startNewCheckIn() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isCheckingIn = true
            checkInStep = 1
            // Reset state
            selectedMood = nil
            groundingResponseText = ""
            aiResponse = nil
            isSendingResponse = false
            
            gratitude1 = ""; gratitude2 = ""; gratitude3 = ""
            great1 = ""; great2 = ""; great3 = ""
            affirmation = ""
            amazing1 = ""; amazing2 = ""; amazing3 = ""
            better1 = ""; better2 = ""
        }
    }
    
    private func loadEntry(_ entry: DailyJournalEntry) {
        // Populate state from entry
        selectedMood = entry.mood
        groundingResponseText = entry.groundingResponse
        aiResponse = entry.aiReflection
        dynamicQuote = entry.quote
        dynamicQuoteAuthor = entry.quoteAuthor
        dynamicAffirmation = entry.dynamicAffirmation
        
        // Mapping (Simplified)
        gratitude1 = entry.gratitude.indices.contains(0) ? entry.gratitude[0] : ""
        gratitude2 = entry.gratitude.indices.contains(1) ? entry.gratitude[1] : ""
        gratitude3 = entry.gratitude.indices.contains(2) ? entry.gratitude[2] : ""
        
        great1 = entry.great.indices.contains(0) ? entry.great[0] : ""
        great2 = entry.great.indices.contains(1) ? entry.great[1] : ""
        great3 = entry.great.indices.contains(2) ? entry.great[2] : ""
        
        affirmation = entry.affirmation
        
        amazing1 = entry.amazing.indices.contains(0) ? entry.amazing[0] : ""
        amazing2 = entry.amazing.indices.contains(1) ? entry.amazing[1] : ""
        amazing3 = entry.amazing.indices.contains(2) ? entry.amazing[2] : ""

        better1 = entry.better.indices.contains(0) ? entry.better[0] : ""
        better2 = entry.better.indices.contains(1) ? entry.better[1] : ""
        
        // Open directly to Page View
        withAnimation {
            isCheckingIn = true
            checkInStep = 4
        }
    }

    private func finishCheckIn() {
        // Create Entry
        let newEntry = DailyJournalEntry(
            date: Date(),
            mood: selectedMood ?? "Neutral",
            groundingPrompt: "Grounding Prompt",
            groundingResponse: groundingResponseText,
            gratitude: [gratitude1, gratitude2, gratitude3],
            great: [great1, great2, great3],
            affirmation: affirmation,
            amazing: [amazing1, amazing2, amazing3],
            better: [better1, better2],
            aiReflection: aiResponse ?? "",
            quote: dynamicQuote,
            quoteAuthor: dynamicQuoteAuthor,
            dynamicAffirmation: dynamicAffirmation
        )
        
        // Save
        if let index = savedEntries.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            savedEntries[index] = newEntry
        } else {
            savedEntries.append(newEntry)
            // Log the new journal entry
            ProgressService.shared.logJournalEntry()
        }
        
        withAnimation {
            isCheckingIn = false
        }
    }
    
    private var groundingPromptForMood: String {
        guard let mood = selectedMood else { return "What's on your mind?" }
        
        switch mood {
        case "Very bad", "Just getting by":
            return "What’s weighing on you today?"
        case "Okay":
             return "What are you trying to control right now?"
        case "Pretty good", "I'm feeling great today":
             return "What do you need more of today?"
        default:
            return "What's on your mind?"
        }
    }
    
    private func submitGroundingResponse() {
        submitGroundingResponse(isSkip: false)
    }
    
    private func submitGroundingResponse(isSkip: Bool) {
        withAnimation {
            checkInStep = 3 // Move to Reflection screen
            isSendingResponse = true
        }
        
        let mood = selectedMood ?? "Neutral"
        let prompt = groundingPromptForMood
        let userEntry = isSkip ? "(User skipped this part)" : groundingResponseText
        
        // Structured Prompt
        let systemContext = """
        The user is doing a daily journal check-in.
        Current Mood: \(mood)
        Journal Prompt: "\(prompt)"
        User Answer: "\(userEntry)"
        
        Please provide a response in the following specific format. Do not include markdown or JSON formatting, just the labels.
        
        REFLECTION: [A brief, empathetic acknowledgement of the user's feelings (1-2 sentences)]
        QUOTE: [A short, relevant quote that fits their mood]
        AUTHOR: [Author of the quote]
        AFFIRMATION: [A short, powerful 'I am' affirmation relevant to their answer]
        """
        
        let dummyHistory: [ChatMessage] = [] 
        
        OpenRouterChatService.shared.sendMessage(
            history: dummyHistory,
            systemPrompt: systemContext,
            crisisPrefix: ""
        ) { result in
            DispatchQueue.main.async {
                withAnimation {
                    isSendingResponse = false
                    switch result {
                    case .success(let rawResponse):
                        parseApiResponse(rawResponse)
                    case .failure(let error):
                        print("Check-in API Error: \(error)")
                        aiResponse = "I hear you, and I'm here for you."
                    }
                }
            }
        }
    }
    
    private func parseApiResponse(_ response: String) {
        // Simple parsing logic
        var reflection = ""
        var quote = ""
        var author = ""
        var aff = ""
        
        let lines = response.components(separatedBy: .newlines)
        var currentSection = ""
        
        for line in lines {
            if line.starts(with: "REFLECTION:") {
                currentSection = "REFLECTION"
                reflection = String(line.dropFirst(11)).trimmingCharacters(in: .whitespaces)
            } else if line.starts(with: "QUOTE:") {
                currentSection = "QUOTE"
                quote = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.starts(with: "AUTHOR:") {
                currentSection = "AUTHOR"
                author = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            } else if line.starts(with: "AFFIRMATION:") {
                currentSection = "AFFIRMATION"
                aff = String(line.dropFirst(12)).trimmingCharacters(in: .whitespaces)
            } else if !line.isEmpty {
                // Append to continuation of previous section
                if currentSection == "REFLECTION" { reflection += " " + line }
                else if currentSection == "QUOTE" { quote += " " + line }
            }
        }
        
        self.aiResponse = reflection.isEmpty ? response : reflection
        if !quote.isEmpty { self.dynamicQuote = quote }
        if !author.isEmpty { self.dynamicQuoteAuthor = author }
        if !aff.isEmpty { self.dynamicAffirmation = aff }
    }
    
    private func moodOptionButton(emoji: String, title: String) -> some View {
        Button(action: {
            selectedMood = title
            // Proceed to Step 2
            withAnimation {
                checkInStep = 2
            }
        }) {

            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 32))
                
                Text(title)
                    .font(.museBodyMedium())
                    .foregroundColor(.museSoftWhite)
                
                Spacer()
                
                if selectedMood == title {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.museAccentBlue)
                        .font(.system(size: 20))
                } else {
                    Circle()
                        .stroke(Color.museMediumGray.opacity(0.5), lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedMood == title ? Color.museAccentBlue.opacity(0.15) : Color.museDarkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedMood == title ? Color.museAccentBlue : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Helper for card animations
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
        }
    }
    
    private func placeholderCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.museGradientStart, Color.museGradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Text(subtitle)
                    .font(.museCaption())
                    .foregroundColor(.museLightGray)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(.museMediumGray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.museDarkGray.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.museMediumGray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var journalEntriesList: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Check In Button (Also show at top of list)
                checkInButton
                
                LazyVStack(spacing: 16) {
                    ForEach(journalEntries) { entry in
                        JournalEntryCard(entry: entry)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Journal Entry Model

struct JournalEntry: Identifiable {
    let id = UUID()
    let type: JournalEntryType
    let title: String
    let content: String
    let date: Date
    let tags: [String]
}

enum JournalEntryType {
    case insight
    case emotion
    case growth
    case memory
    
    var icon: String {
        switch self {
        case .insight: return "brain.head.profile"
        case .emotion: return "heart.fill"
        case .growth: return "lightbulb.fill"
        case .memory: return "memories"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .insight: return [Color.museGradientStart, Color.museGradientEnd]
        case .emotion: return [Color(hex: "FF6B6B"), Color(hex: "FFE66D")]
        case .growth: return [Color(hex: "4ECDC4"), Color(hex: "556270")]
        case .memory: return [Color(hex: "667EEA"), Color(hex: "764BA2")]
        }
    }
}

// MARK: - Journal Entry Card

struct JournalEntryCard: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: entry.type.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: entry.type.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(entry.title)
                    .font(.museHeadline())
                    .foregroundColor(.museSoftWhite)
                
                Spacer()
                
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.museCaption())
                    .foregroundColor(.museLightGray)
            }
            
            // Content
            Text(entry.content)
                .font(.museBodyMedium())
                .foregroundColor(.museLightGray)
                .lineSpacing(4)
            
            // Tags
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.museCaption())
                                .foregroundColor(.museAccentBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.museAccentBlue.opacity(0.15))
                                )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.museDarkGray)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.museMediumGray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    JournalView()
}

// MARK: - Helper Components

struct TypewriterText: View {
    let text: String
    @State private var displayChars = ""
    
    var body: some View {
        Text(displayChars)
            .onAppear {
                displayChars = ""
                animateText()
            }
            .onChange(of: text) { _, newText in
                displayChars = ""
                animateText()
            }
    }
    
    func animateText() {
        // Simple animation loop that appends character by character
        // Note: In a real app complexity, a proper timer with cancellation might be better,
        // but this is sufficient for the visual effect desired.
        let chars = Array(text)
        for (index, char) in chars.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.03) {
                // Ensure we don't append if view state changed (simple check)
                // In production code, check if still mounted/relevant
                displayChars.append(char)
            }
        }
    }
}
